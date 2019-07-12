Function Test-SourceFile{
param
(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $SourceFile
)
    try {
            if(!(test-path "$SourceFile")){
            Write-Host "Source File '$sourceFile' doesn't exist..." -ForegroundColor Red
            throw
            }
        }
    catch {
		Write-Host -ForegroundColor Red $_.Exception.Message;
        Write-Host
		break
    }
}