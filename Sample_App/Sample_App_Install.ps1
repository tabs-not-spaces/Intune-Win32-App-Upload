#region config
$client = "contoso"
$appName = "sampleapp"
$logPath = "$ENV:ProgramData\$client"
$logFile = "$logPath\$appname.log"
#endregion
#region logging
if (!(Test-Path $logPath -ErrorAction SilentlyContinue)) {
    New-Item $LogPath -ItemType Directory -Force | Out-Null
    Start-Transcript $logFile -Force
}
#endregion
#region process
Write-Host "Hello World.."
Start-Sleep -Seconds 5
Write-Host "Moving some files around.."
Copy-Item "$PSScriptRoot\ChromeSetup.exe" -Destination $logPath
Write-Host "Goodbye World.."
Stop-Transcript
#endregion