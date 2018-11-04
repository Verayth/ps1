#http://www.computerperformance.co.uk/powershell/powershell_win32_computersystem.htm

[CmdletBinding()]
param (
	[string]$servername
)

$ErrorActionPreference = "Stop";

# Win32ComputerSystem example .PCSystemType

if ($servername) {
	$CompConfig = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $servername
} else {
	$CompConfig = Get-WmiObject -Class Win32_ComputerSystem
}

foreach ($ObjItem in $CompConfig) {
	$Type = $objItem.PCSystemType
	Switch ($Type) {
		1 {"Desktop"}
		2 {"Mobile / Laptop"}
		3 {"Workstation"}
		4 {"Enterprise Server"}
		5 {"Small Office and Home Office (SOHO) Server"}
		6 {"Appliance PC"}
		7 {"Performance Server"}
		8 {"Maximum"}
		default {"Not a known Product Type"}
	}
}
