Import-CSV -Path "C:\temp\departments.csv" | Foreach-Object {
    $mail = $_.emailAddress
    $title = $_.jobTitle
    $office = $_.Site
    $department = $_.department
    Write-Host "Updating user: $mail with: $office $department $title"
    Get-ADUser -Filter "Mail -eq '$mail'" -Properties * | Set-ADUser -Title $title -Department $department -Office $office
}