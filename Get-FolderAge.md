---
external help file:
Module Name:
online version:
schema: 2.0.0
---

# Get-FolderAge

## SYNOPSIS
Get-FolderAge returns LastModifiedDate for specified folder(s).

## SYNTAX

### Folders
```
Get-FolderAge [-FolderName] <String[]> [-OutputFile <String>] [-ModifiedDays <Int32>] [-TargetDate <DateTime>]
 [-QuickTest] [-TestSubFolders] [<CommonParameters>]
```

### InputFile
```
Get-FolderAge -InputFile <String> [-OutputFile <String>] [-ModifiedDays <Int32>] [-TargetDate <DateTime>]
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

## PARAMETERS

### -FolderName
Input parameters

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
{{Fill InputFile Description}}

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
Other parameters

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

### -ModifiedDays
= "Get-FolderAge.temp.$(Get-Date -f 'yyyymmdd-HHMMss').csv", # removed default value, if output wanted, it should be specified

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

### -TargetDate
{{Fill TargetDate Description}}

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
{{Fill QuickTest Description}}

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
{{Fill TestSubFolders Description}}

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

## OUTPUTS

### [FolderAgeResult[]]

## NOTES
NAME:       Get-FolderAge

AUTHOR:     Igor Iric, iricigor@gmail.com, github.com/iricigor

CREATEDATE: October 2018

## RELATED LINKS
