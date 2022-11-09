.Parameter Domain
#New UPN domain
PARAM{
    [String]$Domain
}

$Users = Get-ADUser -Filter * -SearchBase "Enter OU" | select SamAccountName

foreach ($User in $Users){
    
    $upn = $User.SamAccountName + "@" + $Domain
    Get-ADUser $User.SamAccountName | Set-ADUser -UserPrincipalName $upn
    

}

