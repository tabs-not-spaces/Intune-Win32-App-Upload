function Get-AppFileBody{
	[CmdletBinding()]
	param (
		$name, 
		$size, 
		$sizeEncrypted, 
		$manifest
	)

	$body = @{ "@odata.type" = "#microsoft.graph.mobileAppContentFile" }
	$body.name = $name
	$body.size = $size
	$body.sizeEncrypted = $sizeEncrypted
	if (!($manifest)) {
		$body.manifest = $null
	}
	else {
		$body.manifest = $manifest
	}

	return $body
}