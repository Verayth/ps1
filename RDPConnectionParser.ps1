<#

.SYNOPSIS
    This script reads the event log "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" from
    multiple servers and outputs the human-readable results to a CSV.  This data is not filterable in the native
    Windows Event Viewer.

    Version: November 9, 2016


.DESCRIPTION
    This script reads the event log "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" from
    multiple servers and outputs the human-readable results to a CSV.  This data is not filterable in the native
    Windows Event Viewer.

    NOTE: Despite this log's name, it includes both RDP logins as well as regular console logins too.

    Author:
    Mike Crowley
    https://BaselineTechnologies.com

 .EXAMPLE

    .\RDPConnectionParser.ps1 -ServersToQuery Server1, Server2 -StartTime "November 1"

.LINK
    https://MikeCrowley.us/tag/powershell

#>

[cmdletbinding()]
Param(
    [array]$ServersToQuery = (hostname),
    #[datetime]$StartTime = "January 1, 1970"
    [datetime]$StartTime = (Get-Date).AddDays(-14),
    [System.Management.Automation.PSCredential] $Credential
)

#Soft Requirement to keep Format-Table from breaking pipeline
Import-Module FormatPx -ErrorAction SilentlyContinue -Verbose:$false

    foreach ($Server in $ServersToQuery) {

        $LogFilter = @{
            LogName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'
            ID = 21, 23, 24, 25
            StartTime = $StartTime
            }

        try {
            if ($Credential) {
        	    $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server -ErrorAction stop -Verbose:$false -Credential $Credential
            } else {
        	    $AllEntries = Get-WinEvent -FilterHashtable $LogFilter -ComputerName $Server -ErrorAction stop -Verbose:$false
            }

					$AllEntries | Foreach {
							$entry = [xml]$_.ToXml()
							[array]$Output += New-Object PSObject -Property @{
									TimeCreated = $_.TimeCreated
									User = $entry.Event.UserData.EventXML.User
									IPAddress = $entry.Event.UserData.EventXML.Address
									EventID = $entry.Event.System.EventID
									ServerName = $Server
									}
							}
        } catch [System.Exception] {
        	if ($Error[0].FullyQualifiedErrorId -like 'NoMatchingEventsFound*') {
        		Write-Warning "$($Server): No logins since $StartTime"
        	} else {
        		throw $Error[0]
        	}
        	#$Error[0]
				#} catch {$Error[0] | fl -Force;exit
				}

    }

    $FilteredOutput += $Output | Select TimeCreated, User, ServerName, IPAddress, @{Name='Action';Expression={
                if ($_.EventID -eq '21'){"logon"}
                if ($_.EventID -eq '22'){"Shell start"}
                if ($_.EventID -eq '23'){"logoff"}
                if ($_.EventID -eq '24'){"disconnected"}
                if ($_.EventID -eq '25'){"reconnection"}
                }
            }

#load the output format file
#if (Test-Path "$($PSCommandPath)xml") {Update-FormatData -PrependPath "$($PSCommandPath)xml"}

#$Date = (Get-Date -Format s) -replace ":", "."
#$FilePath = "$env:USERPROFILE\Desktop\$Date`_RDP_Report.csv"
#$FilteredOutput | Sort TimeCreated | Export-Csv $FilePath -NoTypeInformation
$FilteredOutput | Format-Table

#Write-host "Writing File: $FilePath" -ForegroundColor Cyan
#Write-host "Done!" -ForegroundColor Cyan


#End
