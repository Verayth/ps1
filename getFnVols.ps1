Import-Module BetterCredentials -ErrorAction Stop

Get-Credential freenas\root -Store | Out-Null
$Credentials = Get-Credential freenas\root -GenericCredentials

Invoke-RestMethod -Uri 'http://freenas.local/api/v1.0/storage/volume/' -Method Get -Credential $Credentials | % SyncRoot
