function Invoke-SFConsoleAPI ($Command) {
    if (-not $Global:SFConsole_API) {Connect-SFConsoleAPI}

    $out=(Invoke-RestMethod -Method POST -Uri $Global:SFConsole_API -Body $Command).split("`n") | Where-Object { $_ -and $_ -notlike "*$Command" }
    if ($out.count -eq 1) {
        $s=$out.split()
        if ($s[2] -eq '>>' -and $s[0] -notlike '*HasKey*') {
            [PSCustomObject]@{
                Type = $s[0]
                $s[1] = $s[3]
            }
        } else {$s}
    } else {$out}
}
