This repository documents PowerShell scripts and commands I use for task automation and troubleshooting.
<br>
<br>

## 1. PowerShell_Commands.ps1
- Common PowerShell commands.
<br>

## 2. PnPPowerShell_Commands.ps1
- Common PnP PowerShell commands. https://pnp.github.io/powershell/
<br>

## 3. PowerShell_DockerImageDeployment.ps1
- Automate Docker image build and deployment to Harbor registry.
<br>

## 4. PowerShell_SharePoint.ps1
- Troubleshoot SharePoint 2019.
<br>

## 5. PnPPowerShell_DeleteSubsites.ps1
- Delete SharePoint site by URL.
    - USE: DeleteSubsite("site_url_to_be_deleted")
<br>

## 6. PnPPowerShell_ListSiteContents.ps1
- List a single subsite's site contents.
    - USE: GetSiteContents("Site_Url"), GetLibContents("Document_Library_Name")
- Recursively traverses every subsite and lists their site content. You only need to provide the root site url.
    - USE: List-SiteContent -RootSiteUrl "your_sites_root_url"
<br>

## 7. PnPPowerShell_DownloadDocumentLibraryV1.ps1 (Use Get-PnPFolderItem)
- List site contents.
    - USE: Get-SiteContent -SiteURL "full_site_url_here"
- List files and folders in a Document Library
    - USE: Get-DocumentLibraryItem -DocumentLibraryName "Document_Library_Name"
- Download a Document Library to current working directory.
    - USE: Download-DocumentLibrary -DocumentLibraryName "Document_Library_Name"
<br>

## 8. PnPPowerShell_DownloadDocumentLibraryV2.ps1 (Use Get-PnPListItem with CALM Queries, with improved logging.)
- Generate executable commands.
    - USE: Generate-Commands -urlFile "text_file_containing_SharePoint_site_URLs.txt"
- List site contents.
    - USE: Get-SiteContent -SiteURL "full_site_url_here"
- List files and folders in a Document Library
    - USE: Get-DocumentLibraryItem -DocumentLibraryName "Document_Library_Name"
- Download a Document Library to current working directory.
    - USE: Download-DocumentLibrary -DocumentLibraryName "Document_Library_Name"
<br>

## 9. PnPPowerShell_ExportSharePointCalendarToCSV.ps1
- List all "Lists" of a subsite.
    - USE: Get-SiteLists -SiteURL "full_site_url_here"
- Get List Events from a List/Calendar.
    - USE: Get-CalendarEvents -CalendarName "Calendar_Name"
- Show calendar event's FieldValues.
    - USE: Get-CalendarEventSample -CalendarName "Calendar_Name"