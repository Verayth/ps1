#requires -modules @{ModuleName="BetterCredentials";ModuleVersion="4.5"},FormatPx

Get-Credential freenas\root -Store | Out-Null
$Credentials = Get-Credential freenas\root -GenericCredentials

$format = (
    @{N='Name';E={$_.name};},
    @{N='Quota';A='right';E={prettySize.ps1($_.quota)};},
    @{N='Used';A='right';E={prettySize.ps1($_.Used)};},
    @{N='Avail';A='right';E={prettySize.ps1($_.avail)};},
    @{N='Capacity';A='right';E={"{0:0}%" -f ($_.Capacity*100)};},
    #@{N='Refer';A='right';E={prettySize.ps1($_.Refer)};},
    @{N='MountPoint';E={$_.MountPoint};}
)

$ds = Invoke-RestMethod -Uri 'http://freenas.local/api/v1.0/storage/dataset/?limit=200' -Method Get -Credential $Credentials | % SyncRoot
$ds | Add-Member -Name Capacity -MemberType ScriptProperty -Value {$this.used / ($this.used + $this.avail)}
$ds | Format-Table ($format)
