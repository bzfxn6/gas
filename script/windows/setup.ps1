# Function to check if AWS CLI is installed
function Test-AWSCLI {
    try {
        $awsVersion = aws --version
        Write-Host "AWS CLI is installed: $awsVersion"
        return $true
    } catch {
        Write-Host "AWS CLI is not installed"
        return $false
    }
}

# Function to check if required PowerShell modules are installed
function Test-PowerShellModules {
    $requiredModules = @(
        @{Name = "AWSPowerShell.NetCore"; Version = "4.1.0"},
        @{Name = "AWSPowerShell"; Version = "4.1.0"}
    )

    $missingModules = @()
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module.Name)) {
            $missingModules += $module
        }
    }
    return $missingModules
}

# Function to create AWS config directory and files
function Initialize-AWSConfig {
    $awsConfigPath = "$env:USERPROFILE\.aws"
    if (-not (Test-Path $awsConfigPath)) {
        New-Item -ItemType Directory -Path $awsConfigPath | Out-Null
    }

    # Create config file if it doesn't exist
    $configPath = "$awsConfigPath\config"
    if (-not (Test-Path $configPath)) {
        @"
[default]
region = us-east-1
output = json

"@ | Out-File -FilePath $configPath -Encoding ASCII
    }

    # Create credentials file if it doesn't exist
    $credentialsPath = "$awsConfigPath\credentials"
    if (-not (Test-Path $credentialsPath)) {
        @"
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

"@ | Out-File -FilePath $credentialsPath -Encoding ASCII
    }
}

# Main setup process
Write-Host "Starting setup process..." -ForegroundColor Green

# Check AWS CLI
if (-not (Test-AWSCLI)) {
    Write-Host "AWS CLI is required but not installed. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "You can download it from: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor Yellow
    exit 1
}

# Check PowerShell modules
$missingModules = Test-PowerShellModules
if ($missingModules.Count -gt 0) {
    Write-Host "The following PowerShell modules are required but not installed:" -ForegroundColor Yellow
    foreach ($module in $missingModules) {
        Write-Host "- $($module.Name) (Version $($module.Version))" -ForegroundColor Yellow
    }
    Write-Host "Please install these modules using:" -ForegroundColor Yellow
    Write-Host "Install-Module -Name AWSPowerShell.NetCore -Force" -ForegroundColor Cyan
    Write-Host "Install-Module -Name AWSPowerShell -Force" -ForegroundColor Cyan
    exit 1
}

# Initialize AWS configuration
Write-Host "Initializing AWS configuration..." -ForegroundColor Green
Initialize-AWSConfig

# Check if menu.ps1 exists
if (-not (Test-Path "menu.ps1")) {
    Write-Host "Error: menu.ps1 not found in the current directory" -ForegroundColor Red
    exit 1
}

# Check if aws_accounts.json exists
if (-not (Test-Path "aws_accounts.json")) {
    Write-Host "Error: aws_accounts.json not found in the current directory" -ForegroundColor Red
    exit 1
}

Write-Host "`nSetup completed successfully!" -ForegroundColor Green
Write-Host "`nTo run the menu, use:" -ForegroundColor Cyan
Write-Host ".\menu.ps1" -ForegroundColor White
Write-Host "`nNote: Make sure to update the AWS credentials in $env:USERPROFILE\.aws\credentials with your actual AWS credentials." -ForegroundColor Yellow 