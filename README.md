# GetFolderAge

PowerShell script which checks for last modified date for large number of folders.
It checks recursively for all files and folders inside.

Running a script itself will just import (i.e. create) new commandlet `Get-FolderAge` in your session.
It will not do any checks.
You can afterwards run this commandlet with proper parameters as in examples below.

Running script with specifying only a folder name will return last modification time of that folder.
If you specify `-CutOffDate` (or `-CutoffDays`) script will determine if folder was modified after that time. It will exit folder search as soon as it finds modified file or folder.

Script can be run in un-attended mode also with file output using `-OutputFileName` parameter. Output format is comma-separated value, so file extension should be `.csv`.

Technical explanation of LastModifiedDate can be seen in [this archived copy](https://web.archive.org/web/20110604022236/http://support.microsoft.com/kb/299648) of Microsoft knowledge base article.

## Help and Examples

![Screenshot 1](img/Screenshot_1.jpg)

### Details

For more examples and full parameter's explanation, run `Get-Help Get-FolderAge -Full` or see the [online version](Get-FolderAge.md).

### Examples

* `Get-FolderAge -Folder '\\server\Docs'`

Returns last modification date of the specified folder.

* `Get-FolderAge -Folder '\\FileServer01.Contoso.com\Users' -TestSubFolders`

Returns last modification date for each user share on file server.

* `Get-FolderAge -InputFile 'ShareList.txt' -OutputFile 'ShareScanResults.csv' -CutoffDays 3`

Tests if folders listed in specified input file (one folder per line) are modified since "cut-off" 3 days ago. Results are saved to file in csv format.

### Input parameters

Input can be specified in three ways:

* parameter `-FolderName` _(default parameter, can be omitted)_ followed by string or an array of strings specifying paths to be checked
* via pipeline - the same values as above can be passed via pipeline, see example with `Get-ChildItem`
* parameter `-InputFile` - a file specifying folders to be processed, one folder per line

![Screenshot 2](img/Screenshot_2.png)

### Cut-off Date explanation

Cut-off date represents the point in time for which we want to know if a folder was modified after.
Usually this is the date when last copy or backup or sync was performed on given folder.

It can be specified as:

* PowerShell [DateTime] object, i.e. the value returned by Get-Date command
* Integer number representing days since last cut-off date (easier, but less precise)

### Output format

Script outputs array of FolderAgeResult objects. Each object contain these properties:

* [string]`Path` - as specified in input parameters (or obtained subfolder names)
* [DateTime]`LastWriteTime` - latest write time for all items inside of the folder
* [bool]`Modified` - if folder was modified since last cut-off date (or null if date not given)

It also outputs diagnostic/statistics info:

* [bool]`Confident` - if Modified return value is confident result, in case script is called with QuickTest switch, return value for Modified might not be correct. This does not apply to LastWriteTime.
* [int]`TotalFiles` - total number of files and directories scanned
* [int]`TotalFolders` - total number of directories scanned
* [string]`LastItem` - item with latest timestamp found (note that this might not ber really the latest modified file. If this timestamp is newer than CutOffDate, script will not search further.
* [int]`Depth` - total depth of scanned folders relative to initial folder. If QuickTest, then it will be 1, regardless of real depth. If CutOffDate specified, it might not go to full depth, so this number will be smaller than full depth.
* [decimal]`ElapsedSeconds` - time spent in checking the folder
* [DateTime]`FinishTime` - date and time when folder check was completed

## Download

You can see online latest script version at this [link](https://github.com/iricigor/GetFolderAge/blob/master/Get-FolderAge.ps1).
Raw PS1 file can be downloaded from [here](https://raw.githubusercontent.com/iricigor/GetFolderAge/master/Get-FolderAge.ps1).

Script will be soon published to [PSGallery](https://www.powershellgallery.com).

## Build status

Each commit or PR to master is checked on [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/) [Pipelines](https://azure.microsoft.com/en-us/services/devops/pipelines/) on two build systems:

1. Ubuntu **Linux** v.16.04 running PowerShell (Core) v.6.1
2. **Windows** Container running Windows PowerShell v.5.1

[![Build Status](https://dev.azure.com/iiric/GetFolderAge/_apis/build/status/GetFolderAge-CI)](https://dev.azure.com/iiric/GetFolderAge/_build/latest?definitionId=5)

## Support

You can chat about this commandlet via [Skype](https://www.skype.com) _(no Skype ID required)_, by clicking a link below.

[![chat on Skype](https://img.shields.io/badge/chat-on%20Skype-blue.svg?style=flat)](https://join.skype.com/hQMRyp7kwjd2)

## Contributing

If you find any problems, feel free to open a new issue.

![GitHub open issues](https://img.shields.io/github/issues/iricigor/GetFolderAge.svg?style=flat)
![GitHub closed issues](https://img.shields.io/github/issues-closed/iricigor/GetFolderAge.svg?style=flat)

If you want to contribute, please fork the code and make a new PR after!

![GitHub](https://img.shields.io/github/license/iricigor/GetFolderAge.svg?style=flat)
![GitHub top language](https://img.shields.io/github/languages/top/iricigor/GetFolderAge.svg?style=flat)