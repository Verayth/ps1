
#(Get-TypeData -TypeName System.IO.FileInfo).DefaultDisplayPropertySet.ReferencedProperties

<## >

Update-TypeData -TypeName System.IO.FileInfo -MemberType ScriptProperty -MemberName FileSize -Value { 
    switch($this.length) {
               { $_ -gt 1tb } 
                      { "{0:n2} TB" -f ($_ / 1tb) ; Break }
               { $_ -gt 1gb } 
                      { "{0:n2} GB" -f ($_ / 1gb) ; Break }
               { $_ -gt 1mb } 
                      { "{0:n2} MB " -f ($_ / 1mb) ; Break }
               { $_ -gt 1kb } 
                      { "{0:n2} KB " -f ($_ / 1Kb) ; Break }
               default  
                      { "{0} B " -f $_} 
             }
} -Force -DefaultDisplayPropertySet Mode,LastWriteTime,FileSize,Name

#(Get-TypeData -TypeName System.IO.FileInfo).DefaultDisplayPropertySet.ReferencedProperties

<##>

#https://blogs.technet.microsoft.com/pstips/2017/05/20/display-friendly-file-sizes-in-powershell/

$file = '{0}myTypes.ps1xml' -f ([System.IO.Path]::GetTempPath()) 
$data = Get-Content -Path $PSHOME\FileSystem.format.ps1xml
$data -replace '<PropertyName>Length</PropertyName>', @'
<ScriptBlock>
if($$_ -is [System.IO.FileInfo]) {
    $this=$$_.Length; $sizes='Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
    for($i=0; ($this -ge 1kb) -and ($i -lt $sizes.Count); $i++) {$this/=1kb}
    $N=2; if($i -eq 0) {$N=0}
    "{0:N$($N)} {1}" -f $this, $sizes[$i]
} else { $null }
</ScriptBlock>
'@ | Set-Content -Path $file
Update-FormatData -PrependPath $file

$file

<##>
