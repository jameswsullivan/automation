# This script exports SharePoint calendars to CSV files and gets them ready for importing into Outlook.
# The script is best suited for migrating SharePoint calendars to other platforms. (e.g. SharePoint Calendar -> CSV -> Outlook Calendar -> Save Outlook calendars to iCalendar .ics format -> import to other platforms)
# Environment: SharePoint 2019 on-prem installation.

# Set up login credentials.
$UserName = "your_username"
$Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username,$Password)


# List all "Lists" of a subsite.
# Use: Get-SiteLists -SiteURL "full_site_url_here"
function Get-SiteLists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $SiteURL
    )

    try {
        Connect-PnPOnline -URL $SiteURL -Credentials $Cred
        $SiteName = Get-PnPWeb | Select-Object -ExpandProperty Title
        $SiteFolderPath = ".\" + $SiteName

        # Create folder based on Site/Subsite name.
        if (!(Test-Path -Path $SiteFolderPath))
        {
            New-Item $SiteFolderPath -ItemType Directory | Out-Null
            Write-Host -ForegroundColor Green "Site folder $SiteFolderPath created." $_.Exception.Message
        }

        # Create log file.
        $LogFilePath = $SiteFolderPath + "\log.log"
        if (!(Test-Path -Path $LogFilePath))
        {
            New-Item $LogFilePath -ItemType File | Out-Null
            Write-Host -ForegroundColor Green "Log file '$LogFilePath' created." $_.Exception.Message
            $Timestamp = Get-Date
            Add-Content $LogFilePath "$Timestamp - '$SiteFolderPath' created."
            Add-Content $LogFilePath "$Timestamp - '$LogFilePath' created."
        }
    
        # Get all lists.
        $ListCollection = Get-PnPList | Where-Object {$_.BaseType -eq "GenericList"} | Select-Object Title,DefaultViewUrl,Id,ParentWebUrl
        $ListCollectionFileName = $SiteFolderPath + "\Lists.csv"
        $ListCollection | Export-Csv -Path $ListCollectionFileName
        $Timestamp = Get-Date
        Write-Host -ForegroundColor Green "'$ListCollectionFileName' exported." $_.Exception.Message
        Add-Content $LogFilePath "$Timestamp - '$ListCollectionFileName' exported."

        $ListCollection | Select-Object Title,Id
    }
    catch {
        Write-Host -ForegroundColor Red `
        "Error retrieving Lists from '$SiteName': " `
        $_.Exception.Message
    }
}

# Get List Events from a List/Calendar
# Use: Get-CalendarEvents -CalendarName "Calendar_Name"
function Get-CalendarEvents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $CalendarName,
        [Parameter(Mandatory=$true)] [string] $ExportFileName
    )

    try {
        $SiteName = Get-PnPWeb | Select-Object -ExpandProperty Title
        $SiteFolderPath = ".\" + $SiteName
        $LogFilePath = $SiteFolderPath + "\log.log"

        # Get all events of the Calendar/List
        $EventCollection = Get-PnPListItem -List $CalendarName
        $EventDetailsCollection = @()

        foreach ($event in $EventCollection) {
            $EventDetailsCollection += New-Object PSObject -Property @{
                Subject = $event.FieldValues.Title
                Location = $event.FieldValues.Location
                "Start Date" = $event.FieldValues.EventDate.ToString("MM/dd/yyyy")
                "Start Time" = $event.FieldValues.EventDate.ToString("hh:mm:ss tt")
                "End Date" = $event.FieldValues.EndDate.ToString("MM/dd/yyyy")
                "End Time" = $event.FieldValues.EndDate.ToString("hh:mm:ss tt")
                "All day event" = if ($event.FieldValues.fAllDayEvent) {$true} else {$false}
                Description = [System.Web.HttpUtility]::HtmlDecode([System.Web.HttpUtility]::HtmlDecode($event.FieldValues.Description))
                "Meeting Organizer" = $event.FieldValues.Author.LookupValue
                "Required Attendees" = (($event.FieldValues.EmailTo -replace '&lt;', '<') -replace '&gt;', '>')
            }
        }

        $CalendarFilePathUTF8BOM = $SiteName + "\" + $ExportFileName + " - UTF8withBOM" + ".csv"

        $EventDetailsCollection = $EventDetailsCollection | Select-Object Subject,Location,"Start Date","Start Time","End Date","End Time","All day event",Description,"Meeting Organizer","Required Attendees"
        $EventDetailsCollection | Export-csv -Path $CalendarFilePathUTF8BOM -NoTypeInformation -Encoding UTF8

        $Timestamp = Get-Date
        Add-Content $LogFilePath "$Timestamp - '$CalendarFilePathUTF8BOM' exported."

        # Convert UTF8 with BOM to UTF8 without BOM.
        $CalendarFilePathUTF8 = $SiteName + "\" + $ExportFileName + ".csv"

        $CurrentWorkingPath = Get-Location | Select-Object -ExpandProperty Path
        $CalendarFilePathUTF8BOM = $CurrentWorkingPath + "\" + $CalendarFilePathUTF8BOM
        $CalendarFilePathUTF8 = $CurrentWorkingPath + "\" + $CalendarFilePathUTF8

        $contentBytes = [System.Io.File]::ReadAllBytes($CalendarFilePathUTF8BOM)
        $preambleLength = [System.Text.Encoding]::UTF8.GetPreamble().Length
        if (($preambleLength -gt 0) -and ($contentBytes[0] -eq 0xEF) -and ($contentBytes[1] -eq 0xBB -and $contentBytes[2] -eq 0xBF)) {
            $contentBytes = $contentBytes[$preambleLength..($contentBytes.Length - 1)]
        }
        [System.IO.File]::WriteAllBytes($CalendarFilePathUTF8, $contentBytes)

        $Timestamp = Get-Date
        Add-Content $LogFilePath "$Timestamp - UTF8 version of file '$CalendarFilePathUTF8' is created."
    }
    catch {
        Write-Host -ForegroundColor Red `
        "Error retrieving event details from '$CalendarName' : " `
        $_.Exception.Message
    }
    finally {
    }
}


# Show calendar event's FieldValues.
# Used for generating a list of FieldValues for reference in the Get-CalendarEvents cmdlet.
# Use: Get-CalendarEventSample -CalendarName "Calendar_Name"
function Get-CalendarEventSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $CalendarName
    )

    try {
        $EventCollection = Get-PnPListItem -List $CalendarName
        foreach ($event in $EventCollection) {
            $event.FieldValues | Tee-Object .\SampleEvent.txt | Out-Null
            $event.FieldValues.Author.LookupValue
            break
        }
    }
    catch {
        Write-Host -ForegroundColor Red `
        "Error retrieving event details from '$CalendarName' : " `
        $_.Exception.Message
    }
}