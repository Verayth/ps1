#requires -modules @{ModuleName="BetterCredentials";ModuleVersion="4.5"},FormatPx

[CmdletBinding()]
param (
    [string[]]$fields
)

Get-Credential freenas\root -Store | Out-Null
$Credentials = Get-Credential freenas\root -GenericCredentials

$format = (
    @{N='Name';E={$_.name};},
    @{N='Path';E={$_.path};},
    @{N='Status';E={$_.status};},
    @{N='Used';A='right';E={prettySize.ps1($_.Used)};},
    @{N='Avail';A='right';E={prettySize.ps1($_.avail)};},
    @{N='Used_Pct';A='right';E={$_.used_pct};}
    #@{N='MountPoint';E={$_.MountPoint};}
)

getFnVols.ps1 | % children | % children | ? { -not $_.children } | Format-Table ($format)
