package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// Config represents the configuration for the monitor
type Config struct {
	RepoPath          string   `json:"repo_path"`
	WatchPaths        []string `json:"watch_paths"`
	ExcludePaths      []string `json:"exclude_paths"`
	TriggerFiles      []string `json:"trigger_files"` // files that trigger a plan when changed
	TriggerExtensions []string `json:"trigger_extensions"` // file extensions that trigger a plan
}

// Module represents a Terragrunt module
type Module struct {
	Path         string
	Dependencies []string
	Account      string // The account name (directory containing account.hcl)
	Region       string
	SubEnv       string // dev, test, stg, prod
}

// Change represents a detected change in the repository
type Change struct {
	Path      string
	Type      string // "modified", "added", "deleted"
	Timestamp time.Time
}

func main() {
	// Load configuration
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("Error loading config: %v", err)
	}

	// Get changed files from git diff
	changedFiles, err := getChangedFiles()
	if err != nil {
		log.Fatalf("Error getting changed files: %v", err)
	}

	// Find affected modules
	affectedModules, err := findAffectedModules(config, changedFiles)
	if err != nil {
		log.Fatalf("Error finding affected modules: %v", err)
	}

	// Run terragrunt plan for affected modules
	if err := runTerragruntPlan(affectedModules); err != nil {
		log.Fatalf("Error running terragrunt plan: %v", err)
	}
}

func loadConfig() (*Config, error) {
	// Default configuration
	config := &Config{
		RepoPath:          ".",
		WatchPaths:        []string{"."},
		ExcludePaths:      []string{".git", ".terraform"},
		TriggerFiles:      []string{"terragrunt.hcl", "terraform.tfvars", "account.hcl"},
		TriggerExtensions: []string{".tf", ".hcl", ".tfvars", ".json", ".yaml", ".yml"},
	}

	// Try to load from config file if it exists
	configPath := "terragrunt_monitor_config.json"
	if _, err := os.Stat(configPath); err == nil {
		data, err := ioutil.ReadFile(configPath)
		if err != nil {
			return nil, fmt.Errorf("error reading config file: %v", err)
		}

		if err := json.Unmarshal(data, config); err != nil {
			return nil, fmt.Errorf("error parsing config file: %v", err)
		}
	}

	return config, nil
}

func getChangedFiles() ([]string, error) {
	// Get the base branch from GitHub event
	baseBranch := os.Getenv("GITHUB_BASE_REF")
	if baseBranch == "" {
		return nil, fmt.Errorf("GITHUB_BASE_REF environment variable not set")
	}

	// Run git diff to get changed files
	cmd := exec.Command("git", "diff", "--name-only", fmt.Sprintf("origin/%s", baseBranch))
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("error running git diff: %v", err)
	}

	// Split output into lines and filter out empty lines
	files := strings.Split(string(output), "\n")
	var changedFiles []string
	for _, file := range files {
		if file != "" {
			changedFiles = append(changedFiles, file)
		}
	}

	return changedFiles, nil
}

func findAffectedModules(config *Config, changedFiles []string) ([]Module, error) {
	var affectedModules []Module
	moduleCache := make(map[string]*Module)
	commonModuleDeps := make(map[string][]string) // Maps common modules to their dependent modules

	// First pass: collect all modules and their dependencies
	err := filepath.Walk(config.RepoPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip excluded paths
		for _, excludePath := range config.ExcludePaths {
			if strings.Contains(path, excludePath) {
				return filepath.SkipDir
			}
		}

		// Check if this is a terragrunt module directory
		if info.IsDir() && isTerragruntModule(path) {
			module := &Module{
				Path:         path,
				Dependencies: []string{},
			}

			// Find the account this module belongs to
			accountPath := findAccountPath(path)
			if accountPath != "" {
				module.Account = filepath.Base(accountPath)
			}

			// Determine region and subenv from path
			parts := strings.Split(path, string(os.PathSeparator))
			for _, part := range parts {
				if part == "eu-central-1" || part == "us-east-1" {
					module.Region = part
				}
				if part == "dev" || part == "test" || part == "stg" || part == "prod" {
					module.SubEnv = part
				}
			}

			moduleCache[path] = module

			// Read terragrunt.hcl to find dependencies
			deps, err := findModuleDependencies(path)
			if err != nil {
				return err
			}
			module.Dependencies = deps

			// Track dependencies on common modules
			for _, dep := range deps {
				if strings.Contains(dep, "_envcommon/modules") {
					commonModuleDeps[dep] = append(commonModuleDeps[dep], path)
				}
			}
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("error walking repository: %v", err)
	}

	// Second pass: find modules affected by changed files
	for _, changedFile := range changedFiles {
		// Check if the changed file is in a module directory
		modulePath := findModuleForFile(changedFile, moduleCache)
		if modulePath != "" {
			module := moduleCache[modulePath]
			affectedModules = append(affectedModules, *module)
		}

		// Check if any module depends on the changed file
		for _, module := range moduleCache {
			if isFileInDependencies(changedFile, module.Dependencies) {
				affectedModules = append(affectedModules, *module)
			}
		}

		// Check if changed file is in _envcommon/modules
		if strings.Contains(changedFile, "_envcommon/modules") {
			// Find all modules that depend on this common module
			for commonModule, dependentModules := range commonModuleDeps {
				if strings.Contains(changedFile, commonModule) {
					for _, depModule := range dependentModules {
						if module, exists := moduleCache[depModule]; exists {
							affectedModules = append(affectedModules, *module)
						}
					}
				}
			}
		}

		// Check if account.hcl was changed
		if strings.HasSuffix(changedFile, "account.hcl") {
			accountPath := filepath.Dir(changedFile)
			// Find all modules in this account
			for _, module := range moduleCache {
				if strings.HasPrefix(module.Path, accountPath) {
					affectedModules = append(affectedModules, *module)
				}
			}
		}
	}

	return affectedModules, nil
}

func findAccountPath(path string) string {
	parts := strings.Split(path, string(os.PathSeparator))
	for i := len(parts) - 1; i >= 0; i-- {
		accountPath := filepath.Join(parts[:i+1]...)
		if _, err := os.Stat(filepath.Join(accountPath, "account.hcl")); err == nil {
			return accountPath
		}
	}
	return ""
}

func isTerragruntModule(path string) bool {
	// Check if directory contains terragrunt.hcl
	_, err := os.Stat(filepath.Join(path, "terragrunt.hcl"))
	return err == nil
}

func findModuleDependencies(path string) ([]string, error) {
	// Read terragrunt.hcl file
	content, err := ioutil.ReadFile(filepath.Join(path, "terragrunt.hcl"))
	if err != nil {
		return nil, fmt.Errorf("error reading terragrunt.hcl: %v", err)
	}

	var dependencies []string
	lines := strings.Split(string(content), "\n")

	// Look for include blocks and other dependencies
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "include") {
			// Extract the path from include block
			parts := strings.Split(line, "\"")
			if len(parts) >= 2 {
				dependencies = append(dependencies, parts[1])
			}
		}
	}

	return dependencies, nil
}

func findModuleForFile(file string, moduleCache map[string]*Module) string {
	for modulePath := range moduleCache {
		if strings.HasPrefix(file, modulePath) {
			return modulePath
		}
	}
	return ""
}

func isFileInDependencies(file string, dependencies []string) bool {
	for _, dep := range dependencies {
		if strings.HasPrefix(file, dep) {
			return true
		}
	}
	return false
}

func runTerragruntPlan(modules []Module) error {
	for _, module := range modules {
		log.Printf("Running plan for module: %s (Account: %s, Region: %s, SubEnv: %s)",
			module.Path, module.Account, module.Region, module.SubEnv)

		cmd := exec.Command("terragrunt", "plan", "--terragrunt-working-dir", module.Path)
		output, err := cmd.CombinedOutput()
		if err != nil {
			return fmt.Errorf("error running terragrunt plan for %s: %v\nOutput: %s", module.Path, err, string(output))
		}
		log.Printf("Successfully ran plan for module: %s\nOutput: %s", module.Path, string(output))
	}
	return nil
} 