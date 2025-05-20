Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load AWS accounts from JSON
try {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $accountsData = Get-Content -Path (Join-Path $scriptPath "aws_accounts.json") | ConvertFrom-Json
} catch {
    [System.Windows.Forms.MessageBox]::Show("Error loading aws_accounts.json: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Function to create the main menu form
function Show-MainMenu {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "AWS Account Selector"
    $form.Size = New-Object System.Drawing.Size(400,150)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Create the account selection dropdown
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(120,20)
    $label.Text = "Select AWS Account:"
    $form.Controls.Add($label)

    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = New-Object System.Drawing.Point(140,20)
    $comboBox.Size = New-Object System.Drawing.Size(200,20)
    $comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $accountsData.accounts | ForEach-Object { $comboBox.Items.Add($_.name) }
    $form.Controls.Add($comboBox)

    # Create login button
    $loginButton = New-Object System.Windows.Forms.Button
    $loginButton.Location = New-Object System.Drawing.Point(140,60)
    $loginButton.Size = New-Object System.Drawing.Size(200,30)
    $loginButton.Text = "Login to AWS SSO"
    $loginButton.Enabled = $false
    $form.Controls.Add($loginButton)

    # Add event handler for account selection
    $comboBox.Add_SelectedIndexChanged({
        $loginButton.Enabled = $true
    })

    # Add event handler for login button
    $loginButton.Add_Click({
        $selectedAccount = $accountsData.accounts | Where-Object { $_.name -eq $comboBox.SelectedItem }
        if ($selectedAccount) {
            $form.Hide()
            try {
                # Execute AWS SSO login command
                $command = "aws sso login --profile " + $selectedAccount.name
                Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait
                
                # Show the options menu after successful login
                Show-OptionsMenu -Account $selectedAccount
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Error during AWS SSO login: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $form.Show()
            }
        }
    })

    $form.ShowDialog()
}

# Function to create the options menu form
function Show-OptionsMenu {
    param (
        [Parameter(Mandatory=$true)]
        $Account
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "AWS Account Options - $($Account.name)"
    $form.Size = New-Object System.Drawing.Size(400,300)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    # Account info label
    $accountLabel = New-Object System.Windows.Forms.Label
    $accountLabel.Location = New-Object System.Drawing.Point(10,20)
    $accountLabel.Size = New-Object System.Drawing.Size(360,20)
    $accountLabel.Text = "Connected to: $($Account.name) ($($Account.account_number))"
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
            $command = "aws ec2 describe-instances --filters `"Name=tag:Name,Values=$($Account.ec2_tag)`" --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' --output text --profile $($Account.name)"
            $instanceId = Invoke-Expression $command

            if ([string]::IsNullOrEmpty($instanceId)) {
                throw "No running instance found with tag: $($Account.ec2_tag)"
            }

            # Start SSM port forwarding in background
            $ssmCommand = "aws ssm start-session --target $instanceId --document-name AWS-StartPortForwardingSession --parameters `"localPortNumber=$($Account.rdp_port),portNumber=3389`" --profile $($Account.name)"
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
                $s3Path = "s3://$($Account.s3_bucket)/$($Account.upload_folder)/"

                if ($selectedItems -is [string]) {
                    # Single folder selected
                    $folderName = Split-Path $selectedItems -Leaf
                    $command = "aws s3 cp `"$selectedItems`" $s3Path$folderName/ --recursive --profile $($Account.name)"
                    Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait
                } else {
                    # Multiple files selected
                    foreach ($file in $selectedItems) {
                        $fileName = Split-Path $file -Leaf
                        $command = "aws s3 cp `"$file`" $s3Path$fileName --profile $($Account.name)"
                        Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait
                    }
                }

                [System.Windows.Forms.MessageBox]::Show("Files uploaded successfully to $s3Path", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error uploading files: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($uploadButton)

    # Download from S3 Button
    $downloadButton = New-Object System.Windows.Forms.Button
    $downloadButton.Location = New-Object System.Drawing.Point(20,($buttonY + ($buttonHeight + $buttonSpacing) * 2))
    $downloadButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $downloadButton.Text = "3. Download Files from S3"
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
                $command = "aws s3 ls s3://$($Account.s3_bucket)/$Prefix --recursive --profile $($Account.name)"
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
                    
                    if ($item.SubItems[1].Text -eq "Folder") {
                        # Download folder
                        $command = "aws s3 cp s3://$($Account.s3_bucket)/$s3Path $localPath --recursive --profile $($Account.name)"
                    } else {
                        # Download file
                        $command = "aws s3 cp s3://$($Account.s3_bucket)/$s3Path $localPath --profile $($Account.name)"
                    }
                    
                    Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait
                }

                [System.Windows.Forms.MessageBox]::Show("Files downloaded successfully to your Downloads folder", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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
    $logoutButton.Location = New-Object System.Drawing.Point(20,($buttonY + ($buttonHeight + $buttonSpacing) * 3))
    $logoutButton.Size = New-Object System.Drawing.Size(340,$buttonHeight)
    $logoutButton.Text = "4. Logout of AWS Account"
    $logoutButton.Add_Click({
        try {
            # Execute AWS SSO logout command
            $command = "aws sso logout --profile $($Account.name)"
            Start-Process powershell -ArgumentList "-NoProfile -Command `"$command`"" -NoNewWindow -Wait

            # Show success message
            [System.Windows.Forms.MessageBox]::Show("Successfully logged out of AWS account: $($Account.name)", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            # Close the current form
            $form.Close()
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error during logout: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
    $form.Controls.Add($logoutButton)

    $form.ShowDialog()
}

# Start the application
Show-MainMenu 