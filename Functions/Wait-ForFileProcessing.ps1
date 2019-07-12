function Wait-ForFileProcessing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $fileUri, 
        [Parameter(Mandatory = $true)]
        $stage
    )

    $attempts = 600
    $waitTimeInSeconds = 10

    $successState = "$($stage)Success"
    $pendingState = "$($stage)Pending"
    #$failedState = "$($stage)Failed"
    #$timedOutState = "$($stage)TimedOut"

    $file = $null;
    while ($attempts -gt 0) {
        $file = Invoke-GetRequest $fileUri

        if ($file.uploadState -eq $successState) {
            break;
        }
        elseif ($file.uploadState -ne $pendingState) {
            throw "File upload state is not success: $($file.uploadState)"
        }

        Start-Sleep -Seconds $waitTimeInSeconds
        $attempts++
    }

    if ($null -eq $file) {
        throw "File request did not complete in the allotted time."
    }

    $file

}