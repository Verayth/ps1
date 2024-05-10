function Connect-SFConsoleAPI {
    [CmdletBinding()]
    param (
        [string]$Hostname = 'localhost',
        [int]$port = 55555,
        [string]$URL
    )
    if (-not $URL) {
        #WARN: doesn't support IPv6 as of 1.0.3, so force IPv4 IP address for the host
        $IPV4Address = (Test-Connection $hostname -Count 1).IPV4Address
        $URL = "http://${IPV4Address}:$port/console"
    }
    $out=(Invoke-RestMethod -Method POST -Uri $URL -Body "GetSFSEVersion").split("`n") | Where-Object { $_ -notlike "*GetSFSEVersion" }
    $ver=($out[0].split(','))[0].split(':')
    if ($ver[0] -eq 'SFSE version') {
        $Global:SFConsole_API = $URL
        Write-Host "Connected To: $($Global:SFConsole_API)" -ForegroundColor Yellow
    } else {
        $out
        throw "Unable to connect"
    }
}
