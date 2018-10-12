# re-import function
. .\Get-FolderAge.ps1

# generate help
$url = 'https://github.com/iricigor/GetFolderAge/blob/master/Get-FolderAge.md'
New-MarkdownHelp -Command Get-FolderAge -OutputFolder . -Verbose -Force -wa 0 -OnlineVersionUrl $url