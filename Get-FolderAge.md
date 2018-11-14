---
external help file:
Module Name:
online version: https://github.com/iricigor/GetFolderAge/blob/master/Get-FolderAge.md
schema: 2.0.0
---

# Get-FolderAge

## SYNOPSIS
Get-FolderAge returns \`LastModifiedDate\` for a specified folder(s) and if folders were modified after a specified cut-off date.

## SYNTAX

### Folders
```
Get-FolderAge [-FolderName] <String[]> [-OutputFile <String>] [-CutOffDays <Int32>] [-CutOffTime <DateTime>]
 [-Exclude <String[]>] [-Threads <Int32>] [-QuickTest] [-TestSubFolders] [-ProgressBar] [<CommonParameters>]
```

### InputFile
```
Get-FolderAge -InputFile <String> [-OutputFile <String>] [-CutOffDays <Int32>] [-CutOffTime <DateTime>]
 [-Exclude <String[]>] [-Threads <Int32>] [-QuickTest] [-TestSubFolders] [-ProgressBar] [<CommonParameters>]
```

## DESCRIPTION
Get-FolderAge returns LastModifiedDate for a specified folder(s) and if folders were modified after a specified cut-off date.
Input folders can be specified as an array or via pipeline, or via input file.
The function is intended to run on a large number of big/huge folders, i.e.
in file servers environment.

## EXAMPLES

### EXAMPLE 1
```
Get-FolderAge -Folder '\\server\Docs'
```

Returns last modification date of the specified folder.

### EXAMPLE 2
```
Get-FolderAge -Folder '\\FileServer01.Contoso.com\Users -TestSubFolders'
```

Returns last modification date for each user share on file server.

### EXAMPLE 3
```
Get-FolderAge -InputFile 'ShareList.txt' -OutputFile 'ShareScanResults.csv' -CutoffDays 3
```

Tests if folders listed in specified input file (one folder per line) are modified since "cut-off" 3 days ago.
Results are saved to file in csv format.

### EXAMPLE 4
```
Get-ChildItem \\server\share | ? Name -like 'User*' | Get-FolderAge
```

Obtains list of folders and filters it by name.
Then this list is passed via pipeline to Get-FolderAge

### EXAMPLE 5
```
Get-ChildItem -Input '10shares.txt' -Threads 5
```

Gather information about 10 shares from input file, running 5 shares at the time.
Requires ThreadJob module, which can be installed with Install-Module ThreadJob


### EXAMPLE 6

```
Get-FolderAge . -Exclude .git,img
```

This example can be executed on a clone of this repository. It will exclude mentioned two folders.

## PARAMETERS

### -FolderName
FolderName specifies the folder which will be evaluated.
Parameter accepts multiple values or pipeline input.
Pipeline input can be obtained for example via Get-ChildItem command (see examples).

```yaml
Type: String[]
Parameter Sets: Folders
Aliases: FullName

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -InputFile
String specifying file name which contains a list of folders to be processed, one folder per line.

```yaml
Type: String
Parameter Sets: InputFile
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFile
A string specifying file name which will be used for output in addition to screen (or pipeline) output.
This is especially useful for long running commands. Each folder as soon as processed will be stored in the file.
This can be also used for restarting the script, if it gets interrupted before it finishes all folders.
Just specify the same input and output files, and script will skip already processed folders!
If this parameter is not specified, there will be no file output generated.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CutOffDays
An integer specifying how many days passed since the last cut off point in time.
With -Verbose output you can see actual point in time used for cutoff time.
If both CutOffTime and CutOffDays specified, the script will throw a warning.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -CutOffTime
Specifies a point in time for evaluating "Modified" field in the result.
If not specified, the field will have $null value.
This can speed up the script as processing will exit once first "modified" file or folder is found.
Date format is following standard PowerShell definition and script is not handling any additional conversion.
In case of issues specifying an exact date, consider using -CutOffDays parameter.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Exclude
Specifies, as a string array, folder names that this cmdlet excludes in the search operation. Multiple names should be separated by commas. If folder name has space you must enclose it in apostrophes. Only exact folder names are excluded.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Threads
If this parameter specifies number larger than 1, checks will be done in more than one thread.
This means that multiple folders will be processed in parallel which can bring significant speed improvement.
Prerequisite for this functionality is module ThreadJob available from PS Gallery (run: inmo threadjob).


```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -QuickTest
Switch which if specified will force to script to run in quick mode.
The default is full depth search.
QuickTest means only contents of the folder itself will be evaluated, i.e.
it will not do full depth scan.
Results in this case may not be correct.
This is useful for testing input file and network connectivity issues.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TestSubFolders
Instead of specifying all subfolders inside certain folder or share, you can use the switch -TestSubFolders.
It will generate results for each subfolder inside of the specified folder.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressBar
Script can displays standard PowerShell progress bar showing current processed folder and percent of completion.
Be aware that this can prolong running time.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]]

### Input can be specified in three ways:

### - parameter -FolderName followed by string or an array of strings specifying paths to be checked

### - via pipeline - the same values as above can be passed via pipeline, see the example with Get-ChildItem

### - parameter -InputFile - a file specifying folders to be processed, one folder per line

## OUTPUTS

### [FolderAgeResult[]]

### Script outputs array of FolderAgeResult objects. Each object contain these properties:

### - [string]   Path          - as specified in input parameters (or obtained subfolder names)

### - [DateTime] LastWriteTime - the latest write time for all items inside of the folder

### - [bool]     Modified      - if folder was modified since last cut-off date (or null if date not given)

### It also outputs diagnostic/statistics info which can be seen online.

## NOTES
NAME:       Get-FolderAge

AUTHOR:     Igor Iric, iricigor@gmail.com, https://github.com/iricigor

CREATEDATE: October 2018

## RELATED LINKS

[https://github.com/iricigor/GetFolderAge](https://github.com/iricigor/GetFolderAge)

