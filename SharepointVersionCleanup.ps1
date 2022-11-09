Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue
  
.Parameter SiteURL
#URL of sharepoint site to check size of
PARAM{
    [String]$SiteURL
}

#Configuration Parameters
$ListName = "Documents"
 
#Get the Web, List objects
$Web= Get-SPWeb $SiteURL
$List= $web.Lists[$ListName]
 
#Get all Items from the List
$ListItems = $List.Items
Write-host "Total Items Found in the List:"$List.ItemCount
$Counter =0
 
#Iterate through each item
foreach ($ListItem  in $ListItems)
{
    #Display Progress bar
    $Counter=$Counter+1    
     Write-Progress -Activity "Cleaning up versions" -Status "Processing Item:$($ListItem['Name']) $($counter) of $($List.ItemCount)" -PercentComplete $($Counter/$List.ItemCount*100)
      
    #If the File has versions, clean it up
    if ($ListItem.Versions.Count -gt 1)
    { 
        Write-host "Cleaning versions for: " $ListItem["Name"]
        $ListItem.file.Versions.DeleteAll()
    }
}