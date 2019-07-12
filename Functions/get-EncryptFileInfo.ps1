Function Get-EncryptFileInfo {
    [cmdletbinding()]
    param (
        $metadataFile
    )
    try {
        if (Test-Path $metadataFile) {
            $xml = [xml](Get-Content $metadataFile)
            $encryptionInfo = [PSCustomObject]@{
                encryptionKey = $xml.ApplicationInfo.EncryptionInfo.encryptionKey
                macKey = $xml.ApplicationInfo.EncryptionInfo.macKey
                initializationVector = $xml.ApplicationInfo.EncryptionInfo.initializationVector
                mac = $xml.ApplicationInfo.EncryptionInfo.mac
                profileIdentifier = $xml.ApplicationInfo.EncryptionInfo.profileIdentifier
                fileDigest = $xml.ApplicationInfo.EncryptionInfo.fileDigest
                fileDigestAlgorithm = $xml.ApplicationInfo.EncryptionInfo.fileDigestAlgorithm
            }

            $fileEncryptionInfo = @{};
            $fileEncryptionInfo.fileEncryptionInfo = $encryptionInfo

            return $fileEncryptionInfo
        }
        else {
            throw "File not found: $metaData"
        }
        
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}