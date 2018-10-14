# class FolderAgeResult {

#     [string]$Path
#     [datetime]$LastWriteTime
#     [Nullable[boolean]]$Modified

# }

function Get-FolderAge {

    <#

    .SYNOPSIS
    Get-FolderAge returns `LastModifiedDate` for a specified folder(s) and if folders were modified after a specified cut-off date.

    .DESCRIPTION
    Get-FolderAge returns LastModifiedDate for a specified folder(s) and if folders were modified after a specified cut-off date.
    Input folders can be specified as an array or via pipeline, or via input file.
    The function is intended to run on a large number of big/huge folders, i.e. in file servers environment.

    .INPUTS
    [string[]]
    Input can be specified in three ways:
    - parameter -FolderName followed by string or an array of strings specifying paths to be checked
    - via pipeline - the same values as above can be passed via pipeline, see the example with Get-ChildItem
    - parameter -InputFile - a file specifying folders to be processed, one folder per line

    .OUTPUTS
    [FolderAgeResult[]]
    
    Script outputs array of FolderAgeResult objects. Each object contain these properties:
    - [string] Path - as specified in input parameters (or obtained subfolder names)
    - [DateTime] LastWriteTime - the latest write time for all items inside of the folder
    - [bool] Modified - if folder was modified since last cut-off date (or null if date not given)

    It also outputs diagnostic/statistics info:
    - [bool] Confident - if Modified return value is confident result, in case script is called with QuickTest switch, return value for Modified might not be correct. This does not apply to LastWriteTime.
    - [int] TotalFiles - total number of files and directories scanned
    - [int] TotalFolders - total number of directories scanned
    - [string] LastItem - item with latest timestamp found (note that this might not ber really the latest modified file. If this timestamp is newer than CutOffDate, script will not search further.
    - [int] Depth - total depth of scanned folders relative to initial folder. If QuickTest, then it will be 1, regardless of real depth. If CutOffDate specified, it might not go to full depth, so this number will be smaller than full depth.
    - [decimal]  ElapsedSeconds - time spent in checking the folder
    - [DateTime] FinishTime - date and time when folder check was completed
    - [bool] Errors - indicate if command encountered errors during its execution (i.e. Access Denied on part of the files)
    - [string] LastError - text of the last encountered error
    
    .EXAMPLE
    Get-FolderAge -Folder '\\server\Docs'
    Returns last modification date of the specified folder.

    .EXAMPLE
    Get-FolderAge -Folder '\\FileServer01.Contoso.com\Users -TestSubFolders'
    Returns last modification date for each user share on file server.

    .EXAMPLE
    Get-FolderAge -InputFile 'ShareList.txt' -OutputFile 'ShareScanResults.csv' -CutoffDays 3
    Tests if folders listed in specified input file (one folder per line) are modified since "cut-off" 3 days ago. Results are saved to file in csv format.

    .EXAMPLE
    Get-ChildItem \\server\share | ? Name -like 'User*' | Get-FolderAge
    Obtains list of folders and filters it by name. Then this list is passed via pipeline to Get-FolderAge

    .PARAMETER FolderName
    FolderName specifies the folder which will be evaluated. Parameter accepts multiple values or pipeline input.
    Pipeline input can be obtained for example via Get-ChildItem command (see examples).

    .PARAMETER InputFile
    String specifying file name which contains a list of folders to be processed, one folder per line.
    
    .PARAMETER CutOffTime
    Specifies a point in time for evaluating "Modified" field in the result. If not specified, the field will have $null value.
    This can speed up the script as processing will exit once first "modified" file or folder is found.
    Date format is following standard PowerShell definition and script is not handling any additional conversion.
    In case of issues specifying an exact date, consider using -CutOffDays parameter.
    
    .PARAMETER CutOffDays
    An integer specifying how many days passed since the last cut off point in time.
    With -Verbose output you can see actual point in time used for cutoff time.
    If both CutOffTime and CutOffDays specified, the script will throw a warning.
    
    .PARAMETER OutputFile
    A string specifying file name which will be used for output. If not specified, there will be no file output generated.
    This is especially useful for long running commands. Each folder as soon as processed will be stored in the file.
    
    .PARAMETER QuickTest
    Switch which if specified will force to script to run in quick mode. The default is full depth search.
    QuickTest means only contents of the folder itself will be evaluated, i.e. it will not do full depth scan.
    Results in this case may not be correct. This is useful for testing input file and network connectivity issues.
    
    .PARAMETER TestSubFolders
    Instead of specifying all subfolders inside certain folder or share, you can use the switch -TestSubFolders.
    It will generate results for each subfolder inside of the specified folder.

    .PARAMETER ProgressBar
    Script can displays standard PowerShell progress bar showing current processed folder and percent of completion.
    Be aware that this can prolong running time.

    .LINK
    https://github.com/iricigor/GetFolderAge

    .NOTES
    NAME:       Get-FolderAge

    AUTHOR:     Igor Iric, iricigor@gmail.com, https://github.com/iricigor
    
    CREATEDATE: October 2018

    #>

    param (

        #
        # Input parameters
        #

        [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0,ParameterSetName='Folders')]
        [Alias('FullName')][string[]]$FolderName,

        [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName='InputFile')]
        [string]$InputFile,

        #
        # Other parameters
        #

        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [string]$OutputFile,

        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [int]$CutOffDays,

        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [DateTime]$CutOffTime,

        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [switch]$QuickTest,

        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [switch]$TestSubFolders,

        [parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [switch]$ProgressBar

    )

    BEGIN {

        # function begin phase
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        # process $InputFile
        if ($InputFile) {
            if (!(Test-Path $InputFile)) {
                throw "$FunctionName cannot find input file $InputFile"
            }
            $FolderName = Get-Content -Path $InputFile -ErrorAction SilentlyContinue
            if ($FolderName) {
                Write-Verbose -Message "$(Get-Date -f T)   successfully read $InputFile with $(@($FolderName).Count) entries"
            } else {
                throw "$FunctionName cannot read content of input file $InputFile, check if file is readable and not empty."
            }            
        }

        # Process $CutOffDays
        if ($CutOffDays -and $CutOffTime) {
            Write-Warning -Message "$(Get-Date -f T)   $FunctionName has -CutOffTime specified, ignoring CutOffDays."
        }
        if (!($CutOffTime)) {
            if ($PSBoundParameters.Keys -contains 'CutOffDays') {
                $CutOffTime = (Get-Date).AddDays(-$CutOffDays)
                Write-Verbose -Message "$(Get-Date -f T)   setting cut off date for $CutOffTime"
            } else {
                Write-Verbose -Message "$(Get-Date -f T)   running script without CutOffTime"
            }
        }

        $First = $true # Used if there is output to file, only first line drops header
        $Separator = [IO.Path]::DirectorySeparatorChar
        $UC = '\\?\'
    }


    PROCESS {

        foreach ($FolderEntry in $FolderName) {
            if ($FolderName.Count -gt 1) {Write-Verbose -Message "$(Get-Date -f T)   Processing $FolderEntry"}

            if (!(Test-Path -LiteralPath $FolderEntry)) {
                # non-terminating error, we can proceed to next FolderEntry
                Write-Error "$FunctionName cannot find folder $FolderEntry"
                continue
            }
            $RP = Resolve-Path $FolderEntry
            if ($RP.Provider.Name -ne 'FileSystem') {
                Write-Error "$FunctionName provided path $FolderEntry is not on the FileSystem"
                continue
            } elseif ($FolderEntry -ne $RP.ProviderPath) {
                Write-Verbose -Message "$(Get-Date -f T)   Expanding $FolderEntry to $($RP.ProviderPath) via $($RP.Provider.Name) call"
                $FolderEntry = $RP.ProviderPath
            }

            if ($TestSubFolders) {
                $FolderList = @(Get-ChildItem $FolderEntry -Directory -ea SilentlyContinue | Select -Expand FullName)
                if ($FolderList) {
                    Write-Verbose -Message "$(Get-Date -f T)   Processing $($FolderList.Count) subfolders of $FolderEntry"
                } else {
                    Write-Error "$FunctionName cannot find subfolders from $FolderEntry"
                    continue
                }
                
            } else {
                $FolderList = @($FolderEntry)
            }

            foreach ($Folder in $FolderList) {
                Write-Debug -Message "$(Get-Date -f T)   PROCESS.foreach.foreach $Folder"
                
                # processing single folder $Folder

                # initialize loop
                $StartTime = Get-Date
                $i = 0
                $queue = @($Folder)
                $LastWriteTime = Get-Item -Path $Folder | Select -Expand LastWriteTime
                $TotalFiles = 0
                $LastItemName = $Folder
                $KeepProcessing = $true
                $ErrorsFound = $false
                $LastError = $null

                #
                #
                # main non-recursive loop
                #
                #

                while ($KeepProcessing -and ($i -lt ($queue.Length))) {
                    
                    $Current = $queue[$i]
                    Write-Debug -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while $i/$($queue.Length) $Current)"
                    if ($ProgressBar) {
                        Write-Progress -Activity $Folder -PercentComplete (100 * $i / ($queue.Count)) -Status $Current
                    }
                    if (($Current.Length -gt 250) -and (!($Current.StartsWith($UC))) -and (!($IsLinux))) {
                        $Current = $UC + $Current  # too long path, append unicode prefix, see https://docs.microsoft.com/en-us/windows/desktop/FileIO/naming-a-file#maximum-path-length-limitation
                    }
                    $Children = Get-ChildItem -LiteralPath $Current -Force -ErrorAction SilentlyContinue -ErrorVariable ErrVar
                    if ($ErrVar) {
                        $ErrorsFound = $true
                        $LastError = [string]$ErrVar
                    }
                    $TotalFiles += @($Children).Count
                    
                    # check LastWriteTime
                    $Children | % {
                        if (($_.LastWriteTime -gt $LastWriteTime) -or ($_.CreationTime -gt $LastWriteTime)) {
                            $LastItemName = $_.FullName
                            $LastWriteTime = if ($_.LastWriteTime -gt $_.CreationTime) {$_.LastWriteTime} else {$_.CreationTime}
                            Write-Debug -Message "$(Get-Date -f T)   remembered newer entry $LastItemName"
                            # Check for exit?
                            if ($CutOffTime -and ($LastWriteTime -gt $CutOffTime)) {$KeepProcessing = $false}
                        }
                    }

                    # If quick check, we add children only if $i = 0
                    if ($QuickTest) {
                        # skip adding children
                        Write-Verbose -Message "$(Get-Date -f T)   not processing subfolders due to -QuickTest switch"
                    } else {
                        # add sub-folders for further processing
                        $SubFolders = $Children | where {$_.PSIsContainer}
                        if ($SubFolders) {
                            $queue += @($SubFolders.FullName)
                            # we can use List instead of Array for $queue, but we are not spending much time on this operation anyway
                            Write-Debug -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while new queue length $($queue.Length), last `'$($queue[$queue.Length-1])`'"
                        }
                    }
                    $i++
                }

                #
                #
                # return value
                #
                #

                Write-Debug -Message "$(Get-Date -f T)   preparing return value for $Folder"
                if (!$CutOffTime) {
                    $Modified = $Confident = $null
                } elseif ($LastWriteTime -gt $CutOffTime) {
                    $Modified = $true
                    $Confident = !($ErrorsFound)
                } else {
                    $Modified = $false
                    $Confident = (!($QuickTest)) -and (!($ErrorsFound))
                }
                # normalize paths
                if ($LastItemName.StartsWith($UC)) {$LastItemName = $LastItemName.Replace($UC,'')} 
                if ($queue[$i-1].StartsWith($UC)) {$queue[$i-1] = $queue[$i-1].Replace($UC,'')}
                $EndTime = Get-Date

                Write-Verbose -Message "$(Get-Date -f T)   return value for $Folder"
                $RetVal = New-Object PSObject -Property @{
                        Path = $Folder
                        LastWriteTime = $LastWriteTime
                        Modified = $Modified
                        Confident = $Confident
                        TotalFiles = $TotalFiles
                        TotalFolders = $queue.Count
                        LastItem = $LastItemName
                        Depth = ($queue[$i-1].split($Separator)).Count - ($queue[0].split($Separator)).Count + 1
                        ElapsedSeconds = ($EndTime - $StartTime).TotalSeconds
                        FinishTime = $EndTime
                        Errors = $ErrorsFound
                        LastError = $LastError
                    }
                # File output, if needed
                if ($OutputFile) {
                    if ($First) {
                        try {
                            $RetVal | Export-Csv -LiteralPath $OutputFile -Encoding Unicode -NoTypeInformation
                            Write-Verbose -Message "$(Get-Date -f T)   created output file $OutputFile"
                            $First = $false
                        } catch {
                            Write-Error "$FunctionName failed while writing to $OutputFile, file output is skipped"
                            $OutputFile = $null
                        }
                    } else {
                        try {
                            $RetVal | ConvertTo-Csv -NoTypeInformation | Select -Skip 1 | Out-File -LiteralPath $OutputFile -Append -Encoding Unicode
                            Write-Verbose -Message "$(Get-Date -f T)   appended new line to output file $OutputFile"
                        } catch {
                            Write-Error "$FunctionName failed to append date to $OutputFile, entry for $Folder will be skipped.`n$_"
                        }
                    }
                }
                # Return to pipeline
                $RetVal
            }
        }
    }

    END {
        # function closing phase
        Write-Verbose -Message "$(Get-Date -f T) $FunctionName finished"
}
    
}