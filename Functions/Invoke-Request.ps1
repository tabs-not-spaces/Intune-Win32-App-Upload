function Invoke-Request{
	[CmdletBinding()]
	param (
		$verb, 
		$collectionPath, 
		$body
	)

	$uri = "$baseUrl$collectionPath";
	$request = "$verb $uri"

	$clonedHeaders = @{}
	$clonedHeaders.Authorization = "$($authToken.token_type) $($authToken.access_token)"
	$clonedHeaders.'content-length' = $body.Length
	$clonedheaders.'content-type' = "application/json"

	try
	{
		if($body){
		$response = Invoke-RestMethod $uri -Method $verb -Headers $clonedHeaders -Body $body;
		$response;
		}
		else {
			$response = Invoke-RestMethod $uri -Method $verb -Headers $clonedHeaders
			$response;
		}
	}
	catch
	{
		Write-Host -ForegroundColor Red $request;
		Write-Host -ForegroundColor Red $_.Exception.Message;
		throw;
	}
}


