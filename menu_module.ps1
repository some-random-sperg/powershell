
Function Show-Menu {
    Param (
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Options
    )
    Clear-Host
    Write-Host "================ $Title =================="
    for ($i=0; $i -lt $Options.Length; $i++) {
        Write-Host "$($i+1). $($Options[$i])"
    }
    Write-Host "`nEnter choice or 'q' to quit:"
    $input = Read-Host
    return $input
}
