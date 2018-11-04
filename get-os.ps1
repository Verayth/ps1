#requires -version 3.0

[CmdletBinding()]
param (
	[string]$servername,
	[switch]$full
)

$ErrorActionPreference = "Stop";

# Get OS Version string
#systeminfo.exe
#[int]$verMajor = [environment]::OSVersion.Version | ft -property Major -HideTableHeaders -auto | Out-String
#[int]$verMinor = [environment]::OSVersion.Version | ft -property Minor -HideTableHeaders -auto | Out-String
#TODO: read remote reg
$regVer=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'

if ($servername) {
	$version=(gcim win32_operatingsystem -ComputerName $servername | ForEach-Object version) -split '\.'
	$systype=(gcim Win32_ComputerSystem -ComputerName $servername | ForEach-Object PCSystemType)
} else {
	$version=(gcim win32_operatingsystem | ForEach-Object version) -split '\.'
	$systype=(gcim Win32_ComputerSystem | ForEach-Object PCSystemType)
}

[int]$verMajor=$version[0]
[int]$verMinor=$version[1]
[int]$verBuild=$version[2]

switch ($systype) {
	4 {$isServer=$true}
	5 {$isServer=$true}
	7 {$isServer=$true}
}

#https://prajwaldesai.com/windows-operating-system-version-numbers/

$os=switch($verMajor) {
	1 {"Windows 1.0"}
	2 {"Windows 2.0"}
	3 {
		switch ($verMinor) {
			0  {"Windows 2.0"}
			10 {"Windows NT 3.1"}
			11 {"WFW 3.11"}
			5  {"Windows NT WS 3.5"}
			51 {"Windows NT WS 3.51"}
		}
	}
	4 {
		switch ($verMinor) {
			0  {if ($verBuild -eq  950) {"Win95"} else {"WinNTWS4"}}
			1  {if ($verBuild -eq 1998) {"Win98"} else {"Win98SE"}}
			90 {"WinMe"}
		}
	}
	5 {
		switch ($verMinor) {
			0  {"Win2kPro"}
			1  {"WinXP"}
		}
	}
	6 {
		switch ($verMinor) {
			0 {
					if ($isServer) {"Win2008"} else {"WinVista"}
			}
			1 {
					if ($verBuild -eq  7601) {
						if ($isServer) {"Win2008R2SP1"} else {"Win7SP1"}
					} elseif ($isServer) {"Win2008R2"}
					else {"Win7"}
			}
			2 {
					if ($isServer) {"Win2012"} else {"Win8"}
			}
			3 {
					if ($isServer) {"Win2012R2"}
					elseif ($verBuild -eq 9600) {"Win8.1u1"}
					else {"Win8.1"}
			}
		}
	}
	10 {
			if ($isServer) {"Win2016"} else {"Win10"}
	}
}

if ($full) {
    [PSCustomObject]@{
        OS=$os
		ProductName=$regVer.ProductName
		#Version=$version -join '.'
		ReleaseId=$regVer.ReleaseId
		Version=($regVer.CurrentMajorVersionNumber,$regVer.CurrentMinorVersionNumber,$regVer.CurrentBuild,$regVer.UBR) -join '.'
        PCSystemType=PCSystemType.ps1 $systype
		#BuildNumber=gcim win32_operatingsystem | ForEach-Object BuildNumber
		#BuildNumber=($regVer.CurrentBuild,$regVer.UBR) -join '.'
		EditionID=$regVer.EditionID
		#InstallDate=(Get-Date('1/1/1970')).AddSeconds($regVer.InstallDate)
		OriginalInstallDate=[DateTime]::FromFileTime($regVer.InstallTime)
    } | Format-Table -AutoSize
} else {
    $os
}
