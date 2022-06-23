
Write-Output "Removing self-signed cert from local store."
$hostName = $env:COMPUTERNAME
Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object Issuer -eq "CN=$hostName" | Remove-Item -Verbose -Force

# delete firewall rules
# print all rules: netsh advfirewall firewall show rule name=all > firewall.txt

Write-Output "Removing WinRM HTTPS firewall rule."
$RuleName = "WinRM - Powershell remoting HTTPS-In"
if (Get-NetFirewallRule | Where-Object {$_.name -eq $Rulename}) {
	Write-Output "Removing existing Winrm HTTPS Firewall rule."
	Remove-NetFirewallRule -Name $Rulename
}

Write-Output "Restoring default settings: WinRM client configurations don't allow unencrypted connections."
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/client '@{AllowUnencrypted="false"}'

Write-Output "Removing the self-signed SSL certificate from root (server's) truststore."
Get-ChildItem -Path "Cert:\LocalMachine\root" | Where-Object Issuer -eq "CN=$hostName" | Remove-Item -Verbose -Force

$certExportPath = "C:\tmp\winrm-prep"
Write-Output "Deleting certificate `.cer` file from $certExportPath."
Remove-Item -Path $certExportPath -Recurse
