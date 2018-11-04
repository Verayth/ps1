ssh-agent.ps1 > $null

$ErrorActionPreference='Stop'

ConvertFrom-LinuxDfOutput.ps1 -Text (cmd /c "ssh freenas df 2>nul") | ? { (Split-Path -Path $_.MountedOn -Leaf) -NotIn 'dev','proc','fd','grub' }

#ConvertFrom-LinuxDfOutput.ps1 -Text (ssh root@freenas df 2>$null) | ? capacity -gt .7 | ? used -gt 50mb | ? available -lt 2gb
