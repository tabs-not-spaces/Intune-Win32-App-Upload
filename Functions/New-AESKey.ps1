function New-AESKey {
    try {
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aesProvider = New-Object System.Security.Cryptography.AesCryptoServiceProvider
        $aesProvider.GenerateKey()
        $aesProvider.Key
	}
	catch {
		Write-Warning $_.Exception.Message
	}
    finally {
        if ($aesProvider) { 
			$aesProvider.Dispose() 
		}
		if ($aes) { 
			$aes.Dispose() 
		}
    }
}