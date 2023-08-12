# Improved SCCM Script

# Initialize variables
$workingDirectory = "C:\temp\powershell"
$logFilePath = "$workingDirectory\script_log.txt"
$verboseLogFilePath = "$workingDirectory\verbose_log.txt"
$processedItemsFilePath = "$workingDirectory\processed_items.txt"
$settingsFilePath = "$workingDirectory\script_settings.txt"
$devicesFilePath = "$workingDirectory\devices.txt"
$collectionsFilePath = "$workingDirectory\collections.txt"

# Function to import SCCM modules and connect to the site
Function Initialize-SCCM {
    Import-Module ConfigurationManager
    Import-Module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

    try {
        $PSD = Get-PSDrive -PSProvider CMSite
        CD "$($PSD):"
    } catch {
        Write-Host "Error connecting to SCCM site. Please ensure SCCM console is open."
        exit
    }
}

# Function to set up working directories and file paths
Function Setup-Directories {
    if (-not (Test-Path $workingDirectory)) {
        New-Item -Path $workingDirectory -ItemType Directory | Out-Null
    }
    if (Test-Path $settingsFilePath) {
        $settings = Get-Content $settingsFilePath
        $workingDirectory = $settings[0]
        $verboseLoggingEnabled = [bool]::Parse($settings[1])
    } else {
        $verboseLoggingEnabled = $false
    }

    $paths = @($logFilePath, $verboseLogFilePath, $processedItemsFilePath, $settingsFilePath, $devicesFilePath, $collectionsFilePath)
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType File | Out-Null
        } else {
            try {
                # Try to open the file to check if it's locked
                $fileStream = [System.IO.File]::Open($path, 'Open', 'Write')
                $fileStream.Close()
            } catch {
                # File is locked, create a secondary file
                $path = $path -replace "\.txt$", "_2.txt"
            }
        }
    }
}

# Function to update collection membership
Function Update-CollectionMembership {
    param (
        [string]$deviceName,
        [string]$collectionID,
        [bool]$add
    )

    try {
        $device = Get-CMDevice -Name $deviceName -ErrorAction SilentlyContinue
        if ($device -eq $null) {
            Write-Host "$deviceName not found in SCCM."
            return
        }

        $existingMembership = Get-CMDeviceCollectionMembership -CollectionId $collectionID -ResourceId $device.ResourceID -ErrorAction SilentlyContinue

        if ($add -and $existingMembership -eq $null) {
            Add-CMDeviceCollectionDirectMembershipRule -CollectionId $collectionID -ResourceID $device.ResourceID
            Invoke-CMCollectionUpdate -CollectionId $collectionID
            $message = "Added $deviceName to Collection $collectionID"
        } elseif (-not $add -and $existingMembership -ne $null) {
            Remove-CMDirectMembershipRule -CollectionId $collectionID -ResourceId $device.ResourceID
            Invoke-CMCollectionUpdate -CollectionId $collectionID
            $message = "Removed $deviceName from Collection $collectionID"
        } else {
            $message = "$deviceName is already not a member of Collection $collectionID"
        }

        Write-Host $message
        Write-Log $message
        Write-ProcessedItem "$deviceName membership in Collection $collectionID updated"
    } catch {
        $message = "Failed to update $deviceName membership in Collection $collectionID"
        Write-Host $message
        Write-Log $message
    }
}

# Function to write log
Function Write-Log {
    param (
        [string]$message
    )
    
    $message | Out-File -Append -FilePath $logFilePath
    if ($verboseLoggingEnabled) {
        $message | Out-File -Append -FilePath $verboseLogFilePath
    }
}

# Function to write processed items log
Function Write-ProcessedItem {
    param (
        [string]$message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -Append -FilePath $processedItemsFilePath
}

# Function to show main menu
Function Show-Menu {
    Clear-Host
    Write-Host "Main Menu:"
    Write-Host "1. Manually Add Device to Collection"
    Write-Host "2. Manually Remove Device from Collection"
    Write-Host "3. Trigger Processing from Files"
    Write-Host "4. View Log"
    Write-Host "5. Exit"
    Write-Host "6. Settings"
    $choice = Read-Host "Enter your choice"
    return $choice
}

# Function to show settings menu
Function Show-SettingsMenu {
    Clear-Host
    Write-Host "Settings Menu:"
    Write-Host "1. Configure Working Directory ($workingDirectory)"
    Write-Host "2. Toggle Verbose Logging ($verboseLoggingEnabled)"
    Write-Host "3. Back to Main Menu"
    $choice = Read-Host "Enter your choice"
    
    if ($choice -eq "1") {
        $newWorkingDirectory = Read-Host "Enter the new working directory"
        if (-not [string]::IsNullOrWhiteSpace($newWorkingDirectory)) {
            $workingDirectory = $newWorkingDirectory
            $settings[0] = $workingDirectory
            Set-Content -Path $settingsFilePath -Value $settings
        } else {
            Write-Host "Working directory cannot be empty."
            Read-Host "Press Enter to continue"
        }
    } elseif ($choice -eq "2") {
        $verboseLoggingEnabled = -not $verboseLoggingEnabled
        $settings[1] = $verboseLoggingEnabled.ToString()
        Set-Content -Path $settingsFilePath -Value $settings
    }
}

# Function to manually add device to collection
Function Manual-AddDevice {
    $deviceNames = Read-Host "Enter the device names (comma or newline separated)"
    $collectionID = Read-Host "Enter the collection ID"
        
    $deviceNamesArray = $deviceNames -split "[,\r\n]+"
    foreach ($deviceName in $deviceNamesArray) {
        if (-not [string]::IsNullOrWhiteSpace($deviceName) -and $deviceName -like "SW*") {
            Update-CollectionMembership $deviceName $collectionID $true
            Read-Host "Press Enter to continue"
        } elseif (-not [string]::IsNullOrWhiteSpace($deviceName)) {
            Write-Host "Invalid device name format. Device names should start with 'SW'."
            Read-Host "Press Enter to continue"
        }
    }
}

# Function to manually remove device from collection
Function Manual-RemoveDevice {
    $deviceNames = Read-Host "Enter the device names (comma or newline separated)"
    $collectionID = Read-Host "Enter the collection ID"
    $deviceNamesArray = $deviceNames -split "[,\r\n]+"
    foreach ($deviceName in $deviceNamesArray) {
        if (-not [string]::IsNullOrWhiteSpace($deviceName) -and $deviceName -like "SW*") {
            Update-CollectionMembership $deviceName $collectionID $false
            Read-Host "Press Enter to continue"
        } elseif (-not [string]::IsNullOrWhiteSpace($deviceName)) {
            Write-Host "Invalid device name format. Device names should start with 'SW'."
            Read-Host "Press Enter to continue"
        }
    }
}

# Function to trigger processing from files
Function Process-FromFiles {
    # Read devices and collections from files
    $devices = Get-Content -Path $devicesFilePath
    $collections = Get-Content -Path $collectionsFilePath

    foreach ($pc in $devices) {
        foreach ($id in $collections) {
            $collectionName = (Get-CMCollection -CollectionId $id).Name
            Update-CollectionMembership $pc $id $true
        }
    }
    Read-Host "Press Enter to continue"
}

# Function to view logs
Function View-Logs {
    Clear-Host
    Get-Content $logFilePath
    Read-Host "Press Enter to continue"
}

# Main execution begins here
Initialize-SCCM
Setup-Directories

while ($true) {
    $choice = Show-Menu

    switch ($choice) {
        "1" { Manual-AddDevice }
        "2" { Manual-RemoveDevice }
        "3" { Process-FromFiles }
        "4" { View-Logs }
        "5" { Write-Host "Exiting..."; exit }
        "6" { Show-SettingsMenu }
        default { Write-Host "Invalid choice. Please select again."; Read-Host "Press Enter to continue" }
    }
}

Write-Host "Script execution completed."
