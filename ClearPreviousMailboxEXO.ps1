$Users = Get-User
foreach ($user in $Users){
    if ($user.RecipientType -eq "User"){
        Set-User $user.Name -PermanentlyClearPreviousMailboxInfo -Confirm:$false
        Write-Output $user.Name + "Mailbox Removed" 
    }
}