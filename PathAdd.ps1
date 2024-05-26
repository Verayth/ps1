[CmdletBinding()]
param(
    #the path entries to add, or $null to refresh from system
    [string[]]$pathAdd,
    #User or Machine
    [string]$type='User',
    #
    [string]$PathVariable='PATH',
    # skip Test-Path check
    [switch]$force,
    # re-add
    [switch]$ReAdd,
    # Add to the top of the path
    [switch]$top
)

if ($type -notin 'Local','User','Machine') {throw "Invalid PATH Type Specified (Local,User,Machine)"}

if ($type -eq 'Local') {
    $OrigPath=(Get-ChildItem Env:$PathVariable -ErrorAction SilentlyContinue).Value
} else {
    $OrigPath=[System.Environment]::GetEnvironmentVariable($PathVariable,$type)
}
$path={$OrigPath -split ';' | Where-Object { $_ -NE ''} | ForEach-Object {$_.TrimEnd('\')}}.Invoke()

$pathAdd=$pathAdd | ForEach-Object {$_.TrimEnd('\')}
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
    Write-Verbose "Updating ${type}-${PathVariable}: $NewPath"
    if ($type -eq 'Local') {
        Set-Item -Path Env:$PathVariable -Value $NewPath
    } else {
        [System.Environment]::SetEnvironmentVariable($PathVariable,$NewPath,$type)
    }
}
if ($type -ne 'Local') {
    #env:PATH= machine takes precedence
    if ($PathVariable -eq 'PATH') {
        Set-Item -Path Env:$PathVariable -Value (
            [System.Environment]::GetEnvironmentVariable($PathVariable,'Machine')+';'+
            [System.Environment]::GetEnvironmentVariable($PathVariable,'User')
        )
    } else {
        Set-Item -Path Env:$PathVariable -Value (
            [System.Environment]::GetEnvironmentVariable($PathVariable,'User')+';'+
            [System.Environment]::GetEnvironmentVariable($PathVariable,'Machine')
        )
    }
}
