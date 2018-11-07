<#

.NOTES
TODO: consolidate all the XML document creations.  adding them didn't actually solve anything as the problem was unrelated to the XML object.

20181026: initial conversion to PS1 from https://www.nexusmods.com/kingdomcomedeliverance/mods/629
20181027a: added sections: carry500,pebbles,sharpening,gathering,dirt
20181027b: my first working version 1.0
20181027c
	added ability to set cheats
	added NoGreetings and SaveGame everywhere
	change to include only the necessary
	activation fixes
20181030
	fix XML processing
	fixed mod file creation (directory structure problem)
	disable game breaking durability section
20181104: copied from private repo to git
20181106: changed to get $progdir from registry.  added launcher and 64-bit check + relaunch
#>

$header=@"
##################################################################
# Kingdom Come Deliverence - TWEAKs                              #
# by Dugarr - Version 2.04                                       #
# by Verayth - Version 2.04.181106                               #
##################################################################
"@
$ErrorActionPreference='Stop'

if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    #if we are running 32-bit on as 64-bit machine
    Write-Warning "Re-launching in 64-bit mode....."
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
    exit $lastexitcode
}

#this is MUCH faster than using Get-Package
$progdir=(Get-ItemProperty -ErrorAction SilentlyContinue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 379430').InstallLocation
if (!$progdir) {
    $progdir=([xml](Get-Package 'Kingdom Come: Deliverance' -ErrorAction SilentlyContinue | ForEach-Object swidtagtext)).SoftwareIdentity.Meta.InstallLocation
}

if (!$progdir) {Write-Warning "Unable to find KCD Game folder";Start-Sleep 3;exit 1}

$modDir="$progdir\Mods\KCDtweak\script"
$null=mkdir "$modDir" -Force
Set-Location $modDir

function mkModDirs {
    $null=mkdir "$modDir\cache" -Force -ErrorAction SilentlyContinue
    $null=mkdir "$modDir\edit" -Force -ErrorAction SilentlyContinue
}
mkModDirs

#use cached files
#if (Test-Path('cache\*.xml')) {copy cache\*.xml edit -Force}

function reset {
    Clear-Host
    Remove-Item -Recurse cache,edit,orig,ZZZ_Mod -Force -ErrorAction SilentlyContinue
    Remove-Item *.zip,*.pak -Force -ErrorAction SilentlyContinue
    mkModDirs
}
function extract {
    Clear-Host
    reset
    #Remove-Item -Recurse edit -ErrorAction SilentlyContinue
    #$null=mkdir orig -ErrorAction SilentlyContinue
    #$null=mkdir edit -ErrorAction SilentlyContinue
    7z e ..\..\..\Data\tables.pak -o'edit' rpg_param.xml -r
    7z e ..\..\..\Data\tables.pak -o'edit' soul.xml -r
    7z e ..\..\..\Data\tables.pak -o'edit' shop_type2item.xml -r
    7z e ..\..\..\Data\tables.pak -o'edit' random_event.xml -r
    7z e ..\..\..\Data\tables.pak -o'edit' food.xml -r
    7z e ..\..\..\Data\tables.pak -o'edit' armor.xml -r
    7z e ..\..\..\Data\tables.pak -o'edit' weapon.xml -r
    7z e ..\..\..\Data\Scripts.pak -o'edit' arrow.xml -r
    7z e ..\..\..\Data\Scripts.pak -o'edit' TypeDefinitions.xml -r
    #7z e ..\..\..\Data\Scripts.pak -o'edit' sb_switch_hitreactions.xml -r
    7z e ..\..\..\Data\GameData.pak -o'edit' MM_IngameMenu.xml -r
    7z e ..\..\..\Data\GameData.pak -o'edit' MM_SaveGame.xml -r
    Copy-Item -Recurse edit orig
    Remove-Item -Recurse cache -ErrorAction SilentlyContinue
    $null=New-Item -Path "cache" -Name 'extract.on' -Force

    Start-Sleep 2
}
function spoil {
    Clear-Host
    if (Test-Path('cache\spoil.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\food.xml")
        $x.database.table.rows.row | % { if ($_.decay_time_hours -gt 0) {$_.decay_time_hours = "{0}" -f ([int]$_.decay_time_hours / 3)}  }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\item\food.xml -Encoding ASCII
        del 'cache\spoil.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\food.xml")
        $x.database.table.rows.row | % { if ($_.decay_time_hours -gt 0) {$_.decay_time_hours = "{0}" -f ([int]$_.decay_time_hours * 3)}  }
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\item" -Name 'food.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\item\food.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'spoil.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\item\food.xml edit\ -Force
}
function dura {
    Clear-Host
    if (Test-Path('cache\dura.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\armor.xml")
        $x.database.table.rows.row | % { if ($_.slash_def -gt 0) {$_.slash_def = "{0}" -f ([decimal]$_.slash_def / 10)} }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\item\armor.xml -Encoding ASCII

        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\weapon.xml")
        $x.database.table.rows.row | % { $_.max_status = $_.max_status -replace '0$' }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\item\weapon.xml -Encoding ASCII

        del 'cache\dura.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\armor.xml")
        $x.database.table.rows.row | % { if ($_.slash_def -gt 0) {$_.slash_def = "{0}" -f ([decimal]$_.slash_def * 10)} }
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\item" -Name 'armor.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\item\armor.xml -Encoding ASCII

        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\weapon.xml")
        $x.database.table.rows.row | % { $_.max_status = "{0}0" -f $_.max_status }
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\item" -Name 'weapon.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\item\weapon.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'dura.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\item\armor.xml edit\ -Force
    copy ZZZ_Mod\Libs\Tables\item\weapon.xml edit\ -Force
}

function AimSpread {
    Clear-Host
    if (Test-Path('cache\AimSpread.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'AimSpreadMax' | % {$_.rpg_param_value = '15'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\AimSpread.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'AimSpreadMax' | % {$_.rpg_param_value = '0'}
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'AimSpread.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit\ -Force
}
function revent {
    Clear-Host
    if (Test-Path('cache\revent.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\random_event.xml")
        $x.database.table.rows.row | % {
            $_.base_run_chance = $_.base_run_chance -replace '^1'
            if ($_.cooldown -eq '2h') {$_.cooldown = '168h'}
        }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\random_event.xml -Encoding ASCII
        del 'cache\revent.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\random_event.xml")
        $x.database.table.rows.row | % {
            $_.base_run_chance = "1{0}" -f $_.base_run_chance
            if ($_.cooldown -eq '168h') {$_.cooldown = '2h'}
        }
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables" -Name 'random_event.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\random_event.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'revent.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\random_event.xml edit\ -Force
}
function Carry500 {
    Clear-Host
    if (Test-Path('cache\Carry500*.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'BaseInventoryCapacity' | % {$_.rpg_param_value = '66'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\Carry500*.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        if (Test-Path('cache\Cheats.on')) {
            $InventoryCapacity='999999999'
            $null=New-Item -Path "cache" -Name 'Carry500Cheat.on' -Force
        } else {
            $InventoryCapacity='500'
            $null=New-Item -Path "cache" -Name 'Carry500.on' -Force
        }
        $x.database.table.rows.row | ? rpg_param_key -EQ 'BaseInventoryCapacity' | % {$_.rpg_param_value = $InventoryCapacity}
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit\ -Force
}
function pebbles {
    Clear-Host
    if (Test-Path('cache\pebbles.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\soul.xml")
        $x.database.table.rows.row | ? soul_name -eq 'horse_sedivka' | % {
            $_.agi = '5'
            $_.courage = '8'
            $_.str = '5'
            $_.vit = '5'
        }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\soul.xml -Encoding ASCII
        del 'cache\pebbles.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\soul.xml")
        $x.database.table.rows.row | ? soul_name -eq 'horse_sedivka' | % {
            $_.agi = '20'
            $_.courage = '20'
            $_.str = '20'
            $_.vit = '20'
        }
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'soul.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\soul.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'pebbles.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\rpg\soul.xml edit\ -Force
}

function newRpgXmlRow {
	param($v1,$v2)
	$e=$x.CreateElement("row")
	$a1=$x.CreateAttribute('rpg_param_key')
	$a1.Value=$v1
	$a2=$x.CreateAttribute('rpg_param_value')
	$a2.Value=$v2
	$null=$e.Attributes.Append($a1)
	$null=$e.Attributes.Append($a2)
	$e
}

function sharpening {
    #Default: Ideal=0.3-0.5 Destruction=0.6-0.7
    Clear-Host
    if (Test-Path('cache\sharpening*.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $nodes = $x.database.table.rows.row | ? rpg_param_key -Like 'SharpeningM*'
        foreach ($node in $nodes) {$node.ParentNode.RemoveChild($node)}
        $nodes = $x.database.table.row | ? rpg_param_key -Like 'SharpeningM*'
        foreach ($node in $nodes) {$node.ParentNode.RemoveChild($node)}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\sharpening*.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        if (Test-Path('cache\Cheats.on')) {
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMinIdealAngle' '0' ))
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMaxIdealAngle' '0.98'))
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMinDestructionAngle' '0.99'))
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMaxDestructionAngle' '1'))
            $null=New-Item -Path "cache" -Name 'sharpeningCheat.on' -Force
        } else {
            #OK for Executioner quest?
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMinIdealAngle' '0.1' ))
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMaxIdealAngle' '0.8'))
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMinDestructionAngle' '0.9'))
            $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'SharpeningMaxDestructionAngle' '1'))
            $null=New-Item -Path "cache" -Name 'sharpening.on' -Force
        }
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit -Force
}
function gathering {
    Clear-Host
    if (Test-Path('cache\gathering.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'HerbGatherSkillToRadius' | % {$_.rpg_param_value = '0.25'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\gathering.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'HerbGatherSkillToRadius' | % {$_.rpg_param_value = '1.25'}
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'gathering.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit\ -Force
}
function dirt {
    Clear-Host
    if (Test-Path('cache\dirt.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $nodes = $x.database.table.rows.row | ? rpg_param_key -EQ 'FullClothDirtyingOnFullSpeed'
        foreach ($node in $nodes) {$node.ParentNode.RemoveChild($node)}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\dirt.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        #$x = New-Object xml
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.LastChild.ParentNode.AppendChild((newRpgXmlRow 'FullClothDirtyingOnFullSpeed' '11500' ))
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'dirt.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit -Force
}
function 2xp {
    Clear-Host
    if (Test-Path('cache\2xp*.on')) {
        $multiplier=1
        del 'cache\2xp*.on'
    } elseif (Test-Path('cache\Cheats.on')) {
        $multiplier=5
        $null=New-Item -Path "cache" -Name '2xpCheat.on' -Force
    } else {
        $multiplier=2
        $null=New-Item -Path "cache" -Name '2xp.on' -Force
    }
    $x = New-Object System.Xml.XmlDocument
    $x.PreserveWhitespace = $true
    $x.Load("$pwd\edit\rpg_param.xml")
    $x.database.table.rows.row | ? rpg_param_key -EQ 'AlchemyXPPerSuccessfullBrewing'   | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 40)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'HorseRidingXPPerDistance'         | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 12.5)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'HunterXPKill'                     | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 15)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'LockPickingStealthXP'             | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 8)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'LockPickingSuccessXPMulCoef'      | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 18)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'NonSkillBookXP'                   | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 30)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'PickpocketingFailXPMod'           | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 0.3)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'PickpocketingStealthXP'           | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 12)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'PickpocketingXP'                  | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 15)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'ReadingXpPerHour'                 | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 20)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SecondaryStatXPRatio'             | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 0.5)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPBlock'                     | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 2)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPComboHit'                  | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 4)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPHit'                       | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 2)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPKill'                      | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 12)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPPerfectBlock'              | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 8)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPRiposte'                   | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 8)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillXPUseRepairKit'              | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 5)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPComboHit'                   | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 4)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPHit'                        | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 2)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPKill'                       | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 8)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPSpeechPerSequence'          | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 1)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPVitalityPerDistance'        | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 8)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPVitalityPerJump'            | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 0.5)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPVitalityPerKill'            | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 15)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StatXPVitalityPerVault'           | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 0.7)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StealthAttackFailXp'              | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 10)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StealthAttackMaxXp'               | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 50)}
    $x.database.table.rows.row | ? rpg_param_key -EQ 'StealthAttackMinXp'               | % {$_.rpg_param_value = '{0}' -f  ($multiplier * 25)}
    $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
    $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit\ -Force
}

$Merchant_Amounts = @'
2,1800
4,200
5,100
8,20000
9,2000
10,4000
14,200
15,1500
16,20000
17,1500
19,3000
20,50
22,100
24,400
25,250
26,2500
28,10000
29,2000
30,500
32,2000
36,1000
37,2000
38,15000
40,400
41,10000
42,1000
43,2000
44,200
45,800
46,200
47,4000
48,1500
49,2000
50,2000
51,2000
52,10000
53,10000
54,800
55,2000
56,2000
57,2000
58,1000
59,1000
60,10000
61,1500
62,4000
63,4000
64,6000
65,3500
66,20000
67,15000
68,2000
69,10000
70,1000
71,200
72,1500
73,1500
74,1500
75,1500
76,1500
77,1500
78,2000
79,4000
81,20000
82,20000
83,6000
84,8000
85,8000
87,3000
88,1500
89,1500
90,5000
'@ | ConvertFrom-Csv -Header shop_type_id,amount

function rich {
    Clear-Host
    if (Test-Path('cache\rich.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\shop_type2item.xml")
        $x.database.table.rows.row | ? item_id -EQ '5ef63059-322e-4e1b-abe8-926e100c770e' | % {
            $oldamt=$Merchant_Amounts | ? shop_type_id -EQ $_.shop_type_id | % {if ($_.amount) {"{0}" -f $_.amount}}
            if ($oldamt) {$_.amount=$oldamt}
        }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\shop\shop_type2item.xml -Encoding ASCII
        del 'cache\rich.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\shop_type2item.xml")
        $x.database.table.rows.row | ? item_id -EQ '5ef63059-322e-4e1b-abe8-926e100c770e' | % {$_.amount='50000'}
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\shop" -Name 'shop_type2item.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\shop\shop_type2item.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'rich.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\shop\shop_type2item.xml edit -Force
}
function stamcost {
    Clear-Host
    if (Test-Path('cache\stamcost.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'AimStamCost' | % {$_.rpg_param_value = '20'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'BaseAttackStaminaCost' | % {$_.rpg_param_value = '12'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillToDmgConstA' | % {$_.rpg_param_value = '250'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'SprintCost' | % {$_.rpg_param_value = '3.5'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamDamage' | % {$_.rpg_param_value = '8'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\stamcost.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'AimStamCost' | % {$_.rpg_param_value = '10'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'BaseAttackStaminaCost' | % {$_.rpg_param_value = '6'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'SkillToDmgConstA' | % {$_.rpg_param_value = '100'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'SprintCost' | % {$_.rpg_param_value = '1.5'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamDamage' | % {$_.rpg_param_value = '4'}
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'stamcost.on' -Force
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit\ -Force
}
function stamreg {
    Clear-Host
    if (Test-Path('cache\stamreg*.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamRegenBase' | % {$_.rpg_param_value = '22'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamRegenBlockMod' | % {$_.rpg_param_value = '0.6'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamRegenCooldown' | % {$_.rpg_param_value = '1.5'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
        del 'cache\stamreg*.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\rpg_param.xml")
        if (Test-Path('cache\Cheats.on')) {
            $StamRegenBase='44'
            $null=New-Item -Path "cache" -Name 'stamregCheat.on' -Force
        } else {
            $StamRegenBase='30'
            $null=New-Item -Path "cache" -Name 'stamreg.on' -Force
        }
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamRegenBase' | % {$_.rpg_param_value = $StamRegenBase}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamRegenBlockMod' | % {$_.rpg_param_value = '0.5'}
        $x.database.table.rows.row | ? rpg_param_key -EQ 'StamRegenCooldown' | % {$_.rpg_param_value = '0.5'}
        $null=New-Item -Path "ZZZ_Mod\Libs\Tables\rpg" -Name 'rpg_param.tbl' -Force
        $x.OuterXml | Out-File ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml -Encoding ASCII
    }
    copy ZZZ_Mod\Libs\Tables\rpg\rpg_param.xml edit\ -Force
}

function arrowf {
    Clear-Host
    if (Test-Path('cache\arrowf.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\arrow.xml")
        $x.Ammo.physics.param | ? Name -EQ 'gravity' | % {$_.value='0, 0, -9.0'}
        $x.OuterXml | Out-File ZZZ_Mod\Scripts\Entities\Items\XML\Ammo\arrow.xml -Encoding ASCII -Force
        del 'cache\arrowf.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\arrow.xml")
        $x.Ammo.physics.param | ? Name -EQ 'gravity' | % {$_.value='0, 0, -3.0'}
        $null=mkdir "ZZZ_Mod\Scripts\Entities\Items\XML\Ammo" -Force -ErrorAction SilentlyContinue
        $x.OuterXml | Out-File ZZZ_Mod\Scripts\Entities\Items\XML\Ammo\arrow.xml -Encoding ASCII -Force
        $null=New-Item -Path "cache" -Name 'arrowf.on' -Force
    }
    copy ZZZ_Mod\Scripts\Entities\Items\XML\Ammo\arrow.xml edit\ -Force
}
function arrows {
    Clear-Host
    if (Test-Path('cache\arrows.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\arrow.xml")
        $x.Ammo.physics.param | ? Name -EQ 'thrust' | % {$_.value='0'}
        $x.OuterXml | Out-File ZZZ_Mod\Scripts\Entities\Items\XML\Ammo\arrow.xml -Encoding ASCII
        del 'cache\arrows.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\arrow.xml")
        $x.Ammo.physics.param | ? Name -EQ 'thrust' | % {$_.value='300'}
        $null=mkdir "ZZZ_Mod\Scripts\Entities\Items\XML\Ammo" -Force -ErrorAction SilentlyContinue
        $x.OuterXml | Out-File ZZZ_Mod\Scripts\Entities\Items\XML\Ammo\arrow.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'arrows.on' -Force
    }
    copy ZZZ_Mod\Scripts\Entities\Items\XML\Ammo\arrow.xml edit\ -Force
}
function greeting {
    Clear-Host
    if (Test-Path('cache\greeting.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\TypeDefinitions.xml")
        $x.TypeDefinitions.Type | ? Name -EQ 'distanceMove_params' | % member | ? name -EQ 'useGreeting' | % { $_.'#text' = 'true' }
        $x.TypeDefinitions.Type | ? Name -EQ 'dudeProx' | % Type | ? Name -eq 'params' | % member | ? name -In 'suppressGreet','suppressStealth' | % { $_.'#text' = 'false' }
        $x.TypeDefinitions.Type | ? Name -EQ 'dialog' | % Type | ? Name -eq 'parameters' | % Type | ? Name -eq 'initiator' | % member | ? name -In 'enableGreeting' | % { $_.'#text' = 'true' }
        $x.OuterXml | Out-File ZZZ_Mod\Libs\AI\TypeDefinitions.xml -Encoding ASCII
        Remove-Item ZZZ_Mod\Libs\AI\final\sb_switch_hitreactions.xml -ErrorAction SilentlyContinue
        del 'cache\greeting.on'
    } else {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\TypeDefinitions.xml")
        $x.TypeDefinitions.Type | ? Name -EQ 'distanceMove_params' | % member | ? name -EQ 'useGreeting' | % { $_.'#text' = 'false' }
        $x.TypeDefinitions.Type | ? Name -EQ 'dudeProx' | % Type | ? Name -eq params | % member | ? name -In 'suppressGreet','suppressStealth' | % { $_.'#text' = 'true' }
        $x.TypeDefinitions.Type | ? Name -EQ 'dialog' | % Type | ? Name -eq 'parameters' | % Type | ? Name -eq 'initiator' | % member | ? name -In 'enableGreeting' | % { $_.'#text' = 'false' }
        $null=mkdir "ZZZ_Mod\Libs\AI\final" -Force -ErrorAction SilentlyContinue
        $x.OuterXml | Out-File ZZZ_Mod\Libs\AI\TypeDefinitions.xml -Encoding ASCII
        Copy-Item ModGreetings\sb_switch_hitreactions.xml ZZZ_Mod\Libs\AI\final\sb_switch_hitreactions.xml -Force
        $null=New-Item -Path "cache" -Name 'greeting.on' -Force
    }
    copy ZZZ_Mod\Libs\AI\TypeDefinitions.xml edit\ -Force
}
function gamsav {
    Clear-Host
    if (Test-Path('cache\gamsav.on')) {
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\MM_IngameMenu.xml")
        $x.Graph.Nodes.Node | ? Id -EQ '583' | % {$_.Inputs.IsExitSave = '0'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\UI\UIActions\MM_IngameMenu.xml -Encoding ASCII
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\MM_SaveGame.xml")
        $x.Graph.Nodes.Node | ? Id -IN '895','896' | % {$_.Inputs.UsePotion = '1'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\UI\UIActions\MM_SaveGame.xml -Encoding ASCII
        del 'cache\gamsav.on'
    } else {
        $null=mkdir ZZZ_Mod\Libs\UI\UIActions -Force
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\MM_IngameMenu.xml")
        $x.Graph.Nodes.Node | ? Id -EQ '583' | % {$_.Inputs.IsExitSave = '1'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\UI\UIActions\MM_IngameMenu.xml -Encoding ASCII
        $x = New-Object System.Xml.XmlDocument
        $x.PreserveWhitespace = $true
        $x.Load("$pwd\edit\MM_SaveGame.xml")
        $x.Graph.Nodes.Node | ? Id -IN '895','896' | % {$_.Inputs.UsePotion = '0'}
        $x.OuterXml | Out-File ZZZ_Mod\Libs\UI\UIActions\MM_SaveGame.xml -Encoding ASCII
        $null=New-Item -Path "cache" -Name 'gamsav.on' -Force
    }
    copy ZZZ_Mod\Libs\UI\UIActions\MM_IngameMenu.xml edit -Force
}

function cheats {
    Clear-Host
    if (Test-Path('cache\cheats.on')) {
        del 'cache\cheats.on'
    } else {
        $null=New-Item -Path "cache" -Name 'cheats.on' -Force
    }
}
function create {
    Clear-Host
    Remove-Item *.zip -ErrorAction SilentlyContinue
    Set-Location ZZZ_Mod
    7z a ..\KCDtweak.zip *
    Set-Location ..
    Move-Item KCDtweak.zip ..\Data\KCDtweak.pak -Force
}

$menu=(
    [PSCustomObject]@{F=''                      ;O='0';E='extract'  ;A='XML-Files are already present';I='extract XML-Files only for 1st install or after game-patch'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='1';E='AimSpread';A='';I='disable left/right AimSpread for Bows'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='2';E='Carry500' ;A='';I="Increased carry capacity"},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='3';E='2xp'      ;A='';I='2x XP'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='4';E='sharpening';A='';I='easy Sharpening'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='5';E='gathering';A='';I='5x gathering radius'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='6';E='dirt'     ;A='';I='get dirty slower'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='7';E='stamcost' ;A='';I='half stamina cost'},
    [PSCustomObject]@{F='rpg_param.xml'         ;O='8';E='stamreg'  ;A='';I='double stamina regen'},
    [PSCustomObject]@{F='soul.xml'              ;O='9';E='pebbles'  ;A='';I='make Pebbles the best Horse'},
    [PSCustomObject]@{F='arrow.xml'             ;O='10';E='arrowf'  ;A='';I='make Arrows faster'},
    [PSCustomObject]@{F='arrow.xml'             ;O='11';E='arrows'  ;A='';I='make Arrows stronger'},
    [PSCustomObject]@{F='shop_type2item.xml'    ;O='12';E='rich'    ;A='';I='Merchants have 5k groschen'},
    [PSCustomObject]@{F='random_event.xml'      ;O='13';E='revent'  ;A='';I='more frequently random Event'},
    [PSCustomObject]@{F='food.xml'              ;O='14';E='spoil'   ;A='';I='food spoils 3x slower'},
    #[PSCustomObject]@{F='armor.xml weapon.xml'  ;O='15';E='dura'    ;A='';I='[BROKEN] 10x Armor and Weapon durability'},
    [PSCustomObject]@{F='TypeDefinitions.xml'   ;O='16';E='greeting';A='';I='NPC NoComplaints NoGreetings'},
    [PSCustomObject]@{F='MM_IngameMenu MM_SaveGame';O='17';E='gamsav';A='';I='Save Game Anywhere with no potion use'},
    [PSCustomObject]@{F='Actions'               ;O='99';E='cheats'  ;A='[Enabled] Cheats';I='Enable Cheat Mode'},
    [PSCustomObject]@{F=''                      ;O='X' ;E='reset'   ;A='';I='reset mod (if you encounter errors or want to start over)'},
    [PSCustomObject]@{F=''                      ;O='Y' ;E='create'  ;A='';I='create Mod'},
    [PSCustomObject]@{F=''                      ;O='Z' ;E=''        ;A='';I='end'}
    )

$resp=''
while ($resp -ne 'z') {
    if (Test-Path('edit\*.xml')) {$color='Green'} else {$color='Red'}
    Clear-Host
    Write-Host -ForegroundColor $color $header
    foreach ($m in $menu) {
        if ($m.F -and $prevF -ne $m.F){
            $prevF=$m.F
            Write-Host -ForegroundColor $color ("{0} {1}" -f (''.PadLeft(19,'#')),("$($m.F) ".PadRight(46,'#')) )
        }
        if (Test-Path("cache\$($m.E).on")) {
            if ($m.A) {$txt=$m.A} else {$txt="[Activated] {0}" -f $m.I}
        } elseif (Test-Path("cache\$($m.E)Cheat.on")) {
            if ($m.A) {$txt=$m.A} else {$txt="[ActiveCheat] {0}" -f $m.I}
        } else {$txt=$m.I}
        Write-Host -ForegroundColor $color ("{0}  -  {1}" -f $m.O,$txt)
    }
    [string]$resp=Read-Host -Prompt "`r`nEnter a number"
    $m=$menu | ? O -eq $resp
    if ($m.E) {& $m.E}
}
