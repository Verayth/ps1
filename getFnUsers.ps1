#requires -modules @{ModuleName="BetterCredentials";ModuleVersion="4.5"},FormatPx

Get-Credential freenas\root -Store | Out-Null
$Credentials = Get-Credential freenas\root -GenericCredentials

$format = (
    @{N='uname';E={$_.bsdusr_username};},
    @{N='Name';E={$_.bsdusr_full_name};},
    @{N='UID';E={$_.bsdusr_uid};},
    @{N='Group';E={$_.bsdusr_group};},
    @{N='Email';E={$_.bsdusr_email};},
    @{N='Home';E={$_.bsdusr_home};},
    @{N='Locked';E={$_.bsdusr_locked};},
    @{N='Shell';E={$_.bsdusr_shell};},
    @{N='Sudo';E={$_.bsdusr_sudo};}
)

Invoke-RestMethod -Uri 'http://freenas.local/api/v1.0/account/users/?limit=200' -Method Get -Credential $Credentials | % SyncRoot | Format-Table ($format)
