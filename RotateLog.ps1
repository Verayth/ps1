param (
    [string]$filePath,
    [int]$threshold=10,
    [switch]$Force
)
$prog=$PSCommandPath.split('\')[-1]

$path=Split-Path -Path $filePath -Parent
$fn=(Split-Path -Path $filePath -Leaf).Split(".")[0];
$sfx=(Split-Path -Path $filePath -Leaf).Split(".")[1];

$file=Get-Item $filePath -ErrorAction silentlyContinue
if (!$file) {
    Write-Warning "${prog}: Nothing to Rotate"
    exit 0
}

$null=cmp $filePath "$path\$fn-01.$sfx" 2>&1
if ($LASTEXITCODE -eq 0 -and -not $Force) {
    Write-Warning "${prog}: duplicate of previous file, removing"
    Remove-Item "$path\$fn.$sfx" -ErrorAction silentlyContinue -Verbose
    exit 0
}
#$target = Get-ChildItem $log -Filter "${filename}*${extension}"
if (Test-Path("$path/$fn-01.$sfx")) {
    Remove-Item "$path/$fn-${threshold}.$sfx" -ErrorAction silentlyContinue -Verbose
    $threshold..2 | % {
        $num1='{0:d2}' -f ($_-1)
        $num2='{0:d2}' -f $_
        "Try: $fn-${num1}.$sfx"
        if (Test-Path("$path/$fn-${num1}.$sfx")) {
            Rename-Item "$path/$fn-${num1}.$sfx"  "$fn-${num2}.$sfx" -ErrorAction stop -Verbose
        }
    }
}
Rename-Item $filePath "$fn-01.$sfx" -ErrorAction stop -Verbose

$global:LASTEXITCODE=0
