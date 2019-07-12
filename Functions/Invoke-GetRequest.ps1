function Invoke-GetRequest($collectionPath){

	$uri = "$baseUrl$collectionPath";
	$request = "GET $uri";
	
	$clonedHeaders = @{}
	$clonedHeaders.Authorization = "$($authToken.token_type) $($authToken.access_token)"
	$clonedHeaders.'content-length' = $body.Length
	$clonedheaders.'content-type' = "application/json"

	try
	{
		$response = Invoke-RestMethod $uri -Method Get -Headers $clonedHeaders;
		$response;
	}
	catch
	{
		Write-Host -ForegroundColor Red $request;
		Write-Host -ForegroundColor Red $_.Exception.Message;
		throw;
	}
}