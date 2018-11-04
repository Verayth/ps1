[CmdletBinding()]
param(
    #the path entry to add
	[parameter(mandatory=$true)] [string[]]$pathAdd,
    #User or Machine
    [string]$type='User',
    # skip Test-Path check
    [switch]$force,
    # re-add
    [switch]$ReAdd,
    # Add to the top of the path
    [switch]$top
)

if ($type -eq 'Machine') {
    if (Test-IsAdmin.ps1) {} else {
        Write-Warning "Must be Administrator to update Machine PATH"
        exit 1
    }
} elseif ($type -ne 'User') {Write-Warning "Invalid PATH Type Specified (User,Machine)";exit 1}

$OrigPath=[System.Environment]::GetEnvironmentVariable('PATH',$type)
$path={$OrigPath -split ';' | ? { $_ -NE ''}}.Invoke()

if ($ReAdd) {
    foreach ($p in $pathAdd) {
        while($path.Remove($p)) {}
    }
}

foreach ($p in $pathAdd) {
    if ($force -or (Test-Path($p))) {
        if ($p -notin $path) {
            if ($top) {
                Write-Verbose "Adding to top: $p"
                $path.Insert(0,$p)
            } else {
                Write-Verbose "Adding: $p"
                $path.Add($p)
            }
        } else {
            Write-Verbose "Already in Path: $p"
        }
    } else {
        Write-Warning "Not Exists: $p"
    }
}

$NewPath=$path -join ';'
if ($NewPath -ne $OrigPath) {
    Write-Verbose "Updating ${type}Path: $NewPath"
    [System.Environment]::SetEnvironmentVariable('PATH',$NewPath,$type)
    $env:Path=[System.Environment]::GetEnvironmentVariable('PATH','Machine')+';'+[System.Environment]::GetEnvironmentVariable('PATH','User')
}
