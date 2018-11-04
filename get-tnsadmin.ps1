
#ls HKLM:/SOFTWARE/Oracle/* | select pschildname,pspath | % {Get-ItemProperty "$($_.PSPath)"} | select pspath,TNS_ADMIN

#Get-ChildItem HKLM:/SOFTWARE/Oracle/* | % {Get-ItemProperty $_.PSPath} | ? ORACLE_HOME_NAME | select ORACLE_HOME_NAME,TNS_ADMIN

#$orakeys = Get-ChildItem HKLM:/SOFTWARE/Oracle/* | % {Get-ItemProperty $_.PSPath} | ? ORACLE_HOME_NAME

foreach ($key in Get-ChildItem HKLM:/SOFTWARE/Oracle,HKLM:\SOFTWARE\Wow6432Node\ORACLE) {
	#$key 
	$prop = Get-ItemProperty $key.PSPath
	#Get-ItemProperty -path $key.PSPath -name TNS_ADMIN -ErrorAction SilentlyContinue

	# Print out the TNS var if this is an oracle home key
	if ($prop.ORACLE_HOME_NAME) {
		$prop | select ORACLE_HOME_NAME,TNS_ADMIN
	}
}
