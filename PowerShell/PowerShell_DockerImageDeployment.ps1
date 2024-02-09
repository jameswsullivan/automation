# Automate Deployment steps.

# Global variables
# $FullTag = ""
# $RegistryURL = ""
$global:LogFilePath = ""
$global:LogMessage = ""
$global:Timestamp = ""

# Retrieve repository.
function Get-Repository {
    [CmdletBinding()]
    param (
        [Parameter()] [string] $GitRepoURL,
        [Parameter()] [string] $Branch
    )

    try {
        if ($Branch -eq "")
        {
            Write-Host -ForegroundColor Green "Begin downloading $GitRepoURL ..." $_.Exception.Message
            git clone $GitRepoURL
        }
        else {
            Write-Host -ForegroundColor Green "Begin downloading $GitRepoURL from Branch: $Branch ..." $_.Exception.Message
            git clone $GitRepoURL --branch $Branch
        }

        Get-ChildItem
    }
    catch {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }
}

# Build image.
function Build-Image {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $Repo,
        [Parameter(Mandatory=$true, HelpMessage="Which branch or commit to checkout?")] 
        [string] $BranchOrCommit,
        [Parameter(Mandatory=$true, HelpMessage="Full Repo URL for tagging: (e.g. myregistry.com/repo/name)")]
        [string] $RepoURL,
        [Parameter(Mandatory=$true, HelpMessage="Version tag: (e.g. 1.1.5-RC1)")]
        [string] $BuildVersion
    )

    try {

        cd .\$Repo

        $global:LogFilePath = pwd | Select-Object -ExpandProperty Path
        $global:Timestamp = Get-Date
        $global:Timestamp = $global:Timestamp.ToString("yyyyMMddHHmmss")
        $global:LogFilePath = $global:LogFilePath + "\" + $Repo + "_build_" + $BuildVersion + "_" + $global:Timestamp + ".log"
        New-Item $global:LogFilePath
                
        Write-Host -ForegroundColor Green "Run 'git checkout $BranchOrCommit': "
        $global:Timestamp = Get-Date
        $global:LogMessage = "Run 'git checkout $BranchOrCommit': " + $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
        git checkout $BranchOrCommit 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
        Write-Output $tempOut


        Write-Host -ForegroundColor Green "Run 'git status': "
        $global:Timestamp = Get-Date
        $global:LogMessage = "Run 'git status': " + $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
        git status 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
        Write-Output $tempOut


        Write-Host -ForegroundColor Green "Run 'git rev-parse HEAD': "
        $global:Timestamp = Get-Date
        $global:LogMessage = "Run 'git rev-parse HEAD': "+ $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
        git rev-parse HEAD 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
        Write-Output $tempOut

        cd ..
        

        Write-Host -ForegroundColor Green "Review the information above."
        Write-Host -ForegroundColor Green "Press any key to continue, or press ESC to terminate."
        
        $KeyPressed = [System.Console]::ReadKey($true)

        # Build image:
        if ($KeyPressed.Key -ne 'Escape')
        {
            $FullTag = $RepoURL + ":" + $BuildVersion
            Write-Host -ForegroundColor Green "Image: $FullTag will be built ..." $_.Exception.Message

            $global:Timestamp = Get-Date
            $global:LogMessage = "`r`nImage: $FullTag will be built ..." + $global:Timestamp
            Add-Content $global:LogFilePath $global:LogMessage

            # Clean Cache.
            docker system prune --force 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
            # Build image.
            docker image build --tag $FullTag --progress plain --no-cache .\$Repo 2>&1 | ForEach-Object { $_ | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII; Write-Output $_ }

            Write-Host -ForegroundColor Green "Build completed! Full image tag: "
            Write-Host -ForegroundColor Green $FullTag
            $global:Timestamp = Get-Date
            $global:LogMessage = $FullTag + " build completed! " + $global:Timestamp
            Add-Content $global:LogFilePath $global:LogMessage
    
            # Show docker images:
            Write-Host -ForegroundColor Green "'Docker images' : "
            $global:Timestamp = Get-Date
            $global:LogMessage = "`r`nDocker images: " + $global:Timestamp
            Add-Content $global:LogFilePath $global:LogMessage

            docker images 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
            Write-Output $tempOut
        }
        else {
            Write-Host -ForegroundColor Red "ESC was pressed. Build stopped."
            #return
        }
    }
    catch {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }
}

# Push to Registry
function Push-Image {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)] [string] $FullTag,
        [Parameter(Mandatory=$true, HelpMessage="Image registry URL: (e.g. myregistry.com)")]
        [string] $RegistryURL,
        [Parameter(Mandatory=$true)] [string] $UserName,
        [Parameter(Mandatory=$true)] [string] $Password
    )

    try {
        Write-Host -ForegroundColor Green "Login to Registry: 'docker login $RegistryURL' "
        $global:Timestamp = Get-Date
        $global:LogMessage = "Login to Registry: 'docker login $RegistryURL' " + $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
        docker login $RegistryURL --username $UserName --password $Password 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
        Write-Output $tempOut

        Write-Host -ForegroundColor Green "Pushing '$FullTag': "
        $global:Timestamp = Get-Date
        $global:LogMessage = "Pushing '$FullTag': " + $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
        docker push $FullTag 2>&1 | ForEach-Object { $_ | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII; Write-Output $_ }

        Write-Host -ForegroundColor Green "Push completed. Docker logout. 'docker logout $RegistryURL' "
        $global:Timestamp = Get-Date
        $global:LogMessage = "Push completed. Docker logout. 'docker logout $RegistryURL' " + $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
        docker logout $RegistryURL 2>&1 | Format-Table -AutoSize | Tee-Object -Variable tempOut | Out-File -FilePath $global:LogFilePath -Append -Encoding ASCII
        
        Write-Host -ForegroundColor Green "Process completed."
        $global:Timestamp = Get-Date
        $global:LogMessage = "Process completed." + $global:Timestamp
        Add-Content $global:LogFilePath $global:LogMessage
    }
    catch {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }
}

# Main function, provide a list of the repos.

function Deploy-Repo {
    
    # Add GitHub repos to $RepoCollection
    $RepoCollection = @()
    $RepoCollection += [PSCustomObject]@{
        Name = "repo name"
        URL = "https://github.com/sample/repo"
    }
    $RepoCollection += [PSCustomObject]@{
        Name = "repo name"
        URL = "https://github.com/sample/repo"
    }
    $RepoCollection += [PSCustomObject]@{
        Name = "repo name"
        URL = "https://github.com/sample/repo"
    }
    $RepoCollection += [PSCustomObject]@{
        Name = "repo name"
        URL = "https://github.com/sample/repo"
    }

    try {
        # Display a list of repo options
        for ($i = 0; $i -lt $RepoCollection.Length; ++$i) {
            $output = "[" + $i +"]: " + $RepoCollection[$i].Name + " - " + $RepoCollection[$i].URL
            Write-Host -ForegroundColor Green $output
        }

        # Wait for user to select a repo.
        $Selection = Read-Host "Select a repository or enter END to cancel"

        while (([int]::TryParse($Selection, [ref]$null) -lt 0) -or ([int]::TryParse($Selection, [ref]$null) -gt ($RepoCollection.Length - 1)) -or ([string]::IsNullOrEmpty($Selection)) -or (-not [int]::TryParse($Selection, [ref]$null))) {
            if ($Selection -eq "END") {
                Write-Host -ForegroundColor Red "Operation cancelled."
                return
            }
            $ErrorMessage = "No repo " + $Selection + " available, Select a repository or enter END to cancel."
            Write-Host -ForegroundColor Red $ErrorMessage $_.Exception.Message
            $Selection = Read-Host "Select a repository or enter END to cancel"
        }
        
        # Wait for user input for branch.
        $InputBranch = Read-Host "Enter the branch, or press Enter to use main"

        if ($InputBranch -ne "")
        {
            $Message = $RepoCollection[$Selection].Name + " - " + $RepoCollection[$Selection].URL + " branch " + $InputBranch + " will be downloaded."
            $Message += "`nPress any key to continue, or ESC to cancel."
            Write-Host -ForegroundColor Green $Message
        }
        else
        {
            $Message = $RepoCollection[$Selection].Name + " - " + $RepoCollection[$Selection].URL + " will be downloaded."
            $Message += "`nPress any key to continue, or ESC to cancel."
            Write-Host -ForegroundColor Green $Message
        }

        # Start git clone or cancel with ESC
        $KeyPressed = [System.Console]::ReadKey($true)

        if ($KeyPressed.Key -ne 'Escape')
        {
            $Message = "Repo is being downloaded ..."
            Get-Repository -GitRepoURL $RepoCollection[$Selection].URL -Branch $InputBranch
        }
        else {
            Write-Host -ForegroundColor Red "ESC was pressed, operation cancelled.."
            #return
        }

        # Start building image.
        $Message = "Build Image? Y to continue, N to cancel"
        $Confirmation = Read-Host $Message

        while (($Confirmation -ne "Y" -and $Confirmation -ne "N") -or [string]::IsNullOrEmpty($Selection)) {
            $ErrorMessage = "Incorrect input. Please try again."
            Write-Host -ForegroundColor Red $ErrorMessage
            $Confirmation = Read-Host $Message
        }

        if ($Confirmation -eq "Y")
        {
            Build-Image -Repo $RepoCollection[$Selection].Name
        }
        else {
            Write-Host -ForegroundColor Red "Operation cancelled."
            #return
        }

        # push image
        $Message = "Push Image? Y to continue, N to cancel."
        $Confirmation = Read-Host $Message

        while (($Confirmation -ne "Y" -and $Confirmation -ne "N") -or [string]::IsNullOrEmpty($Selection)) {
            $ErrorMessage = "Incorrect input. Please try again."
            Write-Host -ForegroundColor Red $ErrorMessage
            $Confirmation = Read-Host $Message
        }

        if ($Confirmation -eq "Y")
        {
            Push-Image
        }
        else {
        }

        # Save log files.
        $SavedLogPath = "D:\Logs"
        $Message = $global:LogFilePath + " saved to " + $SavedLogPath
        Copy-Item $global:LogFilePath -Destination $SavedLogPath
        Write-Host $Message
    }
    catch {
        Write-Host -ForegroundColor Red $_.Exception.Message
    }
}