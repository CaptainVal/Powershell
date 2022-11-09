.Parameter domain
#Domain of AzureAD tenant
PARAM{
    [String]$domain
}

Get-AzureADUser -All $True | Where { $_.UserPrincipalName.ToLower().EndsWith("onmicrosoft.com") } |
ForEach {
 $newupn = $_.UserPrincipalName.Split("@")[0] + "@" + $domain
 Write-Host "Changing UPN value from: "$_.UserPrincipalName" to: " $newupn -ForegroundColor Yellow
 Set-AzureADUser -ObjectId $_.UserPrincipalName  -UserPrincipalName $newupn
}