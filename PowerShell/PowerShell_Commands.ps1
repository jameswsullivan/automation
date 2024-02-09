# Configure Storage Pool and Virtual Disk using PowerShell.
New-StoragePool

New-VirtualDisk -StoragePoolFriendlyName STORAGE_POOL_NAME `
                -FriendlyName VIRTUAL_DISK_NAME -UseMaximumSize `
                -ResiliencySettingName "Parity" -PhysicalDiskRedundancy 1 `
                -ProvisioningType Fixed -MediaType SSD

Get-VirtualDisk


# Get PowerShell command history.
Get-History


# Show PowerShell Version
$PSVersionTable
winget search Microsoft.PowerShell
winget install --id Microsoft.Powershell --source winget


# Install/Remove PowerShell Modules
Install-Module
Remove-Module

e.g.
Install-Module -Name SharePointPnPPowerShell2019 -RequiredVersion 3.29.2101.0


# Add SharePoint PowerShell Snapin
Add-PSSnapin Microsoft.SharePoint.PowerShell


# Get SharePoint Instance
Get-SPServiceInstance | Where-Object {$_.TypeName -eq 'Central Administration'}
Get-SPServer


# Display full width text pipe result into:
Format-Table -AutoSize

e.g.
Get-PnPGroup | Format-Table -AutoSize | Tee-Object AllGroupsOnHub.log


# Tweak PowerShell Console Colors
$host.privatedata
$host.privatedata.ErrorForegroundColor = 'White'

Console Color Reference
https://learn.microsoft.com/en-us/dotnet/api/system.consolecolor?view=net-7.0


# Change PowerShell ISE Tab Name
$psise.CurrentPowerShellTab.DisplayName = ‘Docker Host’


# Connect to remote computer via PowerShell and add remote computer to TrustedHosts
# On the computer you're currently working ON, not the remote computer you're remoting TO.
Enable-PSRemoting
Get-Item -Path WSMan:\localhost\Client\TrustedHosts
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "IP_of_Remote_Machine"
Enter-PSSession -ComputerName "IP_ADDR or PC_NAME" -Credential "Username"


# Test whether a port is open on a server with PowerShell
Test-NetConnection -ComputerName 192.168.1.1 -Port 443


# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Get-ExecutionPolicy -List