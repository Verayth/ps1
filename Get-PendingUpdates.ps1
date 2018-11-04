#requires -modules FormatPx,ImportExcel
<#
  https://gallery.technet.microsoft.com/scriptcenter/0dbfc125-b855-4058-87ec-930268f03285#content
  https://learn-powershell.net/2011/03/07/find-pending-updates-on-local-or-remote-computers/
#>
[CmdletBinding(DefaultParameterSetName = 'computer')] 
param(
    #Computer (Defaults to localhost)
    [Parameter(ValueFromPipeline=$True)][string[]]$ComputerName,
    #https://docs.microsoft.com/en-us/windows/desktop/api/wuapi/nf-wuapi-iupdatesearcher-search
    [string]$Search = "(IsInstalled = 0 and IsHidden = 0)",
    #only include Feature and Service Packs
    [switch]$Features,
    #Find Severe Updates
    [switch]$Severe,
    #Excel Output
    [string]$ExcelOutFile
)

if ($Severe) {$Search = "(IsInstalled = 0 and AutoSelectOnWebSites = 1 and IsHidden = 0)"}

Function Get-PendingUpdate { 
    [CmdletBinding( 
        DefaultParameterSetName = 'computer' 
        )] 
    param( 
        [Parameter(ValueFromPipeline = $True)] 
            [string[]]$Computername = $env:COMPUTERNAME
        )     
    Process { 
        ForEach ($c in $Computername) {
            #Write-Verbose "Computer: $($c)" 
            If (Test-Connection -ComputerName $c -Count 1 -Quiet -TimeToLive 2) { 
                Try { 
                    #Create Session COM object 
                    Write-Verbose "${c}: Creating COM object for WSUS Session"
                    $updatesession =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$c)) 
                } Catch { 
                    Write-Warning "$($Error[0])" 
                    Break 
                } 
                $updatesearcher = $updatesession.CreateUpdateSearcher()
                Write-Verbose "Searching: $Search" 
                $searchresult = $updatesearcher.Search($Search)
                Write-Verbose "Processing Results" 
                foreach ($Update in $searchresult.Updates) { 
                    $output = New-Object -TypeName PsObject
                    Add-Member -InputObject $output -MemberType ScriptMethod -Name AddNote -Value {  
                            Add-Member -InputObject $this -MemberType NoteProperty -Name $args[0] -Value $args[1]
                        }
                    $Update | Get-Member -MemberType Property | % { 
                        if ( $Update.($_.name) ) {
                            $type = ($Update.($_.name)).GetType().Name
                            #Write-Verbose ("Type of {0}= {1}" -f $_.name,$type)
                        } else {
                            $type = $null
                        }
                        if ($_.name -in 'Categories') {
                            #$output.AddNote($_.name, $Update.($_.name))
                            $output.AddNote($_.name, (($Update.($_.name) | Select-Object -ExpandProperty Name)))
                        } elseif ($_.name -eq 'BundledUpdates') {
                            $output.AddNote('BundledUpdates',( @($Update.BundledUpdates)|ForEach{
                               [pscustomobject]@{
                                    Title = $_.Title
                                    DownloadUrl = @($_.DownloadContents).DownloadUrl
                                }
                            }))
                        } elseif ($type -eq '__ComObject') {
                            #$val = $Update.($_.name) | % {"{0}" -f $_ }
                            $val = $Update.($_.name) | Out-String
                            #$val = $Update.($_.name)
                            if ($val -eq 'System.__ComObject') {
                                #Write-Verbose ("Unable to convert ComObject to String: {0}" -f $_.name)
                                $output.AddNote($_.name, $Update.($_.name))
                            } else {
                                $output.AddNote($_.name, $val)
                            }
                        } else {
                            $output.AddNote($_.name, $Update.($_.name))
                        }
                    }
                    $output.AddNote('Computer',$c)
			        $output | Add-Member -MemberType AliasProperty -Name KB -Value KBArticleIDs
			        $output | Add-Member -MemberType AliasProperty -Name Severity -Value MsrcSeverity
			        $output | Add-Member -MemberType AliasProperty -Name DWN -Value IsDownloaded
			        $output | Add-Member -MemberType AliasProperty -Name SecIDs -Value SecurityBulletinIDs
                    $output
                }
            } Else { Write-Warning "$($c): Offline" }
        }  
    }     

}

$format=(
    @{N='Computer';W=10;E={$_.Computer};},
    @{N='KB';W=8;E={$_.KBArticleIDs};},
    @{N='Severity';W=9;E={$_.MsrcSeverity};},
    @{N='DWN?';W=5;E={$_.IsDownloaded};},
    @{N='SecIDs';W=9;E={$_.SecurityBulletinIDs};},
    @{N='Categories';W=25;E={$_.Categories};},
    @{N='Title';E={$_.Title};}
    #@{N='MoreInfoUrls';E={$_.MoreInfoUrls};}
)

$csvformat=(
    @{N='Computer';E={$_.Computer};},
    @{N='KB';E={$_.KBArticleIDs -join ","};},
    @{N='Severity';E={$_.MsrcSeverity};},
    @{N='Downloaded?';E={$_.IsDownloaded};},
    @{N='Security|Bulletins';E={$_.SecurityBulletinIDs -join ","};},
    @{N='Categories';E={$_.Categories -join ","};},
    @{N='Title';E={$_.Title};},
    @{N='MoreInfoUrls';E={$_.MoreInfoUrls -join ","};}
)

function getUpdates {
    Get-PendingUpdate -Computername $ComputerName |? {
                -not $Features -or
                ($_.Categories -match 'Feature Packs' -or $_.Categories -match 'Service Packs') -and
                'Silverlight' -notin $_.Categories
            } 
}

if ($ExcelOutFile) {
    $out = getUpdates
    if ($out) {
        Write-Verbose "Write Excel File"
        #$out | Select Computer,KB,Severify,IsDownloaded,SecurityBulletinIDs,Categories,Title,MoreInfoUrls | ConvertTo-Csv -NoTypeInformation
        $out | Select-Object ($csvformat) | Export-Excel $ExcelOutFile -KillExcel -ClearSheet
        #$out | Export-Excel $ExcelOutFile -KillExcel
        XlsFormat.ps1 $ExcelOutFile
        #Invoke-Item $ExcelOutFile
    } elseif (Test-Path $ExcelOutFile) {
        Write-Verbose "Remove Excel File"
        Export-Excel $ExcelOutFile -KillExcel
        Remove-Item $ExcelOutFile
    } else {
        Write-Verbose "DONE"
    }
} else {
    getUpdates | Format-Table ($format)
}
