#requires -modules @{ModuleName="BetterCredentials";ModuleVersion="4.5"},FormatPx

Get-Credential freenas\root -Store | Out-Null
$Credentials = Get-Credential freenas\root -GenericCredentials

$format = (
    @{N='Filesystem';E={$_.Filesystem};},
    @{N='Name';E={$_.Name};},
    @{N='Used';E={prettySize.ps1($_.Used)};},
    @{N='Refer';E={prettySize.ps1($_.Refer)};}
)

Invoke-RestMethod -Uri 'http://freenas.local/api/v1.0/jails/mountpoints/?limit=200' -Method Get -Credential $Credentials
# | % SyncRoot
# | Format-Table ($format)
