# Environment: SharePoint 2019 Management Shell
# Ref: https://learn.microsoft.com/en-us/powershell/sharepoint/

# Rebuild Distributed Cache after SharePoint Server Farm Updates.
Remove-SPDistributedCacheServiceInstance
PSCONFIG.exe -cmd upgrade -inplace b2b -wait -cmd applicationcontent -install -cmd installfeatures -cmd secureresources -cmd services -install
Add-SPDistributedCacheServiceInstance

$webapp = Get-SPWebApplication <SiteURL>
$webapp.WebService.SideBySideToken = "$((Get-SPFarm).BuildVersion)"
$webapp.WebService.Update()

# Troubleshoot Distributed Cache
Use-CacheCluster

Get-CacheHostConfig
Get-CacheHostConfig –HostName <ServerName> –CachePort 22233
 
Get-SPDistributedCacheServiceInstance

Get-CacheHost

Get-CacheStatistics

Get-AFCache | Select CacheName

Get-CacheStatistics -CacheName default


# Configure SharePoint Server and Office Online Server Connection

Remove-SPWOPIBinding -All
Get-SPWOPIBinding
New-SPWOPIBinding -ServerName office19.library.tamu.edu -AllowHTTP
Set-SPWOPIZone -zone "internal-http"
Get-SPWOPIZone


(Get-SPSecurityTokenServiceConfig).AllowOAuthoverHttp
$config = (Get-SPSecurityTokenServiceConfig)
$config.AllowOAuthOverHttp = $true
$config.Update()

Get-SPWOPIBinding –Application "WordPDF" | Remove-SPWOPIBinding -Confirm:$false

New-SPWOPIBinding –ServerName "<ServerURL>" –Application "WordPDF" -AllowHTTP

$Farm = Get-SPFarm
$Farm.Properties.Add("WopiLegacySoapSupport", "<ServerURL>/x/_vti_bin/ExcelServiceInternal.asmx");
$Farm.Update();

$Farm.Properties.WopiLegacySoapSupport

New-OfficeWebAppsHost -domain "library.tamu.edu"


# Set HSTS
Get-SPWebApplication
$hub = Get-SPWebApplication <SiteURL>
$hub.HttpStrictTransportSecuritySettings.IsEnabled
$hub.HttpStrictTransportSecuritySettings.IsEnabled = $true
$hub.Update()