
Function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp [$Level] $Message"
}

Function Write-ProcessedItem {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Item,
        
        [Parameter(Mandatory=$true)]
        [string]$Action
    )
    Write-Log -Message "Processed $Item for $Action" -Level "INFO"
}
