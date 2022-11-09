DistributionGroup

#takes a csv of Distribution Groups and removes them from Exchange
$groups = Import-CSV "empty dgs.csv"	
ForEach ($group in $groups)
	{
        $removed = Get-DistributionGroup -Identity $group.Address
        #Remove-DistributionGroup -Identity $group
        Write-Host "Removing Group: "$removed			
	}
