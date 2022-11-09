#Script to convert extension into uppercase - needed for website
# Get all items in the current directory
Get-ChildItem | %{
    # Construct a new file name
    $newFilename = ($_.BaseName)+($_.Extension.ToUpper());

    # Move the file
    Move-Item $_ $newFilename
}