function Invoke-PatchRequest($collectionPath, $body){

	Invoke-Request "PATCH" $collectionPath $body;

}