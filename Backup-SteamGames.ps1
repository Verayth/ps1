
Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App*\',
                 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App*\' |
    Where-Object {
        $_.DisplayName -EQ 'Fallout 4' -or
        $_.DisplayName -like '*Skyrim Special Edition' -or
        $_.DisplayName -like '*Oblivion*'
    } | ForEach-Object {
        Write-Host "Checking: $($_.DisplayName)" -ForegroundColor Blue
        #$_.InstallLocation
        Get-ChildItem $_.InstallLocation | Where-Object Name -in 'Fallout4.exe','SkyrimSE.exe','Oblivion.exe'
    } | ForEach-Object {
        $dir=$_.DirectoryName
        $ver=$_.VersionInfo.FileVersion
        $backup=$_.BaseName+'-'+$ver+$_.Extension
        if (Test-Path("$dir\$backup")) {} else {
            Write-Host "Backing Up: $($_.name) v$ver" -ForegroundColor Magenta
            Copy-Item $_.FullName "$dir\$backup"
        }
    }
