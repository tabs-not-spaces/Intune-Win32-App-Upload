function Get-UnattendedAuth {
    param (
        [Parameter(mandatory = $true)]
        [string]$un,
        [Parameter(mandatory = $true)]
        [string]$pw,
        [Parameter(mandatory = $true)]
        [string]$cid,
        [Parameter(mandatory = $true)]
        [string]$resourceURL,
        [Parameter(mandatory = $true)]
        [string]$tenantId,
        [Parameter(mandatory = $false)]
        [string]$refresh
    )
    if ($refresh) {
        $body = @{
            resource   = $resourceURL
            client_id  = $cid
            grant_type = "refresh_token"
            username   = $un
            scope      = "openid"
            password   = $pw
            refresh_token = $refresh
        }
    }
    else {
        $body = @{
            resource   = $resourceURL
            client_id  = $cid
            grant_type = "password"
            username   = $un
            scope      = "openid"
            password   = $pw
        }
    }
    $response = Invoke-RestMethod -Method post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/token" -Body $body
    $headers = @{}
    $headers.Add("Authorization", "Bearer " + $response.access_token)
    return $response
}