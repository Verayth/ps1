#http://www.computerperformance.co.uk/powershell/powershell_win32_computersystem.htm

[CmdletBinding()]
param (
	[string]$servername
)

$ErrorActionPreference = "Stop";

# Win32ComputerSystem example .DomainRole
if ($servername) {
	$CompConfig = Get-WmiObject Win32_ComputerSystem -ComputerName $servername
} else {
	$CompConfig = Get-WmiObject Win32_ComputerSystem
}
foreach ($ObjItem in $CompConfig) {
	$Role = $ObjItem.DomainRole
	Switch ($Role) {
		0 {"Standalone Workstation"}
		1 {"Member Workstation"}
		2 {"Standalone Server"}
		3 {"Member Server"}
		4 {"Backup Domain Controller"}
		5 {"Primary Domain Controller"}
		default {"Not a known Domain Role"}
	}
}
