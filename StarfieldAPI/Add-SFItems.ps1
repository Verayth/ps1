function Add-SFItems ($ItemGroup) {
    function addit ($formid,$name)  {
        Write-Host "Adding $itemGroup $name" -ForegroundColor Cyan
        Invoke-SFConsoleAPI "Player.Additem $formid"   # Spacesuit
    }
    if ($ItemGroup -eq 'mantis') {
        addit 00226299 Spacesuit
        addit 0016640B BackPack
        addit 0016640A Helmet
    } else {
        throw "Unknown Item Group"
    }
}
