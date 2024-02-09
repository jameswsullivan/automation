# This script downloads entire SharePoint document libraries to your current working directory.

# The PnPPowerShell_DownloadDocumentLibraryV1.ps1 script uses Get-PnPFolderItem cmdlet and was having
# "File Not Found" errors with some document libraries. This improved script uses Get-PnPListItem with
# CALM Queries and has improved logging.

# Environment: SharePoint 2019 on-prem installation.
# Set the error action preference
$ErrorActionPreference = 'Stop'

# Set up login credentials.
$UserName = "your_username"
$Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username,$Password)

# Generate executable commands. This script generates commands using a text file that contains
# all the SharePoint site/subsite URLs (one URL per line.)
# Use: Generate-Commands -urlFile "text_file_containing_SharePoint_site_URLs.txt"
function Generate-Commands {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)] [string] $urlFile
    )

    try {
        # Verify if the file exists
        if ( ! (Test-Path -Path $urlFile)) {
            Write-Host -ForegroundColor Red "File Not Found: $urlFile."
        }else{
            Write-Host -ForegroundColor Green "File exists: $urlFile."
        }

        $DestinationFile = ".\" + $urlFile + " - Commands.txt"
        New-Item $DestinationFile -Type File
        Write-Host -ForegroundColor Green "$DestinationFile created."

        # Read the file line by line
        Get-Content -Path $urlFile | ForEach-Object {
            try {
                $SiteURL = $_
                Connect-PnPOnline -URL $SiteURL -Credentials $Cred
                $SiteName = Get-PnPWeb |  Select-Object -ExpandProperty Title
    
                $GetSiteContent = "Get-SiteContent -SiteURL `"$SiteURL`"";
                $GetDocumentLibraryItem = "Get-DocumentLibraryItem -DocumentLibraryName `"Private Documents`""
                $DownloadDocumentLibrary = "Download-DocumentLibrary -DocumentLibraryName `"Private Documents`""
    
                $SiteName = "Site Name: " + $SiteName + ":"
                Add-Content $DestinationFile $SiteName
                Add-Content $DestinationFile "Site URL: $SiteURL ."
                Add-Content $DestinationFile $GetSiteContent
                Add-Content $DestinationFile $GetDocumentLibraryItem
                Add-Content $DestinationFile $DownloadDocumentLibrary
                Add-Content $DestinationFile ""
    
                Write-Host -ForegroundColor Green "Commands for $SiteName generated."
            }
            catch {
                $SiteName = "[ERROR] - Site Name: " + $SiteName + ":"
                $ErrorMessage = "[ERROR] - " + $SiteURL + " - " + $_.Exception.Message
                Add-Content $DestinationFile $SiteName
                Add-Content $DestinationFile "[ERROR] - Site URL: $SiteURL ."
                Add-Content $DestinationFile $ErrorMessage
                Add-Content $DestinationFile ""

                Write-Host -ForegroundColor Red $SiteName
                Write-Host -ForegroundColor Red $ErrorMessage
            }
        }
        Write-Host -ForegroundColor Green "All commands have been generated."
    }
    catch{
        Write-Host -ForegroundColor Red "[ATTENTION] - Process finished with errors."
        $ErrorMessage = "[ERROR] - " + $_.Exception.Message
        Add-Content $DestinationFile $ErrorMessage
        Write-Host -ForegroundColor Red $ErrorMessage
    }
}

# Log function.
# Use: Save-Log -Timestamp  -MsgForegroundColor  -LogFile  -LogMessage 
function Save-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $Timestamp,
        [Parameter(Mandatory=$true)] [string] $Type,
        [Parameter(Mandatory=$true)] [string] $MsgForegroundColor,
        [Parameter(Mandatory=$true)] [string] $LogFile,
        [Parameter(Mandatory=$true)] [string] $LogMessage
    )

    $LogMessage = $Timestamp + " - " + $Type + " - " + $LogMessage
    Write-Host -ForegroundColor $MsgForegroundColor $LogMessage
    Add-Content $LogFile $LogMessage
}

# Get list of site contents.
# Use: Get-SiteContent -SiteURL "full_site_url_here"
function Get-SiteContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $SiteURL
    )

    try {
        # Connect to site.
        Connect-PnPOnline -URL $SiteURL -Credentials $Cred

        # Export site content to a text file.
        $SiteName = Get-PnPWeb |  Select-Object -ExpandProperty Title
        $DestinationFilePath = ".\" + $SiteName + " - SiteContentList.csv"
        
        # Print content to screen.
        Get-PnPList

        # Output to a .csv file.
        Get-PnPList | `
        Select-Object -Property `
            @{Name='Title'; Expression={$_.Title}}, `
            @{Name='BaseType'; Expression={$_.BaseType}}, `
            @{Name='Description'; Expression={$_.Description}}, `
            @{Name='DefaultViewUrl'; Expression={$_.DefaultViewUrl}}, `
            @{Name='ParentWebUrl'; Expression={$_.ParentWebUrl}}, `
            @{Name='DocumentTemplateUrl'; Expression={$_.DocumentTemplateUrl}}, `
            @{Name='Created'; Expression={$_.Created}}, `
            @{Name='LastItemDeletedDate'; Expression={$_.LastItemDeletedDate}}, `
            @{Name='LastItemModifiedDate'; Expression={$_.LastItemModifiedDate}}, `
            @{Name='LastItemUserModifiedDate'; Expression={$_.LastItemUserModifiedDate}}, `
            @{Name='Hidden'; Expression={$_.Hidden}}, `
            @{Name='Id'; Expression={$_.Id}} | `
        Export-Csv -Path $DestinationFilePath -NoTypeInformation

        Write-Host -ForegroundColor Green "$SiteName content list exported to $DestinationFilePath."
    }
    catch {
        $_.Exception.Message
    }
}

# Get list of files in a Document Library
# Use: Get-DocumentLibraryItem -DocumentLibraryName "Document_Library_Name"
function Get-DocumentLibraryItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $DocumentLibraryName
    )

    try {
        # Create folder for the Document Library. e.g. ".\SiteName - DocumentLibraryName"
        $SiteName = Get-PnPWeb | Select-Object -ExpandProperty Title
        $DestFolder = ".\" + $SiteName + " - " + $DocumentLibraryName
            
        if (!(Test-Path -Path $DestFolder)) {
            New-Item $DestFolder -Type Directory | Out-Null
            Write-Host -ForegroundColor Green "$DestFolder created!"
        }else{
            Write-Host -ForegroundColor Green "'$DestFolder' already exists!"
        }

        # Create a log file to log each steps taken.
        $LogfilePath = $DestFolder + "\DownloadLog.log"
        if (!(Test-Path -Path $LogfilePath))
        {
            New-Item -Path $DestFolder -Name "DownloadLog.log" -ItemType "File" -Force | Out-Null
            Save-Log -Timestamp $(Get-Date) -Type "[INFO]" -MsgForegroundColor "Green" -LogFile $LogfilePath -LogMessage "'$LogfilePath' created!"
        }else{
            Save-Log -Timestamp $(Get-Date) -Type "[INFO]" -MsgForegroundColor "Green" `
            -LogFile $LogfilePath -LogMessage "'$LogfilePath' already exists!"
        }

        # Get all files.
        $camlQueryFiles = "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>0</Value></Eq></Where></Query></View>"
        $FileCollection = Get-PnPListItem -List $DocumentLibraryName -Query $camlQueryFiles
        $FileURLCollection = $FileCollection | ForEach-Object { New-Object PSObject -Property @{ 'ServerRelativeUrl' = $_.FieldValues["FileRef"] } }
        
        $DestFileName = $DocumentLibraryName + " - Files.csv"
        $FileURLCollection | Export-Csv -Path .\$DestFolder\$DestFileName -NoTypeInformation

        Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
        -LogFile $LogfilePath -LogMessage "Files from '$DocumentLibraryName' successfully retrieved!"


        # Get all folders.
        $camlQueryFolders = "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>1</Value></Eq></Where></Query></View>"
        $FolderCollection = Get-PnPListItem -List $DocumentLibraryName -Query $camlQueryFolders
        $FolderURLCollection = $FolderCollection | ForEach-Object { New-Object PSObject -Property @{ 'ServerRelativeUrl' = $_.FieldValues["FileRef"] } }
        
        $DestFileName = $DocumentLibraryName + " - Folders.csv"
        $FolderURLCollection | Export-Csv -Path .\$DestFolder\$DestFileName -NoTypeInformation

        Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
        -LogFile $LogfilePath -LogMessage "Folders from '$DocumentLibraryName' successfully retrieved!"
    }
    catch {
        Save-Log -Timestamp $(Get-Date) -Type "[ERROR]"  -MsgForegroundColor "Red" `
        -LogFile $LogfilePath -LogMessage $_.Exception.Message
    }
}

# Download files from FileCollection to local folder.
# Use: Download-DocumentLibrary -DocumentLibraryName "Document_Library_Name"
function Download-DocumentLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $DocumentLibraryName
    )

    try {
        # Create folder for the Document Library. e.g. ".\SiteName - DocumentLibraryName"
        $SiteName = Get-PnPWeb | Select-Object -ExpandProperty Title
        $DestFolder = ".\" + $SiteName + " - " + $DocumentLibraryName

        if (!(Test-Path -Path $DestFolder)) {
            New-Item $DestFolder -Type Directory | Out-Null
            Write-Host -ForegroundColor Green "'$DestFolder' created!"
        }else{
            Write-Host -ForegroundColor Green "'$DestFolder' already exists!"
        }

        # Create a log file to log each steps taken.
        $LogfilePath = $DestFolder + "\DownloadLog.log"
        if (!(Test-Path -Path $LogfilePath)) {
            New-Item -Path $DestFolder -Name "DownloadLog.log" -ItemType "File" -Force | Out-Null
            Save-Log -Timestamp $(Get-Date) -Type "[INFO]" -MsgForegroundColor "Green" `
            -LogFile $LogfilePath -LogMessage "'$LogfilePath' created!"
        }else{
            Save-Log -Timestamp $(Get-Date) -Type "[INFO]" -MsgForegroundColor "Green" `
            -LogFile $LogfilePath -LogMessage "'$LogfilePath' already exists!"
        }

        # Create all subfolders.
        $camlQueryFolders = "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>1</Value></Eq></Where></Query></View>"
        $FolderCollection = Get-PnPListItem -List $DocumentLibraryName -Query $camlQueryFolders
        $FolderURLCollection = $FolderCollection | ForEach-Object { New-Object PSObject -Property @{ 'ServerRelativeUrl' = $_.FieldValues["FileRef"] } }

        foreach ($Folder in $FolderURLCollection) {
            $ToRemove = Get-PnPWeb | Select-Object -ExpandProperty ServerRelativeUrl
            $ToRemove = $ToRemove.Replace('/','\')
            $ToRemove = $ToRemove + "\" + $DocumentLibraryName

            try {
                $FolderPath = $DestFolder + $Folder.ServerRelativeUrl.Replace('/','\')
                $FolderPath = $FolderPath.Replace($ToRemove,"")
        
                if (![string]::IsNullOrEmpty($FolderPath)) {
                    if (!(Test-Path -Path $FolderPath)) {
                        New-Item $FolderPath -ItemType "Directory" | Out-Null
                        Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
                        -LogFile $LogfilePath -LogMessage "'$FolderPath' created!"
                    }
                }
            }catch {
                Save-Log -Timestamp $(Get-Date) -Type "[ERROR]"  -MsgForegroundColor "Red" `
                -LogFile $LogfilePath -LogMessage $_.Exception.Message
            }
        }
        
        Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
        -LogFile $LogfilePath -LogMessage "All subfolders have been created!"

        # Download files from the Document Library
        $camlQueryFiles = "<View Scope='RecursiveAll'><Query><Where><Eq><FieldRef Name='FSObjType' /><Value Type='Integer'>0</Value></Eq></Where></Query></View>"
        $FileCollection = Get-PnPListItem -List $DocumentLibraryName -Query $camlQueryFiles
        $FileURLCollection = $FileCollection | ForEach-Object { New-Object PSObject -Property @{ 'ServerRelativeUrl' = $_.FieldValues["FileRef"] } }

        foreach ($File in $FileURLCollection) {
            $ToRemove = Get-PnPWeb | Select-Object -ExpandProperty ServerRelativeUrl
            $ToRemove = $ToRemove.Replace('/','\')
            $ToRemove = $ToRemove + "\" + $DocumentLibraryName

            $FilePath = $DestFolder + $File.ServerRelativeUrl.Replace('/','\')
            $FilePath = $FilePath.Replace($ToRemove,"")

            try {
                $Filename = Get-PnPFile -ServerRelativeUrl $File.ServerRelativeUrl | Select-Object -ExpandProperty Name
                $FilePath = $FilePath.Replace($Filename,"")
        
                if (![string]::IsNullOrEmpty($FilePath)) {
                    Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
                    -LogFile $LogfilePath -LogMessage "'$FilePath$Filename' download started ..."

                    Get-PnPFile -Url $File.ServerRelativeUrl -AsFile -Path $FilePath -Filename $Filename -Force
                    
                    Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
                    -LogFile $LogfilePath -LogMessage "'$FilePath$Filename' downloaded!"
                }
            }
            catch {
                Save-Log -Timestamp $(Get-Date) -Type "[ERROR]"  -MsgForegroundColor "Red" `
                -LogFile $LogfilePath -LogMessage $_.Exception.Message
            }
        }

        Save-Log -Timestamp $(Get-Date) -Type "[INFO]"  -MsgForegroundColor "Green" `
        -LogFile $LogfilePath -LogMessage "All files have been downloaded!"
    }
    catch {
        Save-Log -Timestamp $(Get-Date) -Type "[ERROR]"  -MsgForegroundColor "Red" `
        -LogFile $LogfilePath -LogMessage $_.Exception.Message
    }
}