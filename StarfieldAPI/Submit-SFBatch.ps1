function Submit-SFBatch ($BatchFile) {
    if (-not $Global:SFConsole_API) {Connect-SFConsoleAPI}

    Get-Content $BatchFile  | ForEach-Object {
        if ( $_ -like ';*') {
            # Write out the comments
            Write-Host $_ -ForegroundColor Magenta
        } elseif ($_) {
            $commentIndex=$_.IndexOf(';')
            $comment=$null
            if ($commentIndex -ge 0) {
                $command = $_.Substring(0,$commentIndex)
                $comment = $_.Substring($commentIndex)
            } else {
                $command = $_
            }
            Write-Host $command -NoNewline -ForegroundColor Yellow
            Write-Host $comment -ForegroundColor Magenta
            <##>
            Invoke-SFConsoleAPI $command  | Where-Object {
                $_ -notlike 'HasKeyword: ResourceType*' -and
                $_ -notlike 'WornHasKeyword*0.00'
            }
            <##>
        }
    }
}
