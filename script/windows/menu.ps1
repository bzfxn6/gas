Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define log file path
$logFilePath = Join-Path $env:TEMP ("aws_profile_debug_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    Add-Content -Path $logFilePath -Value "[$(Get-Date)] $message"
}

Log-Message "Script started"

# Load AWS accounts from JSON
try {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    Log-Message "Script path: $scriptPath"

    $jsonPath = Join-Path $scriptPath "aws_accounts.json"
    Log-Message "Attempting to load JSON from: $jsonPath"

    $accountsData = Get-Content -Path $jsonPath | ConvertFrom-Json
    Log-Message "Loaded $($accountsData.accounts.Count) AWS accounts"
    
    # Check if there are any accounts
    if ($accountsData.accounts.Count -eq 0) {
        Log-Message "No AWS accounts found in the JSON file"
        [System.Windows.Forms.MessageBox]::Show("No AWS accounts found in aws_accounts.json. Please add accounts to the file.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        exit
    }
} catch {
    Log-Message "Error loading aws_accounts.json: $_"
    [System.Windows.Forms.MessageBox]::Show("Error loading aws_accounts.json: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Function to create the options menu form
function Show-OptionsMenu {
    param (
        [Parameter(Mandatory=$true)]
        $Account
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "AWS Account Options - $($Account.name)"
    $form.Size = New-Object System.Drawing.Size(400,400)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Account info label
    $accountLabel = New-Object System.Windows.Forms.Label
    $accountLabel.Location = New-Object System.Drawing.Point(10,20)
    $accountLabel.Size = New-Object System.Drawing.Size(360,20)
    $accountLabel.Text = "Connected to: $($Account.name) ($($Account.account_number)) - Region: $($Account.region)"
    $form.Controls.Add($accountLabel)

    # Create buttons for each option
    $buttonY = 60
    $buttonHeight = 40
    $buttonSpacing = 10

    # RDP Button
    $rdpButton = New-Object System.Windows.Forms.Button
    $rdpButton.Location = New-Object System.Drawing.Point(20,$buttonY)
    $rdpButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $rdpButton.Text = "1. RDP to Tuning Server"
    $rdpButton.Add_Click({
        try {
            # Get EC2 instance ID using the tag
            $tagValue = $Account.ec2_tag
            $awsProfile = $Account.name
            $region = $Account.region

            $command = "aws ec2 describe-instances --filters Name=tag:Name,Values=$tagValue --query `"Reservations[].Instances[?State.Name=='running'].InstanceId`" --output text --profile $awsProfile --region $region"

            Write-Host "Executing command:"
            Write-Host $command

            # Debug output
            Write-Host "Executing command: $command"
            $instanceId = Invoke-Expression $command
            Write-Host "Command response: $instanceId"

            if ([string]::IsNullOrEmpty($instanceId)) {
                throw "No running instance found with tag: $($Account.ec2_tag) in region: $($Account.region)"
            }

            # Start SSM port forwarding in background
            $ssmCommand = "aws ssm start-session --target $instanceId --document-name AWS-StartPortForwardingSession --parameters localPortNumber=$($Account.rdp_port),portNumber=3389 --profile $($Account.name) --region $($Account.region)"
            $ssmProcess = Start-Process powershell -ArgumentList "-NoProfile -Command `"$ssmCommand`"" -PassThru -NoNewWindow

            # Wait a moment for the port forwarding to establish
            Start-Sleep -Seconds 3

            # Create RDP connection string
            $rdpFile = [System.IO.Path]::GetTempFileName() + ".rdp"
            @"
full address:s:localhost`:$($Account.rdp_port)
prompt for credentials:i:1
"@ | Out-File -FilePath $rdpFile -Encoding ASCII

            # Launch RDP connection
            Start-Process mstsc -ArgumentList $rdpFile

            # Wait for RDP process to start
            Start-Sleep -Seconds 2

            # Clean up RDP file
            Remove-Item $rdpFile -Force

            # Show message about SSM session
            [System.Windows.Forms.MessageBox]::Show("RDP connection started. The SSM session will remain active until you close the RDP window.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

            # Add event handler to clean up SSM session when RDP closes
            $rdpProcess = Get-Process | Where-Object { $_.ProcessName -eq "mstsc" } | Select-Object -First 1
            if ($rdpProcess) {
                $rdpProcess.EnableRaisingEvents = $true
                Register-ObjectEvent -InputObject $rdpProcess -EventName Exited -Action {
                    Stop-Process -Id $ssmProcess.Id -Force
                    Unregister-Event -SourceIdentifier $Event.SourceIdentifier
                }
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error connecting to RDP: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            if ($ssmProcess) {
                Stop-Process -Id $ssmProcess.Id -Force
            }
        }
    })
    $form.Controls.Add($rdpButton)

    # Upload to S3 Button
    $uploadButton = New-Object System.Windows.Forms.Button
    $uploadButton.Location = New-Object System.Drawing.Point(20,($buttonY + $buttonHeight + $buttonSpacing))
    $uploadButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $uploadButton.Text = "2. Upload Files to S3"
    $uploadButton.Add_Click({
        try {
            # Create a form for selection type
            $selectionForm = New-Object System.Windows.Forms.Form
            $selectionForm.Text = "Select Upload Type"
            $selectionForm.Size = New-Object System.Drawing.Size(300,150)
            $selectionForm.StartPosition = "CenterScreen"
            $selectionForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
            $selectionForm.MaximizeBox = $false
            $selectionForm.MinimizeBox = $false

            # Create buttons for file and folder selection
            $fileButton = New-Object System.Windows.Forms.Button
            $fileButton.Location = New-Object System.Drawing.Point(20,20)
            $fileButton.Size = New-Object System.Drawing.Size(240,30)
            $fileButton.Text = "Select Files"
            $selectionForm.Controls.Add($fileButton)

            $folderButton = New-Object System.Windows.Forms.Button
            $folderButton.Location = New-Object System.Drawing.Point(20,60)
            $folderButton.Size = New-Object System.Drawing.Size(240,30)
            $folderButton.Text = "Select Folder"
            $selectionForm.Controls.Add($folderButton)

            # Handle file selection
            $fileButton.Add_Click({
                $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $openFileDialog.Multiselect = $true
                if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectionForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
                    $selectionForm.Tag = $openFileDialog.FileNames
                }
            })

            # Handle folder selection
            $folderButton.Add_Click({
                $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
                if ($folderBrowserDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectionForm.DialogResult = [System.Windows.Forms.DialogResult]::OK
                    $selectionForm.Tag = $folderBrowserDialog.SelectedPath
                }
            })

            if ($selectionForm.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $selectedItems = $selectionForm.Tag
                if ($selectedItems -is [string]) {
                    # Single folder selected
                    $folderName = Split-Path $selectedItems -Leaf
                    $s3Path = "s3://$($Account.s3_bucket)/$($Account.upload_folder)/$folderName/"
                    $escapedLocalPath = "`"$selectedItems`""
                    $escapedS3Path = "`"$s3Path`""

                    $arguments = @(
                        "s3", "cp",
                        $escapedLocalPath,
                        $escapedS3Path,
                        "--recursive",
                        "--profile", $Account.name,
                        "--region", $Account.region
                    )

                    Start-Process "aws" -ArgumentList $arguments -NoNewWindow -Wait
                } else {
                    # Multiple files selected
                    foreach ($file in $selectedItems) {
                        $fileName = Split-Path $file -Leaf
                        $s3Path = "s3://$($Account.s3_bucket)/$($Account.upload_folder)/$fileName"
                        $escapedFile = "`"$file`""
                        $escapedS3Path = "`"$s3Path`""

                        $arguments = @(
                            "s3", "cp",
                            $escapedFile,
                            $escapedS3Path,
                            "--profile", $Account.name,
                            "--region", $Account.region
                        )

                        Start-Process "aws" -ArgumentList $arguments -NoNewWindow -Wait
                    }
                }

                [System.Windows.Forms.MessageBox]::Show("Files uploaded successfully to $s3Path", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error uploading files: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($uploadButton)

    # List S3 Bucket Button
    $listButton = New-Object System.Windows.Forms.Button
    $listButton.Location = New-Object System.Drawing.Point(20,($buttonY + ($buttonHeight + $buttonSpacing) * 2))
    $listButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $listButton.Text = "3. List S3 Bucket Contents"
    $listButton.Add_Click({
        try {
            # Create form to display S3 contents
            $s3Form = New-Object System.Windows.Forms.Form
            $s3Form.Text = "S3 Bucket Contents - $($Account.s3_bucket)"
            $s3Form.Size = New-Object System.Drawing.Size(800,600)
            $s3Form.StartPosition = "CenterScreen"

            # Create ListView for S3 contents
            $listView = New-Object System.Windows.Forms.ListView
            $listView.Location = New-Object System.Drawing.Point(10,10)
            $listView.Size = New-Object System.Drawing.Size(760,500)
            $listView.View = [System.Windows.Forms.View]::Details
            $listView.FullRowSelect = $true
            $listView.MultiSelect = $true
            $listView.Columns.Add("Name", 400)
            $listView.Columns.Add("Type", 100)
            $listView.Columns.Add("Size", 100)
            $listView.Columns.Add("Last Modified", 150)
            $s3Form.Controls.Add($listView)

            # Function to list S3 contents
            function Get-S3Contents {
                param (
                    [string]$Prefix = ""
                )
                $listView.Items.Clear()
                $command = "aws s3 ls s3://$($Account.s3_bucket)/$Prefix --recursive --profile $($Account.name) --region $($Account.region)"
                $items = Invoke-Expression $command

                foreach ($item in $items) {
                    $parts = $item -split '\s+'
                    $date = $parts[0]
                    $time = $parts[1]
                    $size = $parts[2]
                    $path = $parts[3]
                    
                    $listItem = New-Object System.Windows.Forms.ListViewItem
                    $listItem.Text = $path
                    $itemType = if ($path.EndsWith("/")) { "Folder" } else { "File" }
                    $listItem.SubItems.Add($itemType)
                    $listItem.SubItems.Add($size)
                    $listItem.SubItems.Add("$date $time")
                    $listView.Items.Add($listItem)
                }
            }

            # Create refresh button
            $refreshButton = New-Object System.Windows.Forms.Button
            $refreshButton.Location = New-Object System.Drawing.Point(10,520)
            $refreshButton.Size = New-Object System.Drawing.Size(100,30)
            $refreshButton.Text = "Refresh"
            $refreshButton.Add_Click({ Get-S3Contents })
            $s3Form.Controls.Add($refreshButton)

            # Initial load of S3 contents
            Get-S3Contents
            $s3Form.ShowDialog()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error listing S3 contents: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($listButton)

    # Download from S3 Button
    $downloadButton = New-Object System.Windows.Forms.Button
    $downloadButton.Location = New-Object System.Drawing.Point(20,($buttonY + ($buttonHeight + $buttonSpacing) * 3))
    $downloadButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $downloadButton.Text = "4. Download Files from S3"
    $downloadButton.Add_Click({
        try {
            # Create form to display S3 contents
            $s3Form = New-Object System.Windows.Forms.Form
            $s3Form.Text = "Select Files to Download from $($Account.s3_bucket)"
            $s3Form.Size = New-Object System.Drawing.Size(600,400)
            $s3Form.StartPosition = "CenterScreen"

            # Create ListView for S3 contents
            $listView = New-Object System.Windows.Forms.ListView
            $listView.Location = New-Object System.Drawing.Point(10,10)
            $listView.Size = New-Object System.Drawing.Size(560,300)
            $listView.View = [System.Windows.Forms.View]::Details
            $listView.FullRowSelect = $true
            $listView.MultiSelect = $true
            $listView.Columns.Add("Name", 300)
            $listView.Columns.Add("Type", 100)
            $listView.Columns.Add("Size", 100)
            $s3Form.Controls.Add($listView)

            # Function to list S3 contents
            function Get-S3Contents {
                param (
                    [string]$Prefix = ""
                )
                $listView.Items.Clear()
                $command = "aws s3 ls s3://$($Account.s3_bucket)/$Prefix --recursive --profile $($Account.name) --region $($Account.region)"
                $items = Invoke-Expression $command

                foreach ($item in $items) {
                    $parts = $item -split '\s+'
                    $size = $parts[2]
                    $path = $parts[3]
                    
                    $listItem = New-Object System.Windows.Forms.ListViewItem
                    $listItem.Text = $path
                    $itemType = if ($path.EndsWith("/")) { "Folder" } else { "File" }
                    $listItem.SubItems.Add($itemType)
                    $listItem.SubItems.Add($size)
                    $listView.Items.Add($listItem)
                }
            }

            # Create buttons
            $refreshButton = New-Object System.Windows.Forms.Button
            $refreshButton.Location = New-Object System.Drawing.Point(10,320)
            $refreshButton.Size = New-Object System.Drawing.Size(100,30)
            $refreshButton.Text = "Refresh"
            $refreshButton.Add_Click({ Get-S3Contents })
            $s3Form.Controls.Add($refreshButton)

            $downloadSelectedButton = New-Object System.Windows.Forms.Button
            $downloadSelectedButton.Location = New-Object System.Drawing.Point(470,320)
            $downloadSelectedButton.Size = New-Object System.Drawing.Size(100,30)
            $downloadSelectedButton.Text = "Download Selected"
            $s3Form.Controls.Add($downloadSelectedButton)

            # Handle download button click
            $downloadSelectedButton.Add_Click({
                if ($listView.SelectedItems.Count -eq 0) {
                    [System.Windows.Forms.MessageBox]::Show("Please select files or folders to download", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                    return
                }

                # Get user's Downloads folder
                $downloadsPath = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
                
                foreach ($item in $listView.SelectedItems) {
                    $s3Path = $item.Text
                    $localPath = Join-Path $downloadsPath (Split-Path $s3Path -Leaf)
                    $escapedLocalPath = "`"$localPath`""

                    if ($item.SubItems[1].Text -eq "Folder") {
                        # Download folder
                        $command = "aws s3 cp `"s3://$($Account.s3_bucket)/$s3Path`" $escapedLocalPath --recursive --profile $($Account.name) --region $($Account.region)"
                    } else {
                        # Download file
                        $command = "aws s3 cp `"s3://$($Account.s3_bucket)/$s3Path`" $escapedLocalPath --profile $($Account.name) --region $($Account.region)"
                    }

                    # Debug output
                    Write-Host "Executing download command: $command"
                    try {
                        Invoke-Expression $command
                        Write-Host "Download completed successfully"

                        # Update timestamps
                        if ($item.SubItems[1].Text -eq "Folder") {
                            if (Test-Path $localPath) {
                                Get-ChildItem -Path $localPath -Recurse -File | ForEach-Object {
                                    $_.LastWriteTime = Get-Date
                                }
                            }
                        } else {
                            if (Test-Path $localPath) {
                                (Get-Item $localPath).LastWriteTime = Get-Date
                            }
                        }
                    } catch {
                        Write-Host "Error during download: $_"
                        [System.Windows.Forms.MessageBox]::Show("Error downloading file: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }

                [System.Windows.Forms.MessageBox]::Show("Files downloaded successfully to your Downloads folder", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                
                # Ask if user wants to logout
                $logoutResult = [System.Windows.Forms.MessageBox]::Show("Would you like to logout of AWS account?", "Logout", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($logoutResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                    try {
                        # Execute AWS SSO logout command
                        $command = "aws sso logout --profile $($Account.name)"
                        Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait

                        # Show success message
                        [System.Windows.Forms.MessageBox]::Show("Successfully logged out of AWS account: $($Account.name)", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                        
                        # Close and dispose the current form
                        $s3Form.Dispose()
                        
                        # Show the main menu
                        Show-MainMenu
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error during logout: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }
                
                $s3Form.Close()
            })

            # Initial load of S3 contents
            Get-S3Contents
            $s3Form.ShowDialog()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error downloading files: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($downloadButton)

    # Logout Button
    $logoutButton = New-Object System.Windows.Forms.Button
    $logoutButton.Location = New-Object System.Drawing.Point(20,($buttonY + ($buttonHeight + $buttonSpacing) * 4))
    $logoutButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $logoutButton.Text = "5. Logout of AWS Account"
    $logoutButton.Add_Click({
        try {
            # Execute AWS SSO logout command
            $command = "aws sso logout --profile $($Account.name)"
            Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait

            # Show success message
            [System.Windows.Forms.MessageBox]::Show("Successfully logged out of AWS account: $($Account.name)", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            # Close and dispose the current form
            $form.Dispose()
            
            # Show the main menu
            Show-MainMenu
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error during logout: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($logoutButton)

    $form.ShowDialog()
}

# Function to create the main menu form
function Show-MainMenu {
    Log-Message "Initializing main menu form"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "AWS Account Selector"
    $form.Size = New-Object System.Drawing.Size(420, 180)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.Size = New-Object System.Drawing.Size(120, 20)
    $label.Text = "Select AWS Account:"
    $form.Controls.Add($label)

    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(140, 20)
    $comboBox.Size = New-Object System.Drawing.Size(250, 20)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    Log-Message "Populating ComboBox with account names"
    try {
        if ($accountsData.accounts.Count -gt 0) {
            $accountsData.accounts | ForEach-Object {
                Log-Message "Adding account to ComboBox: $($_.name)"
                $comboBox.Items.Add($_.name)
            }
            # Select the first item in the ComboBox
            $comboBox.SelectedIndex = 0
        } else {
            Log-Message "No accounts available to populate ComboBox"
            [System.Windows.Forms.MessageBox]::Show("No AWS accounts available. Please check aws_accounts.json.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $form.Close()
            return
        }
    } catch {
        Log-Message "Error populating ComboBox: $_"
        $null = [System.Windows.Forms.MessageBox]::Show("Error populating account list: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    $form.Controls.Add($comboBox)

    $loginButton = New-Object System.Windows.Forms.Button
    $loginButton.Location = New-Object System.Drawing.Point(20, 60)
    $loginButton.Size = New-Object System.Drawing.Size(120, 30)
    $loginButton.Text = "Login to AWS SSO"
    $loginButton.Enabled = $false
    $form.Controls.Add($loginButton)

    $useAccountButton = New-Object System.Windows.Forms.Button
    $useAccountButton.Location = New-Object System.Drawing.Point(150, 60)
    $useAccountButton.Size = New-Object System.Drawing.Size(120, 30)
    $useAccountButton.Text = "Use Account"
    $useAccountButton.Enabled = $false
    $form.Controls.Add($useAccountButton)

    $addProfileButton = New-Object System.Windows.Forms.Button
    $addProfileButton.Location = New-Object System.Drawing.Point(280, 60)
    $addProfileButton.Size = New-Object System.Drawing.Size(120, 30)
    $addProfileButton.Text = "Add AWS Profile"
    $addProfileButton.Enabled = $false
    $form.Controls.Add($addProfileButton)

    # Enable buttons if an account is selected
    if ($comboBox.SelectedIndex -ge 0) {
        $loginButton.Enabled = $true
        $useAccountButton.Enabled = $true
        $addProfileButton.Enabled = $true
    }

    $comboBox.Add_SelectedIndexChanged({
        $selected = $comboBox.SelectedItem
        Log-Message "User selected account: $selected"
        $loginButton.Enabled = $true
        $useAccountButton.Enabled = $true
        $addProfileButton.Enabled = $true
    })

    $loginButton.Add_Click({
        $selectedAccount = $accountsData.accounts | Where-Object { $_.name -eq $comboBox.SelectedItem }
        if ($selectedAccount) {
            Log-Message "Login button clicked for account: $($selectedAccount.name)"
            $form.Hide()
            try {
                $command = "aws sso login --profile " + $selectedAccount.name
                Log-Message "Executing command: $command"
                Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -Wait

                $maxWait = 30
                $waited = 0
                while ($waited -lt $maxWait) {
                    try {
                        Log-Message "Checking if profile $($selectedAccount.name) is ready (attempt $waited)"
                        $identity = aws sts get-caller-identity --profile $selectedAccount.name 2>$null
                        $configCheck = aws configure list --profile $selectedAccount.name 2>$null

                        if ($identity -and $configCheck) {
                            Log-Message "Profile $($selectedAccount.name) is ready"
                            Show-OptionsMenu -Account $selectedAccount
                            $form.Close()
                            return
                        }
                    } catch {
                        Log-Message "Attempt $waited failed for profile $($selectedAccount.name)"
                    }
                    Start-Sleep -Seconds 1
                    $waited++
                }

                Log-Message "Login may not have completed successfully for profile $($selectedAccount.name)"
                $null = [System.Windows.Forms.MessageBox]::Show("Login may not have completed successfully. Please try again.", "Login Timeout", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                $form.Show()
            } catch {
                Log-Message "Error during AWS SSO login: $_"
                $null = [System.Windows.Forms.MessageBox]::Show("Error during AWS SSO login: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $form.Show()
            }
        }
    })

    $useAccountButton.Add_Click({
        $selectedAccount = $accountsData.accounts | Where-Object { $_.name -eq $comboBox.SelectedItem }
        if ($selectedAccount) {
            Log-Message "Use Account button clicked for: $($selectedAccount.name)"
            $form.Hide()
            Start-Sleep -Seconds 1

            $maxWait = 15
            $waited = 0
            while ($waited -lt $maxWait) {
                try {
                    Log-Message "Checking if profile $($selectedAccount.name) is ready (attempt $waited)"
                    $identity = aws sts get-caller-identity --profile $selectedAccount.name 2>$null
                    $configCheck = aws configure list --profile $selectedAccount.name 2>$null

                    if ($identity -and $configCheck) {
                        Log-Message "Profile $($selectedAccount.name) is ready"
                        Show-OptionsMenu -Account $selectedAccount
                        $form.Close()
                        return
                    }
                } catch {
                    Log-Message "Attempt $waited failed for profile $($selectedAccount.name)"
                }
                Start-Sleep -Seconds 1
                $waited++
            }

            Log-Message "Profile $($selectedAccount.name) is not ready or credentials are missing"
            $null = [System.Windows.Forms.MessageBox]::Show("AWS profile '$($selectedAccount.name)' is not ready or credentials are missing. Please log in first.", "Profile Not Ready", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            $form.Show()
        }
    })

    $addProfileButton.Add_Click({
        $selectedAccount = $accountsData.accounts | Where-Object { $_.name -eq $comboBox.SelectedItem }
        if ($selectedAccount) {
            Log-Message "Add Profile button clicked for: $($selectedAccount.name)"
            $configPath = "$HOME\.aws\config"
            $profileHeader = "[profile $($selectedAccount.name)]"

            if (-not (Test-Path $configPath)) {
                New-Item -ItemType File -Path $configPath -Force | Out-Null
            }

            if (-not (Get-Content $configPath | Select-String -SimpleMatch $profileHeader)) {
                $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
                $backupPath = "$configPath.backup.$timestamp"
                Copy-Item -Path $configPath -Destination $backupPath -Force

                $profileBlock = @"

$profileHeader
sso_start_url = $($selectedAccount.sso_start_url)
sso_region = $($selectedAccount.sso_region)
sso_account_id = $($selectedAccount.account_number)
sso_role_name = $($selectedAccount.sso_role_name)
region = $($selectedAccount.region)
output = json
"@
                Add-Content -Path $configPath -Value $profileBlock
                $null = [System.Windows.Forms.MessageBox]::Show("Profile `"$($selectedAccount.name)`" added to AWS config. Backup created at `"$backupPath`".", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $null = [System.Windows.Forms.MessageBox]::Show("Profile `"$($selectedAccount.name)`" already exists in AWS config.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
    })

    $form.ShowDialog()
}

# Start the application
try {
    Show-MainMenu
} catch {
    $errorMessage = "Unhandled exception: $_"
    Log-Message $errorMessage
    $null = [System.Windows.Forms.MessageBox]::Show($errorMessage, "Fatal Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}