[CmdletBinding()]
param(
    #the path entry to remove
	[parameter(mandatory=$true)] [string[]]$PathToRemove,
    #User or Machine
    [string]$type='User',
    #clean the path of obsolete entries
    [switch]$clean
)

if ($type -eq 'Machine') {
    if (Test-IsAdmin.ps1) {} else {
        Write-Warning "Must be Administrator to update Machine PATH"
        exit 1
    }
} elseif ($type -ne 'User') {Write-Warning "Invalid PATH Type Specified (User,Machine)";exit 1}

$OrigPath=[System.Environment]::GetEnvironmentVariable('PATH',$type)
$path={$OrigPath -split ';' | ? { $_ -NE ''}}.Invoke()

foreach ($p in $PathToRemove) {
    while($path.Remove($p)) {}
}

if ($clean) {
    foreach ($p in ($path | % {$_} ) ) {
        if (-not (Test-Path($p))) {
            Write-Verbose "Removing Obsolete Path: $p"
            while($path.Remove($p)) {}
        }
    }
}

$NewPath=$path -join ';'

if ($NewPath -ne $OrigPath) {
    Write-Verbose "Updating ${type}Path: $NewPath"
    [System.Environment]::SetEnvironmentVariable('PATH',$NewPath,$type)
    $env:Path=[System.Environment]::GetEnvironmentVariable('PATH','Machine')+';'+[System.Environment]::GetEnvironmentVariable('PATH','User')
} else {
    Write-Verbose "PathRm, Nothing to do"
}
