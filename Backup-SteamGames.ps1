
[CmdletBinding()]param()

Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App*\',
                 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App*\' |
    Where-Object {
        $_.DisplayName -in 'Fallout 4','The Long Dark','Tyranny' -or
        $_.DisplayName -like '*Skyrim Special Edition' -or
        $_.DisplayName -like 'Crush Crush' -or
        $_.DisplayName -like 'Interstellaria' -or
        $_.DisplayName -like '*eternity*' -or
        #$_.DisplayName -like '*Starve*' -or
        $_.DisplayName -like "Tales of Maj'Eyal" -or
        $_.DisplayName -like 'Conan Exiles' -or
        $_.DisplayName -like '*Oblivion*'
    } | ForEach-Object {
        Write-Host "Checking: $($_.DisplayName)" -ForegroundColor Blue
        #Write-Host $_.InstallLocation
        $exe=Get-ChildItem $_.InstallLocation | Where-Object Name -in 'Fallout4.exe','SkyrimSE.exe','Oblivion.exe','PillarsOfEternityII.exe',
            'tld.exe','Tyranny.exe','CrushCrush.exe','ConanSandbox.exe','Interstellaria.exe','t-engine.exe','t-engine-debug.exe'
        #,'t-engine.exe'
        if ($exe) {$exe} else {
            Write-Host "'$($_.InstallLocation)'" -ForegroundColor Red
            Get-ChildItem $_.InstallLocation | Where-Object Name -like '*.exe' |
                Select-Object Name,
                    @{N='FileVersion';E={$_.VersionInfo.FileVersion}},
                    @{N='Created';E={'{0:yyyy-MM-dd}' -f $_.CreationTime}},
                    @{N='LastWrite';E={'{0:yyyy-MM-dd}' -f $_.LastWriteTime}} |
                Format-Table -AutoSize | Out-Default
        }
    } | ForEach-Object {
        $dir=$_.DirectoryName
        $ver=$_.VersionInfo.FileVersion
        if (-not $ver) {$ver='0.0'}

        $backup=$_.BaseName+'-'+$ver+$_.Extension
        $bkpfile=Get-ChildItem "$dir\$backup" -ErrorAction SilentlyContinue
        if ($bkpfile) {
            $filedate="{0:yyyyMMdd}" -f $_.LastWriteTime
            if ($bkpfile.LastWriteTime -eq $_.LastWriteTime) {
                Write-Verbose ("$filedate {1} v$ver" -f $_.LastWriteTime,$_.Name)
            } else {
                $backup=$_.BaseName+'-'+$ver+'-'+$filedate+$_.Extension
                $bkpfile=Get-ChildItem "$dir\$backup" -ErrorAction SilentlyContinue
                if ($bkpfile) {
                    Write-Verbose ("$filedate {1} v$ver" -f $_.LastWriteTime,$_.Name)
                } else {
                    Write-Host "Backing Up: $filedate $($_.name) v$ver" -ForegroundColor Magenta
                    Copy-Item $_.FullName "$dir\$backup"
                }
            }
        } else {
            Write-Host "Backing Up: $($_.name) v$ver" -ForegroundColor Magenta
            Copy-Item $_.FullName "$dir\$backup"
        }
    }
