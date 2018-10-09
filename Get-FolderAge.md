---
external help file:
Module Name:
online version: https://github.com/iricigor/GetFolderAge
schema: 2.0.0
---

# Get-FolderAge

## SYNOPSIS
Get-FolderAge returns LastModifiedDate for specified folder(s).

## SYNTAX

### Folders
```
Get-FolderAge [-FolderName] <String[]> [-OutputFile <String>] [-CutOffDays <Int32>] [-CutOffTime <DateTime>]
 [-QuickTest] [-TestSubFolders] [<CommonParameters>]
```

### InputFile
```
Get-FolderAge -InputFile <String> [-OutputFile <String>] [-CutOffDays <Int32>] [-CutOffTime <DateTime>]
 [-QuickTest] [-TestSubFolders] [<CommonParameters>]
```

## DESCRIPTION
Get-FolderAge returns LastModifiedDate for specified folder(s).
Input folders can be specified as array or via pipeline, or via input file.
Function is intended to run on large number of big folders, i.e.
in servers environment.

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
Get-FolderAge -InputFile 'ShareList.txt'
```

Returns last modification date for folders listed in specified input file (one folder per line).

### EXAMPLE 4
```
Get-ChildItem \\server\share | ? Name -like 'User*' | Get-FolderAge
```

Obtains list of folders and filters it by name.
Then this list is passed via pipeline to Get-FolderAge

## PARAMETERS

### -FolderName
FolderName specifies folder which will be evaluated.
Parameter accepts multiple values or pipeline input.
Pipeline input can be obtained for example via Get-ChildItem command.

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
String specifying file name which contains list of folders to be processed, one folder per line.

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
String specifying file name which will be used for output.
If not specified, there will be no file output generated.
This is specially useful for long running commands.
Each folder as soon as processed will be stored in the file.

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
Integer specifying how many days passed since last cut off point in time.
With -Verbose output you can see actual point in time used for cutoff time.
If both CutOffTime and CutOffDays specified, script will throw an error.

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
Specifies point in time for evaluating "Modified" field in result.
If not specified, field will have $null value.
This can speed up the script as processing will exit once first "modified" file or folder is found.
Date format is following standard PowerShell definition and script is not handling any additional conversion.
In case of issues specifying exact date, consider using -CutOffDays parameter.

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

### -QuickTest
Switch which if specified will force to script to run in quick mode.
Default is full depth search.
QuickTest means only contents of the folder itself will be evaluated, i.e.
it will not do recursive scan.
Results may not be correct.
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
Instead of specifying all subfolders inside certain folder or share, you can use switch -TestSubFolders.
It will generate results for each subfolder inside of specified folder.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string[]]
Input can be specified in three ways:
- parameter -FolderName followed by string or an array of strings specifying paths to be checked
- via pipeline - the same values as above can be passed via pipeline, see example with Get-ChildItem
- parameter -InputFile - a file specifying folders to be processed, one folder per line

## OUTPUTS

### [FolderAgeResult[]]
Script outputs array os FolderAgeResult objects. Each object contain these properties:
- [string]Path - as specified in input parameters (or obtained subfolder names)
- [DateTime]LastWriteTime - latest write time for all items inside of the folder
- [bool]Modified - if folder was modified since last cut-off date (or null if date not given)

## NOTES
NAME:       Get-FolderAge

AUTHOR:     Igor Iric, iricigor@gmail.com, github.com/iricigor

CREATEDATE: October 2018

## RELATED LINKS

[https://github.com/iricigor/GetFolderAge](https://github.com/iricigor/GetFolderAge)

