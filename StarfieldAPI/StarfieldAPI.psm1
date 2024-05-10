#requires -Version 5.0
#-Modules BetterCredentials,FormatPx,SOS.Common,SOS.SQL

. $PSScriptRoot\Add-SFItems.ps1
. $PSScriptRoot\Connect-SFConsoleAPI.ps1
. $PSScriptRoot\Invoke-SFConsoleAPI.ps1
. $PSScriptRoot\Submit-SFBatch.ps1

if (-not $Global:SFConsole_API) {
    Connect-SFConsoleAPI
}

function Get-SFPlayerAV ($AV) {
    Invoke-ConsoleAPI "player.GetAV $AV"
}
