<#
http://www.jake.vosloo.co/blog/IT/powershellsslazureselfsignedcertificates

This script retrieves the certificate from an SSL connection, saves the certificate as a file and attempts to import it into the trusted root store.
USAGE:  .\DownloadCertAndImportRoot.ps1 "https://www.google.com"
Adapted from: 
https://bernhardelbl.wordpress.com/2013/03/21/download-and-install-a-certificate-to-your-trusted-root-using-powershell/
#>
param($url)

[Net.ServicePointManager]::ServerCertificateValidationCallback = {$true} #Bypass Powershell certificate validation, so that we can download any untrusted certificate.

[System.Uri] $u = New-Object System.Uri($url)
[Net.ServicePoint] $sp = [Net.ServicePointManager]::FindServicePoint($u);

[System.Guid] $groupName = [System.Guid]::NewGuid() #allow to quickly close all connections

[Net.HttpWebRequest] $req = [Net.WebRequest]::create($url)
$req.Method = "GET"
$req.Timeout = 600000 # = 10 minutes
$req.ConnectionGroupName = $groupName

# // Set if you need a username/password to access the resource
#$req.Credentials = New-Object Net.NetworkCredential("username", "password");
[Net.HttpWebResponse] $result = $req.GetResponse() #If the server return 404 then you will get an exception here.
$sp.CloseConnectionGroup($groupName) | Out-Null

<# This Version uses CertUtil # >
$fullPathIncFileName = $MyInvocation.MyCommand.Definition
 
$currentScriptName = $MyInvocation.MyCommand.Name
 
$currentExecutingPath = $fullPathIncFileName.Replace($currentScriptName, "")
 
$outfilename = $currentExecutingPath + "Export.cer"
 
[System.Byte[]] $data = $sp.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
[System.IO.File]::WriteAllBytes($outfilename, $data)
Write-Host $outfilename
 
CertUtil -addStore Root $outfilename

<# PowerShell Native #>

#Write the certificate to a temp file
$tempfilename = [System.IO.Path]::GetTempFileName() #get a temporary file reference
[System.Byte[]] $data = $sp.Certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
[System.IO.File]::WriteAllBytes($tempfilename, $data)
Write-Debug "Downloaded to temp file: $tempfilename"

#move the temp file to the local folder for future use.
$outfilename = (Convert-Path .) + "\CertExport.cer"
if(Test-Path $outfilename) { del $outfilename }
mv $tempfilename $outfilename
Write-Host "Certificate saved as: $outfilename"

#Import the certificate into the root certificate store
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    #CertUtil -addStore Root $outfilename
    $pfx = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store(“Root”,”LocalMachine”)
    $pfx.Import($outfilename)
    $store.Open(“MaxAllowed”)
    $store.Add($pfx)
    $store.Close()
}
else
{
    Write-Host "The script is not running as administrator and cannot automatically import the certificate into the root store. You should Right-click the exported certificate file and install it into the trusted root store."
}
<##>
