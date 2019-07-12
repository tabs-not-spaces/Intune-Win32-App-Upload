[CmdletBinding()]
param (
    [Parameter(mandatory = $true)]
    [string]$un,
    
    [Parameter(mandatory = $true)]
    [string]$pw,
    
    [Parameter(mandatory = $true)]
    [string]$tenantId
)
#region load functions
Get-ChildItem $PSScriptRoot
$Functions = @(Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue)
# Dot source the functions required.
foreach ($f in $Functions) {
    try {
        . $f.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($f.FullName): $_"
    }
}
#endregion
$global:baseUrl = "https://graph.microsoft.com/beta/deviceAppManagement/"
$appPath = Split-Path $PSScriptRoot -Parent
$apps = Get-ChildItem -Path $appPath -Directory -Exclude "intunewin_deploy"
foreach ($a in $apps) {
    try {
        $appData = Get-Content $a\AppInfo.json -Raw | ConvertFrom-Json
        $sourceFile = (Get-ChildItem -Path "$a\*.intunewin").FullName
        if (!($appData -or $sourceFile)) {
            throw "Application config // binaries not found.."
        }
        #region Unattended Authentication
        $global:authParams = @{
            un       = $un
            pw       = $pw
            tenantId = $tenantId
            resource = "https://graph.microsoft.com"
            cId      = "d1ddf0e4-d672-4dae-b554-9d5bdfd93547"
        }
    
        $global:authToken = Get-UnattendedAuth @authParams
        $authToken
        #endregion
    
        #region Publish
        $params = @{
            sourceFile      = $sourceFile
            ApplicationInfo = $appData.ApplicationInfo
            ProgramInfo     = $appdata.ProgramInfo
            RequirementInfo = $appdata.RequirementInfo
            DetectionInfo   = ($appdata.DetectionInfo.DetectionTypes | Where-Object {$_.'@odata.type' -eq $appData.DetectionInfo.ChosenDetectionType})
            ReturnCodes     = $appdata.ReturnCodes
        }
        Publish-Win32Lob @params
        #endregion
    }
    catch {
        Write-Warning $_.Exception.Message
        Return $false
    }
}