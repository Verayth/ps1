#requires -Module FormatPx

$format = @(
    @{Align='left';Width=10;Label="ModuleType";Expression={$_.ModuleType}},
    @{Align='left';Width=10;Label="Version";Expression={$_.Version}},
    @{Align='left';Width=5;Label="PSG";Expression={$_.PSG}},
    @{Align='left';Width=25;Label="Name";Expression={if ($_.Name.length -gt 25) {"..."+$_.Name.SubString($_.Name.length-22)} else {$_.Name} }},
    @{Align='left';Label="ExportedCommands";Expression={$_.ExportedCommands}}
)
    #@{Align='left';Width=5;Label="PSG";Expression={if ($_.RepositorySourceLocation -like '*powershellgallery*') {$true} else {$false} }},


Get-Module -ListAvailable | ? path -notlike '*\v1.0\Modules\*' | 
    ForEach-Object {
        $_ | Add-Member -PassThru -MemberType NoteProperty -Name PSG -Value {
            if ($_.RepositorySourceLocation -like '*powershellgallery*') {$true}
            else {$false}
        }.InvokeReturnAsIs()
    } | Format-Table ($format)

    #Add-Member -MemberType NoteProperty -Name PSG -Value {if ($_.RepositorySourceLocation -like '*powershellgallery*') {$true} else {$false} } |
