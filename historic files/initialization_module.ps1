
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
