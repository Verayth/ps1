#requires -modules @{ModuleName="BetterCredentials";ModuleVersion="4.5"},FormatPx

Get-Credential freenas\root -Store | Out-Null
$Credentials = Get-Credential freenas\root -GenericCredentials

$format = (
    @{N='Name';W=25;E={$_.Name};},	#auto-20180918.2000-2w
    @{N='Used';W=10;Align='Right';E={prettySize.ps1($_.Used)};},
    @{N='Refer';W=10;Align='Right';E={prettySize.ps1($_.Refer)};},
    @{N='Filesystem';E={$_.Filesystem};}
)

Invoke-RestMethod -Uri 'http://freenas.local/api/v1.0/storage/snapshot/?limit=2000' -Method Get -Credential $Credentials | % SyncRoot | Format-Table ($format)
