# Delete SharePoint 2019 subsites.
# Use: DeleteSubsite("site_url_to_be_deleted")
$UserName = "your_username"
$Password = ConvertTo-SecureString "your_password" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username,$Password)

New-Item -Path . -Name "SubsiteDeletion.log"
function DeleteSubsite($SiteUrl) {
    Connect-PnPOnline -Url $SiteUrl -Credentials $Cred
    $SiteID = (Get-PnPWeb).Id
    Remove-PnPWeb -Identity $SiteID -Force
    $Timestamp = Get-Date
    Add-Content SubsiteDeletion.log "Deletion of $SiteUrl - $SiteID completed on $Timestamp"
}