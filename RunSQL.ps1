#requires -Modules GAC,SqlServer

<#

.EXAMPLE
    "SQL Server"
    #[Microsoft.SqlServer.Management.Smo.Database]$db
      $db = sqldbs.ps1 | Select -first 1
      $db = ls SQLSERVER:\SQL\SOS-SQL1\#2012\Databases\ | ? Name -like A* | select -first 1
    RunSQL.ps1 $db.Name -Queries 'select * from sys.sql_logins' -SQLServer $db.Parent.Name
    RunSQL.ps1 $db.Name -SQLServer $db.Parent.Name -StoredProcedures 'sp_help' -Parameters @{objname="sp_configure"}
.EXAMPLE
    "Oracle"
    RunSQL.ps1 SLATE -Queries 'select * from global_name'
#>

[cmdletbinding()]
param(
    # The Database Name
	[parameter(mandatory=$true)] [string]$Database,
    # execute contents of SQL files
	[string[]]$SQLFiles,
    # SQL Queries
	[string[]]$Queries,
    # SQL Server instance (leave blank for Oracle DBs)
    [string]$SQLServer,
    # Stored Procedures
	[string]$StoredProcedures,
    # Parameters to pass to the SPs
    $Parameters=@{}
)

#$ErrorActionPreference = "Stop"
#Soft Requirement to keep Format-Table from breaking pipeline
Import-Module FormatPx -ErrorAction SilentlyContinue -Verbose:$false

if (-not $Queries -and -not $SQLFiles -and -not $StoredProcedures) {
    Write-Error "No SQL specified"
    exit 1
}

function getConnection() {
    if ($SQLServer) {
        Write-Verbose "SQL Server"
        [void][Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

        $oConn = New-Object -TypeName System.Data.SqlClient.SqlConnection
        $oConn.ConnectionString = "SERVER=$SQLServer;Integrated Security = True;Initial Catalog=$Database"

        #Attach the InfoMessage Event Handler to the connection to write out the messages
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Warning $event.Message }; 
        $oConn.add_InfoMessage($handler); 
        $oConn.FireInfoMessageEventOnUserErrors = $true;

        $oConn.Open()
        if ($oConn.State -eq 'Closed') {exit}
        return $oConn
    } else {
        Write-Verbose "Oracle"
        $assembly=Get-GacAssembly Oracle.DataAccess -Version 4.* -ProcessorArchitecture $env:PROCESSOR_ARCHITECTURE | sort Version | select -Last 1
        if ($assembly) {
            #$assembly
            Add-Type -AssemblyName ($assembly.FullName)
        } else {
            Write-Error "Unable to find Oracle.DataAccess driver"
            exit
        }

        $connString= "User Id=/;Data Source=$Database;"
        $oConn = New-Object Oracle.DataAccess.Client.OracleConnection($connString)

        if ($SQLServer) {
            #Attach the InfoMessage Event Handler to the connection to write out the messages
            $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {param($sender, $event) Write-Warning $event.Message }; 
            $oConn.add_InfoMessage($handler); 
            $oConn.FireInfoMessageEventOnUserErrors = $true;
        }

        $oConn.Open()
        if ($oConn.State -eq 'Closed') {exit}
        return $oConn
    }
}

function getCommand() {
    param([Object]$oConn)
    if ($oConn.GetType().FullName -eq 'System.Data.SqlClient.SqlConnection') {
        $Cmd = New-Object -TypeName system.data.sqlclient.sqlcommand
        $Cmd.Connection = $oConn
        #$Cmd.CommandText = $query
        return $Cmd
    } elseif ($oConn.GetType().FullName -eq 'Oracle.DataAccess.Client.OracleConnection') {
        $Cmd = new-Object Oracle.DataAccess.Client.OracleCommand
        $Cmd.Connection = $oConn
        return $Cmd
    } else {
        Write-Error "Unknown connection type passed"
    }
}

function RunSQL() {
    param(
        [Object]$oConn,
        [ValidateSet('StoredProcedure')][String]$CommandType
    )

    Using-Object.ps1 ($Cmd = getCommand $oConn) {
        if (-not $Cmd) {Write-Error "Unable to getCommand";exit 1}
        $Cmd.CommandText = $sql
	    foreach($p in $Parameters.Keys){
 		    [Void] $Cmd.Parameters.AddWithValue("@$p",$Parameters[$p])
 	    }
        $Cmd.CommandTimeout = (60*60)  # In Seconds

        if ($CommandType) {$Cmd.CommandType = [System.Data.CommandType]$CommandType}

        if ($CommandType -eq 'StoredProcedurexxx') {
	        $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Cmd)
	        $DataSet = New-Object System.Data.DataSet
	        [Void] $SqlAdapter.Fill($DataSet)
	        return $DataSet.Tables[0]
        } else {
            Using-Object.ps1 ($reader = $Cmd.ExecuteReader()) {
                while ($reader.Read()) {
                    $data=[PSCustomObject]@{}
                    for($i = 0; $i -lt $reader.FieldCount; $i++) {
                        $data | Add-Member -MemberType NoteProperty -Name $reader.GetName($i) -Value $reader.Item($i)
                    }
                    $data
                }
            }
        }
    }
}

Using-Object.ps1 ($oConn = getConnection) {
    if ($Queries) {
        foreach ($sql in $Queries) {
            Write-Verbose "Query: $sql"
            RunSQL $oConn | Format-Table -AutoSize
        }
    }

    if ($SQLFiles) {
        foreach ($file in $SQLFiles) {
            Write-Verbose "File: $file"
            $sql = Get-Content $file
            RunSQL $oConn | Format-Table -AutoSize
        }
    }

    if ($StoredProcedures) {
        foreach ($sql in $StoredProcedures) {
            Write-Verbose "SP: $sql"
            RunSQL $oConn -CommandType StoredProcedure | Format-Table -AutoSize
        }
    }
}
