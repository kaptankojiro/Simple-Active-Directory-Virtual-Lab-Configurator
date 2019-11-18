#Requires -RunAsAdministrator

# Resources:
# https://stackoverflow.com/questions/6217799/rename-computer-and-join-to-domain-in-one-step-with-powershell
# https://www.reddit.com/r/PowerShell/comments/4qg5xh/creating_powershell_script_to_change_ip_address/
# http://www.herlitz.nu/2016/09/13/disable-ipv6-on-all-ethernet-adapters-using-powershell/



clear
Write-Host 'Powershell version=' $PsVersionTable.PSVersion 
Write-Host 'Date =' (Get-date) 
Write-Host 'Welcome to Simple Virtual Lab Computer Configurator For Active Directory setups.'
Write-Host 'If you want to agree with change your configuration, press any button.'
read-host "Press Enter to continue..."ù

Write-Host "Disabling Domain, Public, Private Windows Firewall profiles" -ForegroundColor red -BackgroundColor white
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
sleep 2
Write-Host "Firewall profiles are disabled" -ForegroundColor red -BackgroundColor white
sleep 2


Write-Host "Disabling IPv6." -ForegroundColor red -BackgroundColor white
sleep 2
Get-NetAdapter | foreach { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
sleep 2
Write-Host "IPv6 disabled" -ForegroundColor red -BackgroundColor white
sleep 2

Write-Host "Please enter the IP Address...(Domain Controller IP: 10.1.1.1)  " -ForegroundColor red -BackgroundColor white
$IP = Read-Host -Prompt 'IP Address...'  
$MaskBits = 24 # This means subnet mask = 255.255.255.0
$Gateway = "10.1.1.1"
$Dns = "10.1.1.1"
$IPType = "IPv4"

# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"}

# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}

 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $IP `
    -PrefixLength $MaskBits `
    -DefaultGateway $Gateway

# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $DNS

sleep 2
Write-Host "IP Configuration is done." -ForegroundColor red -BackgroundColor white
sleep 2

  
$newName = Read-Host -Prompt "Enter New Computer Name"
$domain = Read-Host -Prompt "Enter Domain Name to be added"
$user = Read-Host -Prompt "Enter Domain user name"
$password = Read-Host -Prompt "Enter password for $user" -AsSecureString 
$username = "$domain\$user" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password) 
Rename-Computer -NewName $newName -LocalCredential administrator -Force
Write-Host "Please waiting for a moment to change Domain and then restart" -ForegroundColor Red
Add-Computer -DomainName $domain -Server dc.$domain -Credential (Get-Credential $domain\administrator) -NewName $newName -Restart
Write-Host "It looks everything done." -ForegroundColor red -BackgroundColor white
sleep 2