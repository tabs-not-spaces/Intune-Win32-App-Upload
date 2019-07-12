function Publish-Win32Lob{

<#
.SYNOPSIS
This function is used to upload an MSI LOB Application to the Intune Service
.DESCRIPTION
This function is used to upload an MSI LOB Application to the Intune Service
.EXAMPLE
Publish-Win32Lob -SourceFile "C:\bin\apppackage.intunewin"
.NOTES
NAME: Upload-Win32Lob
#>

    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]$SourceFile,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ApplicationInfo,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ProgramInfo,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$RequirementInfo,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DetectionInfo,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$ReturnCodes
    )

	try	{

        $LOBType = "microsoft.graph.win32LobApp"

        Write-Host "Testing if SourceFile '$SourceFile' Path is valid..." -ForegroundColor Yellow
        Test-SourceFile $SourceFile

        #expand the *.intunewin file to capture the encryption
        Write-Host
        Write-Host "Expanding '$SourceFile' to grab metadata ..." -ForegroundColor Yellow
        $tempPath = "$(split-path $sourceFile -Parent)\temp"
        $zipFile = $sourceFile.Replace(".intunewin",".zip")
        Rename-Item $sourceFile -NewName $zipFile
        Expand-Archive -Path $zipFile -DestinationPath $tempPath -Force
        $expSourceFile = (Get-ChildItem "$tempPath\IntuneWinPackage\Contents\*.intuneWin").FullName
        $expMetadataFile = (Get-ChildItem "$tempPath\IntuneWinPackage\Metadata\Detection.xml").FullName
        
        # Encrypt file and Get File Information
        Write-Host
        Write-Host "Gathering encryption info for the file '$sourceFile'..." -ForegroundColor Yellow
        $encryptionInfo = get-EncryptFileInfo -metadataFile $expMetadataFile
        Rename-Item $zipFile -NewName $sourceFile
        [int64]$encSize = (Get-Item "$expSourceFile").Length
        [int64]$size = ([xml](Get-Content $expMetadataFile)).applicationInfo.UnencryptedContentSize

        Write-Host
        Write-Host "Creating JSON data to pass to the service..." -ForegroundColor Yellow

        $encFileName = Split-Path $expSourceFile -Leaf
#
        #$mobileAppBody = New-Win32AppBody -displayName "$displayName" -publisher "$publisher" -description "$description" -filename "$encFileName"
        $mobileAppBody = New-Win32AppBody -SourceFile $sourceFile -ApplicationInfo $ApplicationInfo -ProgramInfo $ProgramInfo -RequirementInfo $RequirementInfo -DetectionInfo $DetectionInfo -ReturnCodes $ReturnCodes
                 
        Write-Host
        Write-Host "Creating application in Intune..." -ForegroundColor Yellow
		$mobileApp = Invoke-PostRequest "mobileApps" ($mobileAppBody | ConvertTo-Json)

		# Get the content version for the new app (this will always be 1 until the new app is committed).
        Write-Host
        Write-Host "Creating Content Version in the service for the application..." -ForegroundColor Yellow
		$appId = $mobileApp.id
		$contentVersionUri = "mobileApps/$appId/$LOBType/contentVersions"
        $contentVersion = Invoke-PostRequest $contentVersionUri "{}"

		# Create a new file for the app.
        Write-Host
        Write-Host "Creating a new file entry in Azure for the upload..." -ForegroundColor Yellow
		$contentVersionId = $contentVersion.id;
        $fileBody = Get-AppFileBody -name $encFileName -size $Size -sizeEncrypted $encSize
		$filesUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files"
		$file = Invoke-PostRequest $filesUri ($fileBody | ConvertTo-Json)
	
		# Wait for the service to process the new file request.
        Write-Host
        Write-Host "Waiting for the file entry URI to be created..." -ForegroundColor Yellow
		$fileId = $file.id
		$fileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId"
		$file = Wait-ForFileProcessing $fileUri "AzureStorageUriRequest"

		# Upload the content to Azure Storage.
        Write-Host
        Write-Host "Uploading file to Azure Storage..." -f Yellow

		#$sasUri = $file.azureStorageUri
		Publish-FileToAzureStorage -sasUri $file.azureStorageUri -filepath $expSourceFile -RenewSASURI "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId/renewUpload"

		# Commit the file.
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitFileUri = "mobileApps/$appId/$LOBType/contentVersions/$contentVersionId/files/$fileId/commit"
		Invoke-PostRequest $commitFileUri ($encryptionInfo | ConvertTo-Json)

		# Wait for the service to process the commit file request.
        Write-Host
        Write-Host "Waiting for the service to process the commit file request..." -ForegroundColor Yellow
		$file = Wait-ForFileProcessing $fileUri "CommitFile"

		# Commit the app.
        Write-Host
        Write-Host "Committing the file into Azure Storage..." -ForegroundColor Yellow
		$commitAppUri = "mobileApps/$appId"
        $commitAppBody = Get-AppCommitBody $contentVersionId $LOBType
        # Found if I run the commit patch too fast I get a 504 timeout error, so putting in a sleep command for now.
        Start-Sleep -Seconds 5
		Invoke-PatchRequest $commitAppUri ($commitAppBody | ConvertTo-Json)

        Write-Host "Removing Temporary expanded files '$tempPath'..." -f Gray
        Remove-Item -Path "$tempPath" -Recurse -Force
        Write-Host

        Write-Host "Sleeping for 5 seconds to allow patch completion..." -f Magenta
        Start-Sleep -Seconds 5
        Write-Host

	}
	
    catch {

		Write-Host ""
		Write-Host -ForegroundColor Red "Aborting with exception: $($_.Exception.ToString())"
	
    }

}