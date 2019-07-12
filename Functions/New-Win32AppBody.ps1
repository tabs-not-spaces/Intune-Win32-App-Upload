function New-Win32AppBody {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ApplicationInfo,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ProgramInfo,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$RequirementInfo,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$DetectionInfo,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ReturnCodes
    )

    #build the hashtable
    $body = [ordered]@{}
    $body.'@odata.type' = "#microsoft.graph.win32LobApp"

    #add the parts..
    #Application
    $body.displayName = $ApplicationInfo.Name
    $body.description = $ApplicationInfo.Description
    $body.publisher = $ApplicationInfo.publisher
    $body.categories = @()
    $body.isFeatured = $false
    $body.informationUrl = $null
    $body.privacyInformationUrl = $null
    $body.developer = $ApplicationInfo.Developer 
    $body.owner = ""
    $body.notes = ""
    $body.largeIcon = $null
    
    #Program
    $body.installCommandLine = $ProgramInfo.InstallCommandLine
    $body.uninstallCommandLine = $ProgramInfo.uninstallCommandLine
    $body.installExperience = [PSCustomObject]@{
        "@odata.type" = "#microsoft.graph.win32LobAppInstallExperience"
        "runAsAccount" = $programInfo.RunAsContext
    }
    
    #Requirements
    if (!($requirementInfo.MinimumOS.'@odata.type')) {
        $RequirementInfo.MinimumOS | Add-Member -MemberType NoteProperty -Name "@odata.type" -Value "#microsoft.graph.windowsMinimumOperatingSystem"
    }
    $body.applicableArchitectures = $RequirementInfo.OSarchitecture
    $body.minimumSupportedOperatingSystem = $requireMentInfo.MinimumOS
    $body.minimumFreeDiskSpaceInMB = $null
    $body.minimumMemoryInMB = $null
    $body.minimumNumberOfProcessors = $null
    $body.minimumCpuSpeedInMHz = $null
    
    #Detection
    $body.detectionRules = @($DetectionInfo)
    
    #Return Codes
    $body.returnCodes = @($ReturnCodes)

    #Scope
    $body.roleScopeTagIds = @()
    
    #Misc
    $body.fileName = $(Split-Path $SourceFile -Leaf)
    $body.msiInformation = $null
    $body.runAs32Bit = $false
    $body.setupFilePath = $ProgramInfo.SetupFilePath

    return $body
}