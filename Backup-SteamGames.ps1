<#

#>
[CmdletBinding()]param()
Import-Module C:\_SVN\Steam-GetOnTop\Modules\SteamTools -ErrorAction stop

$steamPath=Get-SteamPath
$LibraryFolders = ConvertFrom-VDF (cat "$steamPath\SteamApps\libraryfolders.vdf")
#$config = ConvertFrom-VDF (Get-Content "$steamPath\config\config.vdf")
#$config

[array]$steamLibraries += $steamPath
foreach ($i in 1..9) {
    $a=$LibraryFolders.LibraryFolders.$i
    if ($a) {$steamLibraries+=$a.Replace("\\", "\")}
}

$acf = "$($steamPath)\SteamApps\appmanifest_$($id).acf"
$Games=@()

foreach ($steamLibrary in $steamLibraries) {
    foreach ($acfFile in ls $steamLibrary\SteamApps\appmanifest_*.acf | % FullName) {
        $appManifest=ConvertFrom-VDF (Get-Content $acfFile)
        #$appManifest.AppState
        $InstallDir=$appManifest.AppState.InstallDir.Replace("\\", "\")
        if ($InstallDir -notmatch ':') {
            $InstallDir="$steamLibrary\SteamApps\Common\$InstallDir"
        }
        [array]$Games+=[PSCustomObject]@{
            #Library     =$steamLibrary
            AppID       =$appManifest.AppState.AppID
            Name        =$appManifest.AppState.Name
            InstallDir  =$InstallDir
            LastUpdated =$appManifest.AppState.LastUpdated
            SizeOnDisk  =$appManifest.AppState.SizeOnDisk
            BuildID     =$appManifest.AppState.buildid
        }
        #exit
    }
}
#$Games

#[array]$apps = @()


$executables=@(
    'Dungeons3Bin.exe',
    'CrushCrush.exe',
    'ConanSandbox.exe',
    'Fallout4.exe',
    'Interstellaria.exe',
    'KingdomCome.exe',
    'Kingmaker.exe',
    'NMS.exe',
    'Oblivion.exe',
    'PillarsOfEternityII.exe',
    'Portia.exe',
    'SkyrimSE.exe',
    'TESV.exe',
    't-engine.exe',
    't-engine-debug.exe',
    'Terraria.exe',
    'tld.exe',
    'Tyranny.exe'
)

$Games | ? AppID -in (
    377160, # Fallout 4
    305620, # The Long Dark
    362960, # Tyranny
    440900, # Conan Exiles
    459820, # Crush Crush
    493900, # Dungeons 3
    280360, # Interstellaria
    379430, # Kingdom Come: Deliverance
    275850, # No Man's Sky
    22330 , # The Elder Scrolls IV: Oblivion             
    72850 , # The Elder Scrolls V: Skyrim                
    489830, # The Elder Scrolls V: Skyrim Special Edition
    640820, # Pathfinder: Kingmaker
    666140, # My Time At Portia
    560130, # Pillars of Eternity II: Deadfire
    #219740, # Don't Starve
    259680 # Tales of Maj'Eyal
) | ForEach-Object {
        Write-Host "Checking: $($_.Name)" -ForegroundColor Blue
        #Write-Host $_.InstallDir
        $exe=Get-ChildItem ($_.InstallDir, "$($_.InstallDir)\bin\Win64", "$($_.InstallDir)\ConanSandbox\Binaries\Win64", "$($_.InstallDir)\Binaries") -ErrorAction SilentlyContinue | Where-Object Name -in $executables
        #,'t-engine.exe'
        if ($exe) {
            Write-Verbose "'$($_.InstallDir)'"
            $exe
        } else {
            Write-Host "'$($_.InstallDir)'" -ForegroundColor Red
            Get-ChildItem ($_.InstallDir, "$($_.InstallDir)\bin\Win64", "$($_.InstallDir)\ConanSandbox\Binaries\Win64", "$($_.InstallDir)\Binaries") -ErrorAction SilentlyContinue | Where-Object Name -like '*.exe' |
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
