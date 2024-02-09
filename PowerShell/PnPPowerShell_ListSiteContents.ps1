# Export a list of a single Document Library's contents recursively.
# Use: GetSiteContents("Site_Url"), GetLibContents("Document_Library_Name")
$UserName = "your_username"
$Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username,$Password)

function GetSiteContents($url) {
    Connect-PnPOnline -URL $url -Credentials $Cred
    Get-PnPList
}

function GetLibContents($name) {
    $FileName = Get-PnPWeb | Select-Object -ExpandProperty Title
    $FileName += " - "
    $FileName += $name
    $FileName += ".csv"
    Get-PnPFolderItem -FolderSiteRelativeUrl $name -Recursive | Select-Object TypedObject,ItemCount,Name,ServerRelativeUrl,TimeCreated,TimeLastModified,UniqueId | Export-Csv -Path .\$FileName
}

# List all Document Libraries and Lists (Site Contents) of Site/Subsite.
# Use: List-SiteContent -RootSiteUrl "your_sites_root_url"
function ListSiteContent {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $RootSiteUrl
    )

    # Connect to root site and recursively retrieve all subsites.
    Connect-PnPOnline -Url $RootSiteUrl -Credentials $Cred
    $SubsitesUrls = Get-PnPSubwebs -Recurse -IncludeRootWeb | Select-Object Url

    # Connect to each subsite and retrieve list of site assets.
    ForEach ($SiteUrl in $SubsitesUrls) {
        $ConnectionUrl = $SiteUrl."Url"
        Connect-PnPOnline -Url $ConnectionUrl -Credentials $Cred
        $FileName = Get-PnPWeb | Select-Object -ExpandProperty Title
        $FileName += ".csv"
        Get-PnPList | Select-Object BaseType,Title,ParentWebUrl,DefaultViewUrl,Description,DocumentTemplateUrl,Id,Created,LastItemDeletedDate,LastItemModifiedDate,LastItemUserModifiedDate | Export-Csv $FileName
    }
}