$mailboxes = Get-Mailbox
$dgs = Get-DistributionGroup

.Parameter ValidDomains 
#Domains to check email addresses against.
PARAM{
    [array]$ValidDomains
}

foreach ($mailbox in $mailboxes){
    $primsmtp = $mailbox.PrimarySmtpAddress

#Loop through email addresses on each Mailbox    
    For ($i = ($mailbox.EmailAddresses.count) - 1; $i -ge 0; $i--){
       
        $address = $mailbox.EmailAddresses[$i]
        $addressString = $address.addressString
#Loop through all domains and break loop if domain matches valid string.       
        foreach($domain in $ValidDomains){
        if ($addressString -like "(*$domain*"){
            break
        }    
        Write-Output "$addressString found in Mailbox: $primsmtp"
        }
        
    
    }
}


#Loop through email addresses on each Distribution Group

foreach ($dg in $dgs){
    $dgsmtp = $dg.PrimarySmtpAddress
    For ($i = ($dg.EmailAddresses.count) - 1; $i -ge 0; $i--){
        $address = $dg.EmailAddresses[$i]
        $addressString = $address.addressString
#Loop through all domains and break loop if domain matches valid string.        
        foreach($domain in $ValidDomains){
            if ($addressString -like "(*$domain*"){
                break
            }    
            Write-Output "$addressString found in Group: $dgsmtp"
            }
    }
}