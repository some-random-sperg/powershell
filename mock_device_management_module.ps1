
Function Manual-AddDevice {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceName,
        
        [Parameter(Mandatory=$true)]
        [string]$CollectionName
    )
    Write-Host "[Mock Add-CMDeviceCollectionDirectMembershipRule] Adding $DeviceName to $CollectionName"
}

Function Manual-RemoveDevice {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceName,
        
        [Parameter(Mandatory=$true)]
        [string]$CollectionName
    )
    Write-Host "[Mock Remove-CMDirectMembershipRule] Removing $DeviceName from $CollectionName"
}
