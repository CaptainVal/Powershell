.Parameter SiteURL
#URL of sharepoint site to check size of
PARAM{
    [String]$SiteURL
}
$ListName = "Shared Documents"
$CSVFile = "C:\Temp\FolderSize.csv"
 
Try {
    #Connect to PnP Online
    Connect-PnPOnline -Url $SiteURL -Interactive
     
    #Get all folders from the document library
    $Folders = Get-PnPListItem -List $ListName -PageSize 2000 | Where { $_.FileSystemObjectType -eq "Folder" }
     
    #Calculate Folder Size from files
    $FolderSizeData = @()
    $Folders | ForEach-Object {
        #Extract Folder Size data
        $FolderSizeData += New-Object PSObject -Property  ([Ordered]@{
            "Folder Name"  = $_.FieldValues.FileLeafRef
            "URL" = $_.FieldValues.FileRef        
            "Size" = $_.FieldValues.SMTotalSize.LookupId
        })
    }
    $FolderSizeData | Format-Table
    $FolderSizeData | Export-csv $CSVFile -NoTypeInformation
    #Calculate the Total Size of Folders
    $FolderSize = [Math]::Round((($FolderSizeData | Measure-Object -Property "Size" -Sum | Select-Object -expand Sum)/1KB),2)
    Write-host -f Green ("Total Size: {0}" -f $FolderSize)
} 
Catch {
    Write-Host -f Red "Error:"$_.Exception.Message
}