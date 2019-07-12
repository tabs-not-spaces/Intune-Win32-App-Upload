function Publish-FileToAzureStorage {
    [cmdletbinding()]
    param (
        $sasUri, 
        $filepath, 
        $RenewSASURI
    )

    # Set up chunk sizes
    # Set up a timeout limit and start a diag stopwatch
    $chunkSizeInBytes = 4mb
    $timeout = new-timespan -Minutes 10
    $sw = [diagnostics.stopwatch]::StartNew()
	
    # Read the whole file and find the total chunks.
    #[byte[]]$bytes = Get-Content $filepath -Encoding byte
    # Using ReadAllBytes method as the Get-Content used alot of memory on the machine
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($filepath);
    $chunks = [Math]::Ceiling($bytes.Length / $chunkSizeInBytes);

    # Upload each chunk.
    $ids = @();
    $cc = 1

    for ($chunk = 0; $chunk -lt $chunks; $chunk++) {

        $id = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($chunk.ToString("0000")))
        $ids += $id

        $start = $chunk * $chunkSizeInBytes
        $end = [Math]::Min($start + $chunkSizeInBytes - 1, $bytes.Length - 1)
        $body = $bytes[$start..$end]

        Write-Progress -Activity "Uploading File to Azure Storage" -status "Uploading chunk $cc of $chunks" -percentComplete ($cc / $chunks * 100)
        Write-Host "Uploading chunk $cc of $chunks | $([math]::Round($cc / $chunks*100))% | $($sw.Elapsed.ToString())"
        $cc++
        if ($sw.elapsed -ge $timeout) {
            Write-Host "Timer has run out - let's check how our authentication is looking.."
            #$RenewSASURI = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId/renewUpload"
            if ($global:authToken) {
                # Setting DateTime to Universal time to work in all timezones
                Write-Host "Setting DateTime to Universal time to work in all timezones"
                $dateTime = (Get-Date).ToUniversalTime()
                # If the authToken exists checking when it expires
                Write-Host "If the authToken exists checking when it expires"
                $tokenExpires = ((Get-Date 1/1/1970).AddSeconds($global:authToken.expires_on) - $dateTime).Minutes
                if ($tokenExpires -le 1) {
                    Write-Host "Authentication Token expired $TokenExpires minutes ago" -ForegroundColor Yellow
                    Write-Host
                    $global:authToken = Get-UnattendedAuth @global:authParams -refresh $global:authToken.refresh_token
                }
                else {
                    Write-Host "Token is good, expires in $tokenExpires minutes.."
                }
            }
            Write-Host "Renewing the SASURI.."
            $renewSAS = Invoke-PostRequest $RenewSASURI
            Write-Host "10 minutes back on the clock.."
            $sw.reset()
        }
        $uploadResponse = Publish-AzureStorageChunk $sasUri $id $body;
		
    }

    Write-Progress -Completed -Activity "Uploading File to Azure Storage"

    Write-Host

    # Finalize the upload.
    $uploadResponse = Invoke-FinalizeAzureStorageUpload $sasUri $ids
    $uploadResponse
}