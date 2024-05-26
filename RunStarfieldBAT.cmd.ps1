<# :
    @echo off
    powershell /nologo /noprofile /command ^
        "&{[ScriptBlock]::Create((cat """%~f0""") -join [Char[]]10).Invoke(@(&{$args}"""%*"""))}"
    exit /b
#>
param (
    [Parameter(Position=0,mandatory=$true)][string]$BatFileName,
    [string]$Hostname = 'localhost',
    [int]$port = 55555
)

Function pause ($message="Press Enter to exit...")
{
    <#Write-Host "${message}:" -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")#>
    $null=Read-Host $message
}
function Connect-SFConsoleAPI {
    param (
        [string]$Hostname = 'localhost',
        [int]$port = 55555
    )
    #WARN: API doesn't support IPv6 as of 1.0.3, so force IPv4 IP address for the host
    $IPV4Address = (Test-Connection $hostname -Count 1).IPV4Address
    $URL = "http://${IPV4Address}:$port/console"
    $out=try{(Invoke-RestMethod -Method POST -Uri $URL -Body "GetSFSEVersion").split("`n") | Where-Object { $_ -notlike "*GetSFSEVersion" }} catch {}
    if ($out) {$ver=($out[0].split(','))[0].split(':')}
    if ($ver -and $ver[0] -eq 'SFSE version') {
        $Global:SFConsole_API = $URL
        Write-Host "Connected To: $($Global:SFConsole_API)" -ForegroundColor Yellow
    } else {
        $out
        Throw "Unable to connect"
    }
}

function Invoke-SFConsoleAPI ($Command) {
    if (-not $Global:SFConsole_API) {Connect-SFConsoleAPI}
    $out=(Invoke-RestMethod -Method POST -Uri $Global:SFConsole_API -Body $Command).split("`n") | Where-Object { $_ -and $_ -notlike "*$Command" }
    $out
    <#if ($out.count -eq 1) {
        $s=$out.split()
        if ($s[2] -eq '>>' -and $s[0] -notlike '*HasKey*') {
            [PSCustomObject]@{
                Type = $s[0]
                $s[1] = $s[3]
            }
        } else {$out}
    } else {$out}#>
}

function Submit-SFBatch ($BatchFile) {
    if (-not $Global:SFConsole_API) {Connect-SFConsoleAPI}

    Get-Content $BatchFile  | ForEach-Object {
        if ( $_ -like ';*') {
            # Write out the comments
            Write-Host $_ -ForegroundColor Magenta
        } elseif ($_) {
            $commentIndex=$_.IndexOf(';')
            $comment=$null
            if ($commentIndex -ge 0) {
                $command = $_.Substring(0,$commentIndex)
                $comment = $_.Substring($commentIndex)
            } else {
                $command = $_
            }
            Write-Host $command -NoNewline -ForegroundColor Yellow
            Write-Host $comment -ForegroundColor Magenta
            <##>
            Invoke-SFConsoleAPI $command  | Where-Object {
                $_ -notlike 'HasKeyword: ResourceType*' -and
                $_ -notlike 'WornHasKeyword*0.00'
            }
            <##>
        }
    }
}

if (-not $BatFileName) {
    $BatFileName = Read-Host "Enter BAT FileName"
}

if (-not (Test-Path($BatFileName))) {
    Write-Host -ForegroundColor Red "BAT Script File Not Found: $BatFileName"
    pause
    exit 1
}

try{Connect-SFConsoleAPI $Hostname $port} catch {
    Write-Host -ForegroundColor Red "Unable to connect to the Starfield Console API Mod."
    Write-Host @"

Please make sure you have it installed correctly, the "bAlwaysActive" setting is
enabled in your StarfieldCustom.ini file and that the game is running. See the mod page For details:

"@ 
    Write-Host "https://www.nexusmods.com/starfield/mods/4280" -ForegroundColor Blue
    pause
    exit 1
}

Write-Host BAT, $BatFileName -ForeGround Green

Submit-SFBatch $BatFileName | Out-Host

pause 
