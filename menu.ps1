Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Load AWS accounts from JSON
try {
    $accountsData = Get-Content -Path "aws_accounts.json" | ConvertFrom-Json
} catch {
    [System.Windows.Forms.MessageBox]::Show("Error loading aws_accounts.json: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AWS Account Selector"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

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

# Create the details group box
$groupBox = New-Object System.Windows.Forms.GroupBox
$groupBox.Location = New-Object System.Drawing.Point(10,60)
$groupBox.Size = New-Object System.Drawing.Size(560,200)
$groupBox.Text = "Account Details"
$form.Controls.Add($groupBox)

# Create labels for account details
$accountNumberLabel = New-Object System.Windows.Forms.Label
$accountNumberLabel.Location = New-Object System.Drawing.Point(20,30)
$accountNumberLabel.Size = New-Object System.Drawing.Size(120,20)
$accountNumberLabel.Text = "Account Number:"
$groupBox.Controls.Add($accountNumberLabel)

$accountNumberValue = New-Object System.Windows.Forms.Label
$accountNumberValue.Location = New-Object System.Drawing.Point(150,30)
$accountNumberValue.Size = New-Object System.Drawing.Size(200,20)
$groupBox.Controls.Add($accountNumberValue)

$s3BucketLabel = New-Object System.Windows.Forms.Label
$s3BucketLabel.Location = New-Object System.Drawing.Point(20,60)
$s3BucketLabel.Size = New-Object System.Drawing.Size(120,20)
$s3BucketLabel.Text = "S3 Bucket:"
$groupBox.Controls.Add($s3BucketLabel)

$s3BucketValue = New-Object System.Windows.Forms.Label
$s3BucketValue.Location = New-Object System.Drawing.Point(150,60)
$s3BucketValue.Size = New-Object System.Drawing.Size(200,20)
$groupBox.Controls.Add($s3BucketValue)

$regionLabel = New-Object System.Windows.Forms.Label
$regionLabel.Location = New-Object System.Drawing.Point(20,90)
$regionLabel.Size = New-Object System.Drawing.Size(120,20)
$regionLabel.Text = "Region:"
$groupBox.Controls.Add($regionLabel)

$regionValue = New-Object System.Windows.Forms.Label
$regionValue.Location = New-Object System.Drawing.Point(150,90)
$regionValue.Size = New-Object System.Drawing.Size(200,20)
$groupBox.Controls.Add($regionValue)

# Add event handler for account selection
$comboBox.Add_SelectedIndexChanged({
    $selectedAccount = $accountsData.accounts | Where-Object { $_.name -eq $comboBox.SelectedItem }
    if ($selectedAccount) {
        $accountNumberValue.Text = $selectedAccount.account_number
        $s3BucketValue.Text = $selectedAccount.s3_bucket
        $regionValue.Text = $selectedAccount.region
    }
})

# Show the form
$form.ShowDialog() 