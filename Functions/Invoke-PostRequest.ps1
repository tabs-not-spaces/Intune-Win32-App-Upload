function Invoke-PostRequest($collectionPath, $body){

	Invoke-Request "POST" $collectionPath $body;

}