    Import-Module .\logging_module.ps1
    Import-Module .\menu_module.ps1
    Import-Module .\initialization_module.ps1
    Import-Module .\device_management_module.ps1
    # Import-Module .\mock_initialization_module.ps1
    # Import-Module .\mock_device_management_module.ps1
    
    
    # Configuration Setting
    $UseLiveSCCMConnection = $false  # Set to $true for live SCCM connection, $false for mock mode
    
    # Import Modules
    . "path_to_logging_module.ps1"
    . "path_to_menu_module.ps1"
    . "path_to_initialization_module.ps1"
    . "path_to_device_management_module.ps1"
    
    # SCCM Initialization
    if ($UseLiveSCCMConnection) {
        # Live SCCM Initialization
        Initialize-SCCM
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
} else {
        # Mock Initialization for Testing
        Write-Host "[Mock Initialization] Initialized in mock mode."
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
}
    
    # Main Menu
    do {
        $menuOptions = @(
            "Manual Add Device",
            "Manual Remove Device",
            "Batch Add Devices",
            "Batch Remove Devices",
            "Exit"
        )
        $choice = Show-Menu -Title "SCCM Device Management" -Options $menuOptions
    
        switch ($choice) {
            "1" {
                # Manual Add Device logic
                $deviceName = Read-Host "Enter Device Name"
                $collectionName = Read-Host "Enter Collection Name"
                Manual-AddDevice -DeviceName $deviceName -CollectionName $collectionName
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
        }
            "2" {
                # Manual Remove Device logic
                $deviceName = Read-Host "Enter Device Name"
                $collectionName = Read-Host "Enter Collection Name"
                Manual-RemoveDevice -DeviceName $deviceName -CollectionName $collectionName
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
        }
            "3" {
                # Batch Add Devices logic
                $filePath = Read-Host "Enter Path to File with Device Names"
                $collectionName = Read-Host "Enter Collection Name"
                Batch-AddDevices -FilePath $filePath -CollectionName $collectionName
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
        }
            "4" {
                # Batch Remove Devices logic
                $filePath = Read-Host "Enter Path to File with Device Names"
                $collectionName = Read-Host "Enter Collection Name"
                Batch-RemoveDevices -FilePath $filePath -CollectionName $collectionName
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
        }
            "5" {
                # Exit
                break
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
        }
            default {
                Write-Host "Invalid choice. Please try again."
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
        }
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
    }
    }
    catch {
        Write-Log -Message $_.Exception.Message -Level Error
    }
} while ($true)
    
    
    pause