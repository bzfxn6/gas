# AWS Account Manager

This tool provides a Windows GUI for managing AWS accounts, including RDP connections, S3 file operations, and AWS SSO login/logout.

## Prerequisites

Before running the tool, ensure you have the following installed:

1. AWS CLI v2
   - Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
   - Save the installer to the same directory as these scripts

2. Required PowerShell Modules:
   - AWSPowerShell.NetCore
   - AWSPowerShell

## Setup Instructions

1. Copy all files to a directory on your Windows server:
   - `menu.ps1`
   - `setup.ps1`
   - `aws_accounts.json`
   - `AWSCLIV2.msi` (AWS CLI installer)
   - `README.md`

2. Run the setup script:
   ```powershell
   .\setup.ps1
   ```

3. The setup script will:
   - Check for AWS CLI installation
   - Check for required PowerShell modules
   - Create AWS configuration directory and files
   - Verify all required files are present

4. Update the AWS credentials:
   - Open `%USERPROFILE%\.aws\credentials`
   - Replace `YOUR_ACCESS_KEY` and `YOUR_SECRET_KEY` with your actual AWS credentials

## Running the Tool

After setup is complete, run the menu:
```powershell
.\menu.ps1
```

## Features

- AWS SSO Login/Logout
- RDP to Tuning Servers via SSM
- S3 File Upload/Download
- Account-specific configurations

## Troubleshooting

If you encounter any issues:

1. Check AWS CLI installation:
   ```powershell
   aws --version
   ```

2. Verify PowerShell modules:
   ```powershell
   Get-Module -ListAvailable AWSPowerShell*
   ```

3. Check AWS credentials:
   ```powershell
   aws sts get-caller-identity
   ```

4. Ensure all files are in the same directory:
   - `menu.ps1`
   - `aws_accounts.json`
   - `setup.ps1` 