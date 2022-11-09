.Parameter SiteURL
#URL of sharepoint site to limit versions

.Parameter Versions

PARAM{
    [String]$SiteURL,
    [Int]$Versions
}
 
#Connect to PnP Online
Connect-PnPOnline -Url $SiteURL -Credentials (Get-Credential)
 
#Get All Lists from the web
$Lists = Get-PnPList | Where {$_.Hidden -eq $false}
ForEach($List in $Lists)
{ 
    #Enable versioning and set Number of versions to input variable
    Set-PnPList -Identity $List -EnableVersioning $True -MajorVersions $Versions
    Write-host -f Yellow "Configured Versioning on List:"$List.Title
}