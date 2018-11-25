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
#>
[CmdletBinding()]param(
    #The 7DTD Program Directory.  use this parm if the registry query fails.
    [string]$progdir
)

$header=@"
##################################################################
# 7 Days to Die - XML Modding Tool                               #
# by Verayth - Version 1.1.181124a                               #
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
    if ($progdir) {Write-Verbose "PROGDIR: $progdir"} else {Write-Warning "Unable to find Game Install folder";Start-Sleep 3;exit 1}
}

#####################################
# The Tweaks

#$FileVersion = "$progdir\7DaysToDie.exe" | % VersionInfo | % FileVersion

$BuffsFile="$progdir\Data\Config\buffs.xml"
$BuffsXml = New-Object System.Xml.XmlDocument
$BuffsXml.PreserveWhitespace = $true
$BuffsXml.Load($BuffsFile)

$entityclassesFile="$progdir\Data\Config\entityclasses.xml"
$entityclassesXml = New-Object System.Xml.XmlDocument
$entityclassesXml.PreserveWhitespace = $true
$entityclassesXml.Load($entityclassesFile)

$ItemsFile="$progdir\Data\Config\items.xml"
$ItemsXml = New-Object System.Xml.XmlDocument
$ItemsXml.PreserveWhitespace = $true
$ItemsXml.Load($ItemsFile)

$LootXml = New-Object System.Xml.XmlDocument
$LootXml.PreserveWhitespace = $true
$LootXml.Load("$progdir\Data\Config\loot.xml")

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
    if ($menu['OPArmor'].Enabled -in 'true','cheat') {
        $menu['OPArmor'].Enabled = 'false'
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']").SetAttribute('Modded', 'false')
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Insulation"    {$inp.Value = "2" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']/property[@class='Attributes']/property") | % {
            $inp=$_
            switch($_.Name) {
                "ConcussiveProtection"  {$inp.Value = "0.065,0.11" }
                "PunctureProtection"    {$inp.Value = "0.065,0.11" }
                "FireProtection"        {$inp.Value = "0.12,0.2" }
                "RadiationProtection"   {$inp.Value = "0.06,0.1" }
                "ElectricalProtection"  {$inp.Value = "0.06,0.1" }
                "DegradationMax"        {$inp.Value = "72,140" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberHat']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Waterproof"    {$inp.Value = "0.05" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberHood']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Waterproof"    {$inp.Value = "0.05" }
            }
        }
    } elseif ($menu['cheats'].Enabled -eq 'true') {
        $menu['OPArmor'].Enabled = 'cheat'
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']").SetAttribute('Modded', 'cheat')
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Insulation"    {$inp.Value = "3" } # not too high as easy to overheat
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']/property[@class='Attributes']/property") | % {
            $inp=$_
            switch($_.Name) {
                "ConcussiveProtection"  {$inp.Value = "0.5,0.8" }
                "PunctureProtection"    {$inp.Value = "0.5,0.8" }
                "FireProtection"        {$inp.Value = "0.5,0.8" }
                "RadiationProtection"   {$inp.Value = "0.5,0.8" }
                "ElectricalProtection"  {$inp.Value = "0.5,0.8" }
                "DegradationMax"        {$inp.Value = "500,1500" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberHat']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Waterproof"    {$inp.Value = "0.8" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberHood']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Waterproof"    {$inp.Value = "0.8" }
            }
        }
    } else {
        $menu['OPArmor'].Enabled = 'true'
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']").SetAttribute('Modded', 'true')
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Insulation"    {$inp.Value = "3" } # not too high as easy to overheat
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']/property[@class='Attributes']/property") | % {
            $inp=$_
            switch($_.Name) {
                "ConcussiveProtection"  {$inp.Value = "0.1,0.2" }
                "PunctureProtection"    {$inp.Value = "0.1,0.2" }
                "FireProtection"        {$inp.Value = "0.1,0.2" }
                "RadiationProtection"   {$inp.Value = "0.1,0.2" }
                "ElectricalProtection"  {$inp.Value = "0.1,0.2" }
                "DegradationMax"        {$inp.Value = "100,200" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberHat']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Waterproof"    {$inp.Value = "0.2" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='plantFiberHood']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Waterproof"    {$inp.Value = "0.2" }
            }
        }
    }
    #$ItemsXml.Save($ItemsFile)
    $ItemsXml.OuterXml | Out-File $ItemsFile -Encoding ASCII
}

function OPTools {
    if ($menu['OPTools'].Enabled -in 'true','cheat') {
        $menu['OPTools'].Enabled = 'false'
        $ItemsXml.Items.SelectNodes("*[@name='handPlayer']").SetAttribute('Modded', 'false')
        $ItemsXml.Items.SelectNodes("*[@name='handPlayer']/property[@class='Action0']/property") | % {
            $inp=$_
            switch($_.Name) {
                'Range'             {$inp.Value = '2.5'}
                'DamageEntity'      {$inp.Value = '5'}
                'DamageBlock'       {$inp.Value = '1'}
                "Stamina_usage"     {$inp.Value = "3" }
                'DamageBonus.head'  {$inp.Value = '2'}
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Action0']/property") | % {
            $inp=$_
            switch($_.Name) {
                'Range'                 {$inp.Value = '2.1'}
                'Block_range'           {$inp.Value = '3'}
                'Stamina_usage'         {$inp.Value = '3.5'}
                'DamageBonus.head'      {$inp.Value = '5'}
                'DamageBonus.glass'     {$inp.Value = '0.42'}
                'DamageBonus.wood'      {$inp.Value = '1'}
                'DamageBonus.earth'     {$inp.Value = '0.2083'}
                'DamageBonus.stone'     {$inp.Value = '0.625'}
                'DamageBonus.metal'     {$inp.Value = '0.4167'}
                'DamageBonus.organic'   {$inp.Value = '0.8334'}
                'ToolCategory.harvestingTools'  {$inp.Value = '0.7'}
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Action1']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Repair_amount"     {$inp.Value = "100" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Attributes']/property") | % {
            $inp=$_
            switch($_.Name) {
                'EntityDamage'      {$inp.Value = '4,10'}
                'BlockDamage'       {$inp.Value = '22.8,30'}
                'DegradationMax'    {$inp.Value = '100,600'}
                'DegradationRate'   {$inp.Value = '1,1'}
            }
        }
    } elseif ($menu['cheats'].Enabled -eq 'true') {
        $menu['OPTools'].Enabled = 'cheat'
        $ItemsXml.Items.SelectNodes("*[@name='handPlayer']").SetAttribute('Modded', 'cheat')
        $ItemsXml.Items.SelectNodes("*[@name='handPlayer']/property[@class='Action0']/property") | % {
            $inp=$_
            switch($_.Name) {
                'Range'                 {$inp.Value = '10'}
                'DamageEntity'          {$inp.Value = '100'}
                'DamageBlock'           {$inp.Value = '10'}
                "Stamina_usage"         {$inp.Value = "1" }
                'DamageBonus.head'      {$inp.Value = '5'}
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Action0']/property") | % {
            $inp=$_
            switch($_.Name) {
                'Range'                 {$inp.Value = '5'}
                'Block_range'           {$inp.Value = '5'}
                'Stamina_usage'         {$inp.Value = '1'}
                'DamageBonus.head'      {$inp.Value = '5'}
                'DamageBonus.glass'     {$inp.Value = '1'}
                'DamageBonus.wood'      {$inp.Value = '1'}
                'DamageBonus.earth'     {$inp.Value = '1'}
                'DamageBonus.stone'     {$inp.Value = '1'}
                'DamageBonus.metal'     {$inp.Value = '1'}
                'DamageBonus.organic'   {$inp.Value = '1'}
                'ToolCategory.harvestingTools'  {$inp.Value = '1.5'}
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Action1']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Repair_amount"     {$inp.Value = "500" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Attributes']/property") | % {
            $inp=$_
            switch($_.Name) {
                'EntityDamage'      {$inp.Value = '150,200'}
                'BlockDamage'       {$inp.Value = '150,200'}
                'DegradationMax'    {$inp.Value = '500,2000'}
                'DegradationRate'   {$inp.Value = '1,1'}
            }
        }
    } else {
        $menu['OPTools'].Enabled = 'true'
        $ItemsXml.Items.SelectNodes("*[@name='handPlayer']").SetAttribute('Modded', 'true')
        $ItemsXml.Items.SelectNodes("*[@name='handPlayer']/property[@class='Action0']/property") | % {
            $inp=$_
            switch($_.Name) {
                'Range'                 {$inp.Value = '3'}
                'DamageEntity'          {$inp.Value = '100'}
                'DamageBlock'           {$inp.Value = '10'}
                "Stamina_usage"         {$inp.Value = "1" }
                'DamageBonus.head'      {$inp.Value = '5'}
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Action0']/property") | % {
            $inp=$_
            switch($_.Name) {
                'Range'                 {$inp.Value = '3'}
                'Block_range'           {$inp.Value = '5'}
                'Stamina_usage'         {$inp.Value = '2'}
                'DamageBonus.head'      {$inp.Value = '5'}
                'DamageBonus.glass'     {$inp.Value = '0.5'}
                'DamageBonus.wood'      {$inp.Value = '1'}
                'DamageBonus.earth'     {$inp.Value = '0.4'}
                'DamageBonus.stone'     {$inp.Value = '0.8'}
                'DamageBonus.metal'     {$inp.Value = '0.6'}
                'DamageBonus.organic'   {$inp.Value = '1'}
                'ToolCategory.harvestingTools'  {$inp.Value = '1.0'}
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Action1']/property") | % {
            $inp=$_
            switch($_.Name) {
                "Repair_amount"     {$inp.Value = "200" }
            }
        }
        $ItemsXml.Items.SelectNodes("*[@name='stoneAxe']/property[@class='Attributes']/property") | % {
            $inp=$_
            switch($_.Name) {
                'EntityDamage'      {$inp.Value = '8,20'}
                'BlockDamage'       {$inp.Value = '40,60'}
                'DegradationMax'    {$inp.Value = '200,900'}
                'DegradationRate'   {$inp.Value = '1,1'}
            }
        }
    }
    #$ItemsXml.Save($ItemsFile)
    $ItemsXml.OuterXml | Out-File $ItemsFile -Encoding ASCII
}

function ZNerf {
    $null=$ItemsXml.Items.SelectNodes("*[@name='handZombie']/property[@class='Action0']/property[@name='DamageBlock']")
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
                property[@class='Action1']/property[@name='DamageBlock']")
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
    if ($menu['Buffs'].Enabled -in 'true','cheat') {
        $menu['Buffs'].Enabled = 'false'
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']").SetAttribute('Modded', 'false')
        $BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']/modify") | % {
            $inp=$_
            switch($_.Name) {
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

#############################################
# The Menu

$menu=[ordered]@{
    #create      = [PSCustomObject]@{F=''                    ;Opt='0' ;A='XML-Archive already exists';I='extract XML-Files only for 1st install or after game-patch'}
    OPTools     = [PSCustomObject]@{F='items.xml'           ;Opt='1' ;A='';I='OP Starting Tools (hand,stoneAxe)'}
    OPArmor     = [PSCustomObject]@{F='items.xml'           ;Opt='2' ;A='';I="OP Starting Armor (plant)"}
    ZNerf       = [PSCustomObject]@{F='items.xml'           ;Opt='3' ;A='';I="Nerf Zombie block damage"}
    Buffs       = [PSCustomObject]@{F='buffs.xml'           ;Opt='4' ;A='';I="buff bluePillBuff: Food,Water,Health"}
    CorpsesLL   = [PSCustomObject]@{F='entityclasses.xml'   ;Opt='5' ;A='';I="Corpses Last Longer"}
    cheats      = [PSCustomObject]@{F='Actions'             ;Opt='99';A='[Enabled] Cheats';I='Enable Cheat Mode'}
    #reset       = [PSCustomObject]@{F=''                    ;Opt='X' ;A='';I='reset (if you encounter errors or want to start over)'}
    exit        = [PSCustomObject]@{F=''                    ;Opt='Z' ;A='';I='end'}
}

#Add Name and Enabled columns to the menu items
$menu | % Keys | % { $menu[$_] | Add-Member Name $_ -PassThru | Add-Member Enabled 'false' }
$menu['exit'].Name=''

$menu['OPTools'].Enabled=$ItemsXml.Items.SelectNodes("*[@name='handPlayer']").Modded
$menu['OPArmor'].Enabled=$ItemsXml.Items.SelectNodes("*[@name='plantFiberPants']").Modded
$menu['ZNerf'].Enabled=$ItemsXml.Items.SelectNodes("*[@name='handZombie']/property[@class='Action0']/property[@name='DamageBlock']").Modded
$menu['Buffs'].Enabled=$BuffsXml.Buffs.SelectNodes("*[@id='bluePillBuff']").Modded
$menu['CorpsesLL'].Enabled=$entityclassesXml.entity_classes.SelectNodes("*[@name='Backpack']").SelectNodes("*[@name='TimeStayAfterDeath']").Modded

#exit

function cheats {
    #for future expansion
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
