
#[IO.Compression.ZipFile].GetMethods().Name;exit
#[System.IO.Compression.ZipArchive].GetMethods().Name;exit
#[System.IO.Compression.ZipArchiveEntry].GetMethods().Name|ft;exit

$tempfile = "$env:TEMP\tempipafile.ipa"
#$tempfile;exit

foreach (
    $ipa in Get-ChildItem "$env:USERPROFILE\Music\iTunes\Mobile Applications\*.ipa" #| ? Name -Like 'Timer+*'
) {
    #$ipa|gm;exit
    #$ipa
    $zipFile = [IO.Compression.ZipFile]::OpenRead($ipa.FullName)
    #$zipFile | gm;exit

    $Message = ''
    #$zipFile;exit
    #$dirName = $zipFile.Entries | ? FullName -like 'Payload/*.app/' | % FullName
    $dirName = $zipFile.Entries | ? FullName -Match '^Payload/[^/]*\.app/$' | % FullName
    #$dirName
    $fname = $dirName.Replace('Payload/','').Replace('.app/','')
    try {
        $entry = $zipFile.GetEntry("$dirName$fname")
        #$entry | ft -AutoSize
        #$entry | gm ; exit
        if ($entry) {
            $file = $entry.Open()
            $filestream = New-Object IO.FileStream ($tempfile) ,'Append','Write','Read'
            $file.CopyTo($filestream)
            #$file | gm
            $file.Close()
            $filestream.Close()
            $Message = file -b $tempfile
        } else {
            $Message = "Unable to find entry '$("$dirName$fname")'"
        }
    } catch {
        #Write-Warning "Unable to get filetype for '$($ipa.Name)'"
        $Message = "ERROR: " + $Error[0].Exception.Message
        #exit
    }
    [PSCustomObject]@{
        FileName = $ipa.Name
        Date     = $ipa.CreationTime.ToString('yyyy-MM-dd')
        FileType = $Message
    }
    $zipFile.Dispose()
}
