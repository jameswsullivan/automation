# This script downloads entire SharePoint document libraries to your current working directory.
# Environment: SharePoint 2019 on-prem installation.

# Set up login credentials.
$UserName = "your_username"
$Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username,$Password)

# Get list of site contents.
# Use: Get-SiteContent -SiteURL "full_site_url_here"
function Get-SiteContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $SiteURL
    )

    Connect-PnPOnline -URL $SiteURL -Credentials $Cred
    Get-PnPList
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
            Write-Host -ForegroundColor Green "$DestFolder created!" $_.Exception.Message
        }

        $LogfilePath = $DestFolder + "\DownloadLog.log"
        if (!(Test-Path -Path $LogfilePath))
        {
            # Create a log file to log each steps taken.
            New-Item -Path $DestFolder -Name "DownloadLog.log" -ItemType "File" -Force | Out-Null
            $Timestamp = Get-Date
            Write-Host -ForegroundColor Green "'$LogfilePath' created!" $_.Exception.Message
            Add-Content $LogfilePath "$Timestamp - '$LogfilePath' created."
        }

        # Get all files.
        $FileCollection = Get-PnPFolderItem -FolderSiteRelativeUrl $DocumentLibraryName -ItemType File -Recursive | Select-Object ServerRelativeUrl
        $DestFileName = $DocumentLibraryName + " - Files.csv"
        $FileCollection | Export-Csv -Path .\$DestFolder\$DestFileName

        Write-Host -ForegroundColor Green `
        "Files from '$DocumentLibraryName' successfully retrieved!" `
        $_.Exception.Message

        $Timestamp = Get-Date
        Add-Content $LogfilePath "$Timestamp - File List retrieved. '$DestFileName'."


        # Get all folders.
        $FolderCollection = Get-PnPFolderItem -FolderSiteRelativeUrl $DocumentLibraryName -ItemType Folder -Recursive | Select-Object ServerRelativeUrl
        $DestFileName = $DocumentLibraryName + " - Folders.csv"
        $FolderCollection | Export-Csv -Path .\$DestFolder\$DestFileName

        Write-Host -ForegroundColor Green `
        "Folders from '$DocumentLibraryName' successfully retrieved!" `
        $_.Exception.Message

        $Timestamp = Get-Date
        Add-Content $LogfilePath "$Timestamp - Folder List retrieved. '$DestFileName'."
    }
    catch {
        Write-Host -ForegroundColor Red `
        "Error retrieving list of files and folders: " `
        $_.Exception.Message
    }
}

# Download a Document Library to current working directory.
# Use: Download-DocumentLibrary -DocumentLibraryName "Document_Library_Name"
function Download-DocumentLibrary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $DocumentLibraryName
    )

    Try {

        # Create folder for the Document Library. e.g. ".\SiteName - DocumentLibraryName"
        $SiteName = Get-PnPWeb | Select-Object -ExpandProperty Title
        $DestFolder = ".\" + $SiteName + " - " + $DocumentLibraryName
            
        if (!(Test-Path -Path $DestFolder)) {
            New-Item $DestFolder -Type Directory | Out-Null
            Write-Host -ForegroundColor Green "'$DestFolder' created!" $_.Exception.Message
        }

        # Create a log file to log each step taken.
        $LogfilePath = $DestFolder + "\DownloadLog.log"
        if (!(Test-Path -Path $LogfilePath))
        {
            New-Item -Path $DestFolder -Name "DownloadLog.log" -ItemType "File" -Force | Out-Null
            $Timestamp = Get-Date
            Write-Host -ForegroundColor Green "'$LogfilePath' created!" $_.Exception.Message
            Add-Content $LogfilePath "$Timestamp - '$LogfilePath' created."
        }

        # Create all subfolders.        
        $FolderCollection = Get-PnPFolderItem -FolderSiteRelativeUrl $DocumentLibraryName -ItemType Folder -Recursive | Select-Object ServerRelativeUrl
        foreach ($Folder in $FolderCollection) {
            $ToRemove = Get-PnPWeb | Select-Object -ExpandProperty ServerRelativeUrl
            $ToRemove = $ToRemove.Replace('/','\')
            $ToRemove = $ToRemove + "\" + $DocumentLibraryName

            $FolderPath = $DestFolder + $Folder.ServerRelativeUrl.Replace('/','\')
            $FolderPath = $FolderPath.Replace($ToRemove,"")

            if (![string]::IsNullOrEmpty($FolderPath))
            {
                if (!(Test-Path -Path $FolderPath))
                {
                    New-Item $FolderPath -ItemType "Directory" | Out-Null
                    $Timestamp = Get-Date
                    Write-Host -ForegroundColor Green "'$FolderPath' created!" $_.Exception.Message
                    Add-Content $LogfilePath "$Timestamp - '$FolderPath' created."
                }
            }
        }
        Write-Host -ForegroundColor Green "All subfolders have been created!" $_.Exception.Message
        $Timestamp = Get-Date
        Add-Content $LogfilePath "$Timestamp - All subfolders have been created."

        # Download files from the Document Library
        $FileCollection = Get-PnPFolderItem -FolderSiteRelativeUrl $DocumentLibraryName -ItemType File -Recursive | Select-Object ServerRelativeUrl
        foreach ($File in $FileCollection)
        {
            $ToRemove = Get-PnPWeb | Select-Object -ExpandProperty ServerRelativeUrl
            $ToRemove = $ToRemove.Replace('/','\')
            $ToRemove = $ToRemove + "\" + $DocumentLibraryName

            $FilePath = $DestFolder + $File.ServerRelativeUrl.Replace('/','\')
            $FilePath = $FilePath.Replace($ToRemove,"")

            $Filename = Get-PnPFile -ServerRelativeUrl $File.ServerRelativeUrl | Select-Object -ExpandProperty Name
            $FilePath = $FilePath.Replace($Filename,"")

            if (![string]::IsNullOrEmpty($FilePath))
            {
                try {
                    Get-PnPFile -Url $File.ServerRelativeUrl -AsFile -Path $FilePath -Filename $Filename -Force
                    $Timestamp = Get-Date
                    Write-Host -ForegroundColor Green "'$FilePath$Filename' downloaded..." $_.Exception.Message
                    Add-Content $LogfilePath "$Timestamp - '$FilePath$Filename' downloaded."
                }
                catch {
                    Write-Host -ForegroundColor Red `
                    "Error Downloading $File.ServerRelativeurl" `
                    $_.Exception.Message
                    Add-Content $LogfilePath "$Timestamp - '$FilePath$Filename' download failed with Exception: $_.Exception.Message"
                }
            }
        }
        Write-Host -ForegroundColor Green "All files have been downloaded!" $_.Exception.Message
        $Timestamp = Get-Date
        Add-Content $LogfilePath "$Timestamp - All files have been download."
    }
    Catch {
        Write-Host -ForegroundColor Red `
        "Error Downloading '$DocumentLibraryName': " `
        $_.Exception.Message
    }
}