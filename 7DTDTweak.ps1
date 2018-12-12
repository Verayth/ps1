<#
.SYNOPSIS
7 Days to Die XML file Modding Tool
.DESCRIPTION
This is a program for applying Tweaks to the XML files for the game 7 Days to Die.  This is as close to "modding" as you can get with games that only allow XML edits.
.NOTES
20181118: started project
20181123: first working version with successful in-game testing (OPTools,OPArmor,Buffs)
20181124: 1.0
20181124a: added Corpses Last Longer
20181125: added ZNerf, NoDogs
20181126: Alpha 17 fixes
20181211: added check for game folder if running alongside it
#>
[CmdletBinding()]param(
    #The 7DTD Program Directory.  use this parm if the registry query fails.
    [string]$progdir
)

$header=@"
##################################################################
# 7 Days to Die - XML Modding Tool                               #
# by Verayth/rob - Version 1.1.181211                            #
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

if ($progdir) {
    if (Test-Path("$progdir\7DaysToDie.exe")) {} else {
        Write-Warning "Invalid parameter value for 7DTD Program Directory: $progdir"
        exit 1
    }
} else {
    $progdir=(Get-ItemProperty -ErrorAction SilentlyContinue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 251570').InstallLocation
    if (-not $progdir) {
        #Loop through parent directories looking for the game
        $path = $pwd
        while($path -and !(Test-Path (Join-Path $path '7DaysToDie.exe'))){
            $path = Split-Path $path -Parent
        }
        $progdir=$path
    }
    if ($progdir) {Write-Verbose "PROGDIR: $progdir"} else {Write-Warning "Unable to find Game Install folder";Start-Sleep 3;exit 1}
}

#####################################
# The Tweaks

#$FileVersion = "$progdir\7DaysToDie.exe" | % VersionInfo | % FileVersion

$menu=@{}

$BuffsFile="$progdir\Data\Config\buffs.xml"
$BuffsXml = New-Object System.Xml.XmlDocument
$BuffsXml.PreserveWhitespace = $true
$BuffsXml.Load($BuffsFile)

$entityclassesFile="$progdir\Data\Config\entityclasses.xml"
$entityclassesXml = New-Object System.Xml.XmlDocument
$entityclassesXml.PreserveWhitespace = $true
$entityclassesXml.Load($entityclassesFile)

$entitygroupsFile="$progdir\Data\Config\entitygroups.xml"
$entitygroupsXml = New-Object System.Xml.XmlDocument
$entitygroupsXml.PreserveWhitespace = $true
$entitygroupsXml.Load($entitygroupsFile)

$ItemsFile="$progdir\Data\Config\items.xml"
$ItemsXml = New-Object System.Xml.XmlDocument
$ItemsXml.PreserveWhitespace = $true
$ItemsXml.Load($ItemsFile)

$LootXml = New-Object System.Xml.XmlDocument
$LootXml.PreserveWhitespace = $true
$LootXml.Load("$progdir\Data\Config\loot.xml")

function itemEdit {
    param(
        [string]$Modded,
        [string]$itemPath,
        [string]$propertyPath,
        $changeStat
    )
    #"Setting Modded: $Modded, Item: $itemPath  $propertyPath"
    foreach ($c in $changeStat) {
        $attribPath="[@name='$($c.N)']"
        if ($c.T) {$attribPath+="[@tags='$($c.T)']"}
        $ItemsXml.items.SelectNodes($itemPath) | % { $_.SelectNodes($propertyPath+$attribPath) } | ForEach-Object {
            if ($_.value) {
                if (-not $_.Modded) {
                    $_.SetAttribute('OrigValue', $_.value)
                }
                if ($Modded -eq 'true') {
                    #Modded Value
                    $_.value = [string]$c.M
                } elseif ($Modded -eq 'cheat') {
                    #Cheat Value
                    $_.value = [string]$c.C
                } else {
                    #$_.value = [string]$c.D
                    #Modded=False: Reset to the Original Value
                    $_.value = $_.OrigValue
                }
                $_.SetAttribute('Modded', $Modded)
            }
            #$_
        }
    }
    #exit
}

function expandedUI {
    # Player craft storage containers
    if ($patch) {$val='14,10'} else {$val='8,9'}
    $LootXml.lootcontainers.lootcontainer | ? ID -eq 10 | % {$_.Size = $val}
    # minibike storage
    if ($patch) {$val='9,11'} else {$val='3,6'}
    $LootXml.lootcontainers.lootcontainer | ? ID -eq 62 | % {$_.Size = $val}
    #$LootXml.Save()

    <#
    $xml.Load("$progdir\Data\Config\xui.xml")
    #$xml.xui.ruleset.window_group | ? Name -EQ 'crafting' | % Window | ? Name -like '*windowCraftingQueue' | % {$_.Name = 'S420windowCraftingQueue'}
    $xml.xui.ruleset.window_group.window | ? Name -in 'windowCraftingQueue','windowOutput','windowLooting','windowCompass','windowToolbelt','HUDLeftStatBars' | % { $_.Name = 'S420'+$_.Name}
    $xml.xui.ruleset.window_group.window | ? Name -eq 'windowQuestTracker' | % { $_.Name = 'S420XpBar';$_.anchor='CenterBottom'}
    $xml.xui.ruleset.window_group.window | ? Name -like 'windowVehicle*' | % { $_.Name = 'S420'+$_.Name}
    $xml.xui.ruleset.window_group.window | ? Name -like 'S420*'
    #>
}

function OPArmor {
    $Enabled='true'
    if ($menu['OPArmor']) {
        $Enabled=$menu['OPArmor'].Enabled
        if ($Enabled -in 'true','cheat') {
            $Enabled = 'false'
        } elseif ($menu['cheats'].Enabled -eq 'true') {
            $Enabled = 'cheat'
        } else {
            $Enabled = 'true'
        }
        $menu['OPArmor'].Enabled=$Enabled
    }
    $ItemsXml.Items.SelectNodes("item[@name='plantFiberPants']").SetAttribute('Modded', $Enabled)

    #Alpha 17
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberPants']|item[@name='plantFiberShirt']|item[@name='plantFiberHood']" -propertyPath "effect_group/passive_effect" -changeStat (
        [PSCustomObject]@{N='ModSlots'          ;D=1 ;M=2;C=5},
        [PSCustomObject]@{N='HypothermalResist' ;D=2 ;M=5;C=15},
        [PSCustomObject]@{N='HyperthermalResist';D=2 ;M=5;C=15}
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberShoes']|item[@name='plantFiberGloves']" -propertyPath "effect_group/passive_effect" -changeStat (
        [PSCustomObject]@{N='ModSlots'          ;D=1 ;M=2;C=5},
        [PSCustomObject]@{N='HypothermalResist' ;D=1 ;M=4;C=10},
        [PSCustomObject]@{N='HyperthermalResist';D=1 ;M=4;C=10}
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberHat']" -propertyPath "effect_group/passive_effect" -changeStat (
        [PSCustomObject]@{N='ModSlots'          ;D=1 ;M=2;C=5},
        [PSCustomObject]@{N='HypothermalResist' ;D=1 ;M=5;C=10},
        [PSCustomObject]@{N='HyperthermalResist';D=7 ;M=10;C=20}
    )

    #Alpha 16.4
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberPants']" -propertyPath "property"  -changeStat (
        [PSCustomObject]@{N='Insulation';D=2;M=3;C=3} # not too high as easy to overheat
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberPants']" -propertyPath "property[@class='Attributes']/property"  -changeStat (
        [PSCustomObject]@{N='ConcussiveProtection'  ;D='0.065,0.11' ;M='0.1,0.2'    ;C='0.5,0.8'},
        [PSCustomObject]@{N='PunctureProtection'    ;D='0.065,0.11' ;M='0.1,0.2'    ;C='0.5,0.8'},
        [PSCustomObject]@{N='FireProtection'        ;D='0.12,0.2'   ;M='0.1,0.2'    ;C='0.5,0.8'},
        [PSCustomObject]@{N='RadiationProtection'   ;D='0.06,0.1'   ;M='0.1,0.2'    ;C='0.5,0.8'},
        [PSCustomObject]@{N='ElectricalProtection'  ;D='0.06,0.1'   ;M='0.1,0.2'    ;C='0.5,0.8'},
        [PSCustomObject]@{N='DegradationMax'        ;D='72,140'     ;M='100,200'   ;C='500,1500'}
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberHat']" -propertyPath "property"  -changeStat (
        [PSCustomObject]@{N='Waterproof';D=0.05;M=0.2;C=0.8}
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='plantFiberHood']" -propertyPath "property"  -changeStat (
        [PSCustomObject]@{N='Waterproof';D=0.05;M=0.2;C=0.8}
    )

    #exit
    $ItemsXml.OuterXml | Out-File $ItemsFile -Encoding ASCII
}
#OPArmor

function OPTools {
    #$ItemsXml.items.SelectNodes("item[@name='meleeToolStoneAxe']/effect_group[@name='Base Effects']/passive_effect[@name='DamageModifier'][@tags='earth']")
    $Enabled='false'
    if ($menu['OPTools']) {
        $Enabled=$menu['OPTools'].Enabled
        if ($Enabled -in 'true','cheat') {
            $Enabled = 'false'
        } elseif ($menu['cheats'].Enabled -eq 'true') {
            $Enabled = 'cheat'
        } else {
            $Enabled = 'true'
        }
        $menu['OPTools'].Enabled=$Enabled
    }
    $ItemsXml.items.SelectNodes("item[@name='stoneAxe']|item[@name='meleeToolStoneAxe']").SetAttribute('Modded', $Enabled)

    #Alpha17
    itemEdit -Modded $Enabled -itemPath "item[@name='meleeHandPlayer']" -propertyPath "effect_group[@name='Base Effects']/passive_effect"  -changeStat (
        [PSCustomObject]@{N='EntityDamage'      ;D=7  ;M=20 ;C=100},
        [PSCustomObject]@{N='BlockDamage'       ;D=2  ;M=5  ;C=10},
        [PSCustomObject]@{N='AttacksPerMinute'  ;D=80 ;M=100;C=150},
        [PSCustomObject]@{N='StaminaLoss'       ;D=8  ;M=2  ;C=1},
        [PSCustomObject]@{N='MaxRange'          ;D=2.0;M=2.5;C=5.0},
        [PSCustomObject]@{N='BlockRange'        ;D=2.6;M=4.0;C=6.0},
        [PSCustomObject]@{N='HarvestCount'      ;D=0  ;M=2  ;C=5}
    )

    itemEdit -Modded $Enabled -itemPath "item[@name='meleeToolStoneAxe']" -propertyPath "effect_group[@name='Base Effects']/passive_effect" -changeStat (
        [PSCustomObject]@{N='MaxRange'          ;D=2.4;M=4;C=6},
        [PSCustomObject]@{N='BlockRange'        ;D=3;M=4;C=6},
        [PSCustomObject]@{N='EntityDamage'      ;D=11;M=22;C=100},
        [PSCustomObject]@{N='BlockDamage'       ;D=26;M=60;C=200},
        [PSCustomObject]@{N='AttacksPerMinute'  ;D=75;M=100;C=150},
        [PSCustomObject]@{N='HarvestCount'      ;D=.35;M=.5;C=1},
        [PSCustomObject]@{N='DamageModifier'    ;T='stone';D=-.3;M=-.2;C=1},
        [PSCustomObject]@{N='DamageModifier'    ;T='earth';D=-.8;M=-.4;C=1},
        [PSCustomObject]@{N='DamageModifier'    ;T='metal';D=-.5;M=-.3;C=1},
        [PSCustomObject]@{N='StaminaLoss'       ;D=14;M=7;C=3},
        [PSCustomObject]@{N='DegradationMax'    ;D='70,200';M='100,300';C='500,1000'}
        #[PSCustomObject]@{N='ModSlots'          ;D='0,5';M='0,5';C='0,5'},
        #[PSCustomObject]@{N='ModPowerBonus'     ;T='EntityDamage,BlockDamage';D=.15;M=.15;C=.15}
    )

    #Alpha 16.4
    #$ItemsXml.Items.SelectNodes("*[@name='handPlayer']/property[@class='Action0']/property") | % { $_.Name
    itemEdit -Modded $Enabled -itemPath "item[@name='handPlayer']" -propertyPath "property[@class='Action0']/property"  -changeStat (
        [PSCustomObject]@{N='Range'             ;D=2.5;M=3 ;C=10},
        [PSCustomObject]@{N='DamageEntity'      ;D=5  ;M=30;C=100},
        [PSCustomObject]@{N='DamageBlock'       ;D=1  ;M=5 ;C=10},
        [PSCustomObject]@{N='Stamina_usage'     ;D=3  ;M=2 ;C=1},
        [PSCustomObject]@{N='DamageBonus.head'  ;D=2  ;M=3 ;C=5}
    )

    itemEdit -Modded $Enabled -itemPath "item[@name='stoneAxe']" -propertyPath "property[@class='Action0']/property"  -changeStat (
        [PSCustomObject]@{N='Range'                         ;D=2.1   ;M=3 ;C=5},
        [PSCustomObject]@{N='Block_range'                   ;D=3     ;M=5 ;C=5},
        [PSCustomObject]@{N='Stamina_usage'                 ;D=3.5   ;M=2 ;C=1},
        [PSCustomObject]@{N='DamageBonus.head'              ;D=5     ;M=5 ;C=5},
        [PSCustomObject]@{N='DamageBonus.glass'             ;D=0.42  ;M=.5;C=1},
        [PSCustomObject]@{N='DamageBonus.wood'              ;D=1     ;M=1 ;C=1},
        [PSCustomObject]@{N='DamageBonus.earth'             ;D=0.2083;M=.4;C=1},
        [PSCustomObject]@{N='DamageBonus.stone'             ;D=0.625 ;M=.8;C=1},
        [PSCustomObject]@{N='DamageBonus.metal'             ;D=0.4167;M=.6;C=1},
        [PSCustomObject]@{N='DamageBonus.organic'           ;D=0.8334;M=1 ;C=1},
        [PSCustomObject]@{N='ToolCategory.harvestingTools'  ;D=0.7   ;M=1.0;C=1.5}
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='stoneAxe']|item[@name='meleeToolStoneAxe']" -propertyPath "property[@class='Action1']/property"  -changeStat (
        [PSCustomObject]@{N='Delay';D=1;M=.75;C=.2},
        [PSCustomObject]@{N='Repair_amount';D=100;M=200;C=500}
    )
    itemEdit -Modded $Enabled -itemPath "item[@name='stoneAxe']" -propertyPath "property[@class='Attributes']/property"  -changeStat (
        [PSCustomObject]@{N='EntityDamage'      ;D='4,10'   ;M='8,20'   ;C='150,200'},
        [PSCustomObject]@{N='BlockDamage'       ;D='22.8,30';M='40,60'  ;C='150,200'},
        [PSCustomObject]@{N='DegradationMax'    ;D='100,600';M='200,900';C='500,2000'},
        [PSCustomObject]@{N='DegradationRate'   ;D='1,1'    ;M='1,1'    ;C='1,1'}
    )
    $ItemsXml.OuterXml | Out-File $ItemsFile -Encoding ASCII
}

function ZNerf {
    #$null=$ItemsXml.Items.SelectNodes("*[@name='handZombie']/property[@class='Action0']/property[@name='DamageBlock']")
    $modifier = .5
    if ($menu['ZNerf'].Enabled -in 'true','cheat') {
        $menu['ZNerf'].Enabled = 'false'
        $modifier = 1
    } elseif ($menu['cheats'].Enabled -eq 'true') {
        $menu['ZNerf'].Enabled = 'cheat'
        $modifier = .1
    } else {
        $menu['ZNerf'].Enabled = 'true'
        $modifier = .5
    }
    $ItemsXml.Items.Item | Where-Object { $_.Name -like 'handAnimal*' -or $_.Name -like '*Zombie*' } |
        ForEach-Object {
            $name=$_.Name
            $_.SelectNodes("
                property[@class='Action0']/property[@name='DamageBlock'] |
                property[@class='Action1']/property[@name='DamageBlock'] |
                effect_group/passive_effect[@name='BlockDamage']")
        } | ForEach-Object {
            $_.SetAttribute('Modded', $menu['ZNerf'].Enabled)
            if (-not $_.OrigValue) {$_.SetAttribute('OrigValue', $_.value)}
            $_.value = [string]([int]([int]$_.OrigValue * $modifier))
            #Write-Warning "Name: $name"
            #$_
        }
    $ItemsXml.OuterXml | Out-File $ItemsFile -Encoding ASCII
}

function Buffs {
    #bluePillBuff Removed in Alpha 17
    if ($menu['Buffs'].Enabled -in 'true','cheat') {
        $menu['Buffs'].Enabled = 'false'
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']").SetAttribute('Modded', 'false')
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']/modify") | % {
            $inp=$_
            switch($_.Name) {
                #Not sure if these are actually the original values as file was modified manually prior to the tweak script
                'food'      {$inp.amount = '1';$inp.rate='100'}
                'water'     {$inp.amount = '1';$inp.rate='100'}
                'health'    {$inp.amount = '1';$inp.rate='1'}
                "wellness"  {$inp.amount = '800';$inp.rate='1';$inp.duration='1'} 
            }
        }
    } elseif ($menu['cheats'].Enabled -eq 'true') {
        $menu['Buffs'].Enabled = 'cheat'
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']").SetAttribute('Modded', 'cheat')
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']/modify") | % {
            $inp=$_
            switch($_.Name) {
                'food'      {$inp.amount = '1';$inp.rate='1'}
                'water'     {$inp.amount = '1';$inp.rate='1'}
                'health'    {$inp.amount = '10';$inp.rate='0.5'}
                "wellness"  {$inp.amount = '800';$inp.rate='1';$inp.duration='1'}
            }
        }
    } else {
        $menu['Buffs'].Enabled = 'true'
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']").SetAttribute('Modded', 'true')
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']/modify") | % {
            $inp=$_
            switch($_.Name) {
                'food'      {$inp.amount = '1';$inp.rate='10'}
                'water'     {$inp.amount = '1';$inp.rate='10'}
                'health'    {$inp.amount = '1';$inp.rate='1'}
                "wellness"  {$inp.amount = '800';$inp.rate='1';$inp.duration='1'}
            }
        }
    }
    #$ItemsXml.Save($ItemsFile)
    $BuffsXml.OuterXml | Out-File $BuffsFile -Encoding ASCII
}

function CorpsesLL {
    $AfterDeath = @{
        #These are the ORIGINAL values
        Backpack                = 1200
        DroppedLootContainer    = 60
        zombieTemplateMale      = 30
        npcSurvivorTemplate     = 45
        animalTemplateTimid     = 300
        animalStag              = 300
        animalTemplateHostile   = 300 
        npcBanditMelee          = 45
        npcTraderTemplate       = 45
        #OLD Pre 16.4 items
        zombie01                = 30
        zombieBear              = 30
        zombiedog               = 30
        animalBear              = 300
        hornet                  = 300
    }
    if ($menu['CorpsesLL'].Enabled -in 'true','cheat') {
        $menu['CorpsesLL'].Enabled = 'false'
        $multiplier=1
    } elseif ($menu['cheats'].Enabled -eq 'true') {
        $menu['CorpsesLL'].Enabled = 'cheat'
        $multiplier=200
    } else {
        $menu['CorpsesLL'].Enabled = 'true'
        $multiplier=20
    }
    #$entityclassesXml.entity_classes.SelectNodes("*[@name='Backpack']").SetAttribute('Modded', $menu['CorpsesLL'].Enabled)
    $entityclassesXml.entity_classes.entity_class | % {
        if ($AfterDeath[$_.Name]) {
            #$_.Name
            $AfterDeathNode=$_.SelectNodes("*[@name='TimeStayAfterDeath']")
            #$AfterDeathNode
            if ($AfterDeathNode.value) {
                #$AfterDeathNode.value = [string]($AfterDeath[$_.Name] * $multiplier)
                #$_.SelectNodes("*[@name='TimeStayAfterDeath']").value = [string]($AfterDeath[$_.Name] * $multiplier)
                $AfterDeathNode.SetAttribute('value', [string]($AfterDeath[$_.Name] * $multiplier))
                #$_.SetAttribute('Modded', $menu['CorpsesLL'].Enabled)
                $AfterDeathNode.SetAttribute('Modded', $menu['CorpsesLL'].Enabled)
            }
        }
    }
    $entityclassesXml.OuterXml | Out-File $entityclassesFile -Encoding ASCII
    #pause
}

function NoDogs {
    $NoDogs=(
        'zombieFatCop',
        'zombieSpider',
        'animalZombieDog'
    )
    if ($menu['NoDogs'].Enabled -in 'true','cheat') {
        $menu['NoDogs'].Enabled = 'false'
        $dogChance='1'
        $multiplier=1
    } elseif ($menu['cheats'].Enabled -eq 'true') {
        $menu['NoDogs'].Enabled = 'cheat'
        $dogChance='0.01'
        $multiplier=0.01
    } else {
        $menu['NoDogs'].Enabled = 'true'
        $dogChance='0.10'
        $multiplier=0.1
    }
    #$entitygroupsXml.SelectNodes("/entitygroups/entitygroup/entity[@name='animalZombieDog']") | select -first 1
    $entitygroupsXml.SelectNodes("/entitygroups/entitygroup/entity") | ? Name -in $NoDogs |
        ForEach-Object {
            if (-not $_.Modded -and $_.prob) {$_.SetAttribute('OrigProb', $_.prob)}
            if ($_.OrigProb) {
                $_.SetAttribute('prob', [string]([decimal]$_.OrigProb * $multiplier))
            } else {
                $_.SetAttribute('prob', $dogChance)
            }
            $_.SetAttribute('Modded', $menu['NoDogs'].Enabled)
            #Write-Warning "Name: $name"
        }
    $entitygroupsXml.OuterXml | Out-File $entitygroupsFile -Encoding ASCII
}


#############################################
# The Menu

$menu=[ordered]@{
    #create      = [PSCustomObject]@{F=''                    ;Opt='0' ;A='XML-Archive already exists';I='extract XML-Files only for 1st install or after game-patch'}
    OPTools     = [PSCustomObject]@{F='items.xml'           ;Opt='1' ;A='';I='OP Starting Tools (hand,stoneAxe)'}
    OPArmor     = [PSCustomObject]@{F='items.xml'           ;Opt='2' ;A='';I="OP Starting Armor (plant)"}
    ZNerf       = [PSCustomObject]@{F='items.xml'           ;Opt='3' ;A='';I="Nerf Zombie block damage"}
    Buffs       = [PSCustomObject]@{F='buffs.xml'           ;Opt='4' ;A='';I="buff bluePillBuff: Food,Water,Health"}
    CorpsesLL   = [PSCustomObject]@{F='entityclasses.xml'   ;Opt='5' ;A='';I="Corpses Last Longer"}
    NoDogs      = [PSCustomObject]@{F='entitygroups.xml'    ;Opt='6' ;A='';I="Fewer Dogs,Cops,Spiders"}
    cheats      = [PSCustomObject]@{F='Actions'             ;Opt='99';A='[Enabled] Cheats';I='Enable Cheat Mode'}
    #reset       = [PSCustomObject]@{F=''                    ;Opt='X' ;A='';I='reset (if you encounter errors or want to start over)'}
    exit        = [PSCustomObject]@{F=''                    ;Opt='Z' ;A='';I='end'}
}

#Add Name and Enabled columns to the menu items
$menu | % Keys | % { $menu[$_] | Add-Member Name $_ -PassThru | Add-Member Enabled 'false' }
$menu['exit'].Name=''

#$menu['OPTools'].Enabled=$ItemsXml.Items.SelectNodes("*[@name='handPlayer']").Modded
$menu['OPTools'].Enabled=$ItemsXml.items.SelectNodes("item[@name='stoneAxe']|item[@name='meleeToolStoneAxe']").Modded
$menu['OPArmor'].Enabled=$ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']").Modded
$menu['ZNerf'].Enabled=$ItemsXml.Items.SelectNodes("*[@name='handZombie']|*[@name='meleeHandZombieCop']") | % { $_.SelectNodes("property[@class='Action0']/property[@name='DamageBlock']") } | select -first 1 | % Modded
$menu['Buffs'].Enabled=$BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']").Modded
$menu['CorpsesLL'].Enabled=$entityclassesXml.entity_classes.SelectNodes("*[@name='Backpack']").SelectNodes("*[@name='TimeStayAfterDeath']").Modded
$menu['NoDogs'].Enabled=$entitygroupsXml.SelectNodes("/entitygroups/entitygroup/entity[@name='animalZombieDog']") | select -first 1 | % Modded

#exit

function cheats {
    if ($menu['cheats'].Enabled -eq 'true') {
        $menu['cheats'].Enabled = 'false'
    } else {
        $menu['cheats'].Enabled = 'true'
    }
}

$resp=''
while ($resp -ne 'z') {
    #if (Test-Path('edit\*.xml')) {$color='Green'} else {$color='Red'}
    $color='Green'
    Clear-Host
    Write-Host -ForegroundColor $color $header
    foreach ($m in $menu.Values) {
        if ($m.F -and $prevF -ne $m.F){
            $prevF=$m.F
            Write-Host -ForegroundColor $color ("{0} {1}" -f (''.PadLeft(19,'#')),("$($m.F) ".PadRight(46,'#')) )
        }
        if ($m.Enabled -eq 'true') {
            if ($m.A) {$txt=$m.A} else {$txt="[Activated] {0}" -f $m.I}
        } elseif ($m.Enabled -eq 'cheat') {
            if ($m.A) {$txt=$m.A} else {$txt="[ActiveCheat] {0}" -f $m.I}
        } else {$txt=$m.I}
        Write-Host -ForegroundColor $color ("{0}  -  {1}" -f $m.Opt,$txt)
    }
    [string]$resp=Read-Host -Prompt "`r`nEnter a number"
    $m=$menu.Values | ? Opt -eq $resp
    if ($m.Name) {& $m.Name}
}
