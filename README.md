# GetFolderAge

PowerShell script which checks for last modified date for large number of folders.
Script can be run in un-attended mode also.

# Examples

* `Get-FolderAge -Folder '\\server\Docs'`

Returns last modification date of the specified folder.

* `Get-FolderAge -Folder '\\FileServer01.Contoso.com\Users -TestSubFolders'`

Returns last modification date for each user share on file server.

* `Get-FolderAge -InputFile 'ShareList.txt'`

Returns last modification date for folders listed in specified input file (one folder per line).

# Build status

Each commit or PR to master is checked on [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/) [Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/) on two build systems:
1. Ubuntu **Linux** v.16.04 running PowerShell (Core) v.6.1
1. **Windows** Container running Windows PowerShell v.5.1

[![Build Status](https://dev.azure.com/iiric/GetFolderAge/_apis/build/status/GetFolderAge-CI)](https://dev.azure.com/iiric/GetFolderAge/_build/latest?definitionId=5)