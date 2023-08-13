# Initialize settings
$settingsFile = "ScriptSettings.json"
$settings = @{
    SCCMSiteCode = ""
    SCCMServerName = ""
    AutoDiscovery = $true
    MockMode = $true  # Mock mode enabled by default
}

# Function to load SCCM module
Function Load-SCCMModule {
    if ($settings.MockMode) {
        Write-Host "Mock Mode: Simulating loading SCCM module."
        return $true
    } else {
        # Check if the module is already loaded
        if (-not (Get-Module -Name ConfigurationManager -ErrorAction SilentlyContinue)) {
            try {
                Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
                return $true
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to load SCCM module. Ensure you're running this script in an environment with SCCM cmdlets available.")
                return $false
            }
        }
        return $true
    }
}

# Function to initialize settings
Function Initialize-Settings {
    if (Test-Path $settingsFile) {
        $settings = Get-Content $settingsFile | ConvertFrom-Json
    } else {
        Save-SettingsToFile
    }
}

# Function to save settings to file
Function Save-SettingsToFile {
    $settings | ConvertTo-Json | Set-Content $settingsFile
}
# Function to configure user settings
Function Configure-UserSettings {
    Write-Host "User Settings:"
    Write-Host "1. Auto-Discovery: $($settings.AutoDiscovery)"
    $choice = Read-Host "Enter the number of the setting to configure (or 'q' to quit)"
    if ($choice -eq "1") {
        $autoDiscoveryChoice = Read-Host "Enable Auto-Discovery? (Y/N)"
        $settings.AutoDiscovery = $autoDiscoveryChoice -eq "Y"
        Save-SettingsToFile
    }
}
# Auto-Discovery function
Function Auto-Discover {
    if ($settings.MockMode) {
        # Simulated behavior for mock mode
        $settings.SCCMSiteCode = "MOCK-SITE"
        $settings.SCCMServerName = "MOCK-SERVER"
        Save-SettingsToFile
        Write-Host "Mock Mode: Simulated Auto-Discovery Successful: SCCM Site Code: $($settings.SCCMSiteCode), Server Name: $($settings.SCCMServerName)"
    } else {
        if (Load-SCCMModule) {
            try {
                $siteInfo = Get-CMSite
                $settings.SCCMSiteCode = $siteInfo.SiteCode
                $settings.SCCMServerName = $siteInfo.ServerName
                Save-SettingsToFile
                [System.Windows.Forms.MessageBox]::Show("Auto-Discovery Successful: SCCM Site Code: $($settings.SCCMSiteCode), Server Name: $($settings.SCCMServerName)")
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Auto-Discovery failed. Please enter SCCM settings manually.")
                $settings.AutoDiscovery = $false
            }
        }
    }
}

# Function to simulate SCCM interaction for mock mode
Function Simulate-SCCMInteraction {
    param(
        [string]$action
    )
    Write-Host "Mock Mode: Simulated SCCM interaction - $action"
}

# Rest of the settings-related functions

# Basic GUI setup
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'SCCM Management Tool'
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Text = "SCCM Management Tool"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(120, 20)
$form.Controls.Add($label)

$btnAutoDiscover = New-Object System.Windows.Forms.Button
$btnAutoDiscover.Location = New-Object System.Drawing.Point(100, 60)
$btnAutoDiscover.Size = New-Object System.Drawing.Size(200, 30)
$btnAutoDiscover.Text = 'Auto-Discover SCCM Settings'
$btnAutoDiscover.Add_Click({
    Auto-Discover
})
$form.Controls.Add($btnAutoDiscover)
# Button for Configure User Settings
$btnConfigureSettings = New-Object System.Windows.Forms.Button
$btnConfigureSettings.Location = New-Object System.Drawing.Point(100, 100)
$btnConfigureSettings.Size = New-Object System.Drawing.Size(200, 30)
$btnConfigureSettings.Text = 'Configure User Settings'
$btnConfigureSettings.Add_Click({
    Configure-UserSettings
})
$form.Controls.Add($btnConfigureSettings)

# Button to Check Software Installation
$btnCheckSoftware = New-Object System.Windows.Forms.Button
$btnCheckSoftware.Location = New-Object System.Drawing.Point(100, 140)
$btnCheckSoftware.Size = New-Object System.Drawing.Size(200, 30)
$btnCheckSoftware.Text = 'Check Software Installation'
$btnCheckSoftware.Add_Click({
    $device = Read-Host "Enter Device Name"
    $softwareName = Read-Host "Enter Software Name to Check"
    $softwareCheck = Check-SoftwareInstallation -deviceName $device -softwareName $softwareName
    if ($softwareCheck) {
        [System.Windows.Forms.MessageBox]::Show("$softwareName is installed on $device")
    } else {
        [System.Windows.Forms.MessageBox]::Show("$softwareName is NOT installed on $device")
    }
})
$form.Controls.Add($btnCheckSoftware)

# Button to Send Email Notification
$btnSendEmail = New-Object System.Windows.Forms.Button
$btnSendEmail.Location = New-Object System.Drawing.Point(100, 180)
$btnSendEmail.Size = New-Object System.Drawing.Size(200, 30)
$btnSendEmail.Text = 'Send Email Notification'
$btnSendEmail.Add_Click({
    $recipient = Read-Host "Enter Recipient Email"
    $subject = Read-Host "Enter Email Subject"
    $message = Read-Host "Enter Email Message"
    Send-EmailNotification -recipient $recipient -subject $subject -message $message
})
$form.Controls.Add($btnSendEmail)

# Exit button
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Location = New-Object System.Drawing.Point(100, 220)
$btnExit.Size = New-Object System.Drawing.Size(200, 30)
$btnExit.Text = 'Exit'
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

# Show the form
$form.ShowDialog()

# Function to add a device to a collection
Function Add-DeviceToCollection {
    param(
        [string]$deviceName,
        [string]$collectionID
    )
    if ($settings.MockMode) {
        Simulate-SCCMInteraction -action "Adding device '$deviceName' to collection '$collectionID'"
    } else {
        if (Load-SCCMModule) {
            Add-CMDeviceCollectionDirectMembershipRule -CollectionId $collectionID -ResourceClassName "SMS_R_System" -ResourceID (Get-CMDevice -Name $deviceName).ResourceID
        }
    }
}

# Function to remove a device from a collection
Function Remove-DeviceFromCollection {
    param(
        [string]$deviceName,
        [string]$collectionID
    )
    if ($settings.MockMode) {
        Simulate-SCCMInteraction -action "Removing device '$deviceName' from collection '$collectionID'"
    } else {
        if (Load-SCCMModule) {
            $ruleName = "$deviceName Direct Rule"
            Remove-CMDeviceCollectionDirectMembershipRule -CollectionId $collectionID -RuleName $ruleName
        }
    }
}

# Function to update a collection
Function Update-Collection {
    param(
        [string]$collectionID
    )
    if ($settings.MockMode) {
        Simulate-SCCMInteraction -action "Updating collection '$collectionID'"
    } else {
        if (Load-SCCMModule) {
            Start-CMDeviceCollectionUpdate -CollectionId $collectionID
        }
    }
}

# Function to check software installation
Function Check-SoftwareInstallation {
    param(
        [string]$deviceName,
        [string]$softwareName
    )
    if ($settings.MockMode) {
        Write-Host "Mock Mode: Simulating checking software installation on device '$deviceName'"
        return $false
    } else {
        if (Load-SCCMModule) {
            $installedSoftwares = Get-WmiObject -Class Win32_Product -ComputerName $deviceName
            return $installedSoftwares | Where-Object { $_.Name -like "*$softwareName*" }
        }
    }
}

# Function to send email notification
Function Send-EmailNotification {
    param(
        [string]$recipient,
        [string]$subject,
        [string]$message
    )
    if ($settings.MockMode) {
        Write-Host "Mock Mode: Simulating sending email to '$recipient' with subject '$subject'"
    } else {
        if (Load-SCCMModule) {
            $O365Credential = Get-Credential
            $smtpServer = "smtp.office365.com"
            $smtpPort = 587
            Send-MailMessage -From "yourEmail@domain.com" -To $recipient -Subject $subject -Body $message -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $O365Credential
        }
    }
}

# Rest of the functions and GUI setup
# ...

# [Rest of the GUI setup and event handlers]

# Show the form
$form.ShowDialog()

# Done!

