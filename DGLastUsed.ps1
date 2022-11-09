$LastUsed = foreach($grp in Get-DistributionGroup -ResultSize Unlimited){
    $size=(Get-DistributionGroupMember -Identity $grp.DistinguishedName -ResultSize Unlimited).Count
    if ($size -eq 1) 
        {

Get-TransportService -ResultSize Unlimited | Get-MessageTrackingLog -Recipients $grp.PrimarySMTPAddress -EventId RECEIVE | Sort-Object Timestamp -Descending | select Recipient,Timestamp,Sender,MessageSubject -First 1

}
Else{}
}
$lastUsed | Export-CSV LastUsed.csv -NoTypeInformation