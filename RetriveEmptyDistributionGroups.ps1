$emptyGroups = foreach ($grp in Get-DistributionGroup -ResultSize Unlimited) {
    $size=(Get-DistributionGroupMember -Identity $grp.DistinguishedName -ResultSize Unlimited).Count
    if ($size -eq 0) 
        {
        [PsCustomObject]@{
            DisplayName        = $grp.DisplayName
            PrimarySMTPAddress = $grp.PrimarySMTPAddress
            DistinguishedName  = $grp.DistinguishedName
        }
        }
    else{}   
}
$emptyGroups | Export-Csv 'C:\Users\177626\DLsToRemove4.csv' -NoTypeInformation