<#PSScriptInfo

.VERSION 1.2
.GUID c9788cc2-d4af-4219-bf7d-8dd8fa89584f
.AUTHOR Igor Iric, iricigor@gmail.com, https://github.com/iricigor
.COMPANYNAME 
.COPYRIGHT 
.TAGS fileserver folder-structure modification-date last-modified last-write-time path-too-long
.LICENSEURI https://github.com/iricigor/GetFolderAge/blob/master/LICENSE
.PROJECTURI https://github.com/iricigor/GetFolderAge
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES Added restartable script functionality and alias, bug fixes for append and threads issues, for more info see https://github.com/iricigor/GetFolderAge/blob/master/ReleaseNotes.md
.DESCRIPTION Get-FolderAge returns `LastModifiedDate` for a specified folder(s) and if folders were modified after a specified cut-off date.

#>

# class FolderAgeResult {

#     [string]$Path
#     [datetime]$LastWriteTime
#     [Nullable[boolean]]$Modified

# }

function Global:Get-FolderAge {

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

    .EXAMPLE
    Get-ChildItem -Input '10shares.txt' -Threads 5
    Gather information about 10 shares from input file, running 5 shares at the time.
    Requires ThreadJob module, which can be installed with Install-Module ThreadJob

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
    A string specifying file name which will be used for output in addition to screen (or pipeline) output.
    This is especially useful for long running commands. Each folder as soon as processed will be stored in the file.
    This can be also used for restarting the script, if it gets interrupted before it finishes all folders.
    Just specify the same input and output files, and script will skip already processed folders!
    If this parameter is not specified, there will be no file output generated.
    
    .PARAMETER Exclude
    Specifies, as a string array, an folder names that this cmdlet excludes in the search operation.

    .PARAMETER Threads
    If this parameter specifies number larger than 1, checks will be done in more than one thread.
    This means that multiple folders will be processed in parallel which can bring significant speed improvement.
    Prerequisite for this functionality is module ThreadJob available from PS Gallery (run: inmo threadjob).

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

        [parameter(Mandatory=$false)] [string]$OutputFile,

        [parameter(Mandatory=$false)] [int]$CutOffDays,

        [parameter(Mandatory=$false)] [DateTime]$CutOffTime,

        [parameter(Mandatory=$false)] [string[]]$Exclude,

        [parameter(Mandatory=$false)]
        [ValidateRange(0,50)]         [int]$Threads = 0,

        #
        # Switches
        #

        [switch]$QuickTest,

        [switch]$TestSubFolders,

        [switch]$ProgressBar

    )

    BEGIN {

        # function begin phase
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        # internal function which check if path exists, if it is on file system and if it is not a folder
        function TestFile ([string]$Description,[string]$FilePath) { 
            if (!(Test-Path -LiteralPath $FilePath)) {throw "$FunctionName cannot process $Description $FilePath, because it does not exist"}
            $RP = Resolve-Path $FilePath
            if ($RP.Provider.Name -ne 'FileSystem')  {throw "$FunctionName cannot process $Description $FilePath, because it is not on the file system"}
            if ((Get-Item $FilePath).PSIsContainer)  {throw "$FunctionName cannot process $Description $FilePath, because it is directory and not a file"}
        }

        # constants
        $Separator = [IO.Path]::DirectorySeparatorChar
        $UC = '\\?\'
        $ThreadsLock = '.Get-FolderAge.ThreadsLock'

        # process $InputFile
        if ($InputFile) {
            TestFile '-InputFile' $InputFile
            $FolderName = Get-Content -LiteralPath $InputFile -ErrorAction SilentlyContinue
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

        if ($Threads -gt 1) {
            Write-Verbose -Message "$(Get-Date -f T)   checking threads prerequisites"

            if (!(Get-Module ThreadJob -ListAvailable)) {
                Write-Error "$FunctionName cannot find module ThreadJob, continuing without threads support"
                $Threads = 0
            } elseif (!(Get-Module ThreadJob)) {
                Write-Verbose -Message "$(Get-Date -f T)   importing module ThreadJob"
                Import-Module ThreadJob
            }

            $SourceFile = $MyInvocation.MyCommand.ScriptBlock.File
            $JobList = @()

            if ($QuickTest -or $ProgressBar) {
                Write-Warning -Message "$(Get-Date -f T)   $FunctionName cannot be use QuickTest or ProgressBar together Threads, disabling these options."
                $QuickTest = $ProgressBar = $false
            }

            if ($CutOffTime) {
                $CutOffString = [string]$CutOffTime
                if (([datetime]$CutOffString - $CutOffTime).TotalSeconds -gt 1) {
                    throw "$FunctionName cannot convert CutOffTime ($CutOffString)"
                }
            }

        }

        # Restartable script setup
        if ($OutputFile) {
            if (($Threads -eq 0) -and (Test-Path -LiteralPath "$OutputFile$ThreadsLock")) {
                # we are inside of threaded job, skip all the tests
                $FoldersToSkip = $null
                # Run threaded and stop it; then run simple job causes to skip tests, but they are already done in threaded job
            } else {
                # we are inside simple or master job with existing output file, (Threads -gt 0) -or (.threadslock not existing)
            
                if (Test-Path -LiteralPath $OutputFile) {
                    $RP = Resolve-Path -LiteralPath $OutputFile
                    TestFile '-OutputFile' $OutputFile
                    try {
                        $FoldersToSkip = Import-Csv -LiteralPath $OutputFile | Select -Expand Path
                        Write-Verbose -Message "$(Get-Date -f T)   Script continues writing to $OutputFile, with skipping $(@($FoldersToSkip).Count) processed folders"
                    } catch {
                        throw "$FunctionName found existing file $OutputFile in unrecognized format, cannot continue."
                    }
                } else {
                    # test creating file
                    # FIXME: We try to create new item also on non-file-system which is not good, for example HKCU:\Environment\BB; we cannot resolve non existing path
                    $DeleteIt = $false
                    try   {
                        New-Item $OutputFile -ItemType File -ea Stop | Out-Null # we should have writable location
                        $DeleteIt = $true                    
                    } catch {
                        if ($_ -notmatch 'already exists') { # multiple threads can cause to create file in the meantime
                            throw "$FunctionName cannot create $OutputFile`: $_"
                        }
                    } 
                    # test proper path
                    $RP = Resolve-Path -LiteralPath $OutputFile
                    try     {TestFile '-OutputFile' $OutputFile}
                    catch   {throw $_}
                    finally {if ($DeleteIt) {Remove-Item $OutputFile -Force -ea 0}}
                    $FoldersToSkip = $null
                }            
                # resolve outputfile path
                if ($OutputFile -ne $RP.ProviderPath) {
                    Write-Verbose -Message "$(Get-Date -f T)   Expanding $OutputFile to $($RP.Path) via $($RP.Provider.Name) call"
                    $OutputFile = $RP.ProviderPath
                }
            }
        }

        if (($Threads -gt 1) -and (Get-Job | where {$_.State -eq 'Running'})) {
            Write-Warning -Message "$(Get-Date -f T) $FunctionName can be impacted with already running jobs. Consider removing them with Get-Job | Remove-Job -Force"
        }
    }


    PROCESS {

        foreach ($FolderEntry in $FolderName) {
            if ($FolderName.Count -gt 1) {Write-Verbose -Message "$(Get-Date -f T)   Processing $FolderEntry"}

            if (!(Test-Path -LiteralPath $FolderEntry)) {
                # non-terminating error, we can proceed to next FolderEntry
                Write-Error "$FunctionName cannot find folder $FolderEntry"
                continue
            }
            $RP = Resolve-Path -LiteralPath $FolderEntry
            if ($RP.Provider.Name -ne 'FileSystem') {
                Write-Error "$FunctionName provided path $FolderEntry is not on the FileSystem"
                continue
            } elseif ($FolderEntry -ne $RP.ProviderPath) {
                Write-Verbose -Message "$(Get-Date -f T)   Expanding $FolderEntry to $($RP.ProviderPath) via $($RP.Provider.Name) call"
                $FolderEntry = $RP.ProviderPath
            }

            if ($TestSubFolders) {
                $FolderList = @(Get-ChildItem -LiteralPath $FolderEntry -ea SilentlyContinue | where {$_.PSIsContainer} | Select -Expand FullName)
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

                if ($FoldersToSkip -and ($FoldersToSkip -contains $Folder)) {
                    Write-Verbose -Message "$(Get-Date -f T)   skipping $Folder from processing, because it is present in $OutputFile."
                    continue
                }

                if ($Threads -gt 1) {

                    if ($OutputFile) {New-Item "$OutputFile$ThreadsLock" -ea 0 | Out-Null}
                    $JobCode = "$FunctionName '$Folder'"
                    if ($CutOffTime) {$JobCode += " -CutOffTime '$CutOffString'"}
                    if ($Exclude) {$Join = "', '"; $JobCode += " -Exclude '$($Exclude -join $Join)'"}
                    if ($OutputFile) {$JobCode += " -OutputFile '$OutputFile'"}
                    Write-Verbose -Message "$(Get-Date -f T)   starting background job for '$Folder': $JobCode"
                    $JobCode = ". $SourceFile`n$JobCode" # first import function 
                    $JobList += Start-ThreadJob -ScriptBlock ([Scriptblock]::Create($JobCode)) -ThrottleLimit $Threads
                    Start-Sleep -Milliseconds 200 # let the job execute begin block, before starting next one

                    continue # to next $Folder
                }

                # initialize loop
                $StartTime = Get-Date
                $i = 0
                $queue = @($Folder)
                $LastWriteTime = Get-Item -LiteralPath $Folder | Select -Expand LastWriteTime
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

                while ($KeepProcessing -and ($i -lt ($queue.Count))) {
                    
                    $Current = $queue[$i]
                    Write-Debug -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while $i/$($queue.Count) $Current"
                    if ($ProgressBar) {
                        Write-Progress -Activity $Folder -PercentComplete (100 * $i / ($queue.Count)) -Status $Current
                    }
                    if (($Current.Length -gt 250) -and (!($Current.StartsWith($UC))) -and (!($IsLinux))) {
                        $Current = $UC + $Current  # too long path, append unicode prefix, see https://docs.microsoft.com/en-us/windows/desktop/FileIO/naming-a-file#maximum-path-length-limitation
                    }
                    # read files and folders inside
                    $Children = Get-ChildItem -LiteralPath $Current -Force -ErrorAction SilentlyContinue -ErrorVariable ErrVar
                    if ($ErrVar) {
                        Write-Debug -Message "$(Get-Date -f T)   Error processing children on $Current`: $ErrVar"
                        $ErrorsFound = $true
                        $LastError = [string]$ErrVar
                        $LastErrorItem = $Current
                    }
                    # keep all files and not excluded folders
                    if ($Exclude) {
                        if ($Children | where {$_.PSIsContainer} | where {$Exclude -contains ($_.Name)}) {
                            Write-Verbose -Message "$(Get-Date -f T)   excluding $(($Children | where {$_.PSIsContainer} | where {$Exclude -contains ($_.Name)}).Name -join ',')"
                            $Children = $Children | where {($_.PSIsContainer -eq $false) -or (!($Exclude -contains ($_.Name)))}    
                        }
                    }
                    
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
                    if ($Children) {$TotalFiles += @($Children).Count} # v2 gives 1 for empty array
                    Write-Debug -Message "$(Get-Date -f T)   total items checked: $TotalFiles"

                    # If quick check, we add children only if $i = 0
                    if ($QuickTest) {
                        # skip adding children
                        Write-Verbose -Message "$(Get-Date -f T)   not processing subfolders due to -QuickTest switch"
                    } else {
                        # add sub-folders for further processing
                        $SubFolders = $Children | where {$_.PSIsContainer}
                        if ($SubFolders) {
                            $queue += $SubFolders | Select -Expand FullName
                            # we can use List instead of Array for $queue, but we are not spending much time on this operation anyway
                            Write-Debug -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while new queue length $($queue.Count), last `'$($queue[$queue.Count-1])`'"
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
                        # statistical info
                        TotalFiles = $TotalFiles
                        TotalFolders = $queue.Count
                        LastItem = $LastItemName
                        Depth = ($queue[$i-1].split($Separator)).Count - ($queue[0].split($Separator)).Count + 1
                        ElapsedSeconds = ($EndTime - $StartTime).TotalSeconds
                        StartTime = $StartTime
                        FinishTime = $EndTime
                        # error info
                        Errors = $ErrorsFound
                        LastError = $LastError
                        LastErrorItem = $LastErrorItem
                    }
                
                #
                # File output, if needed
                #

                if ($OutputFile) {
                    if (!(Test-Path $OutputFile)) {
                        try {
                            $RetVal | Export-Csv -Path $OutputFile -Encoding Unicode -NoTypeInformation # Export-csv in PS v2 has no -LiteralPath
                            Write-Verbose -Message "$(Get-Date -f T)   created output file $OutputFile"
                        } catch {
                            Write-Error "$FunctionName failed while writing to $OutputFile, file output is skipped`n$_"
                            $OutputFile = $null
                        }
                    } else {
                        $Repeat = 5
                        do {
                            try {
                                $RetVal | ConvertTo-Csv -NoTypeInformation | Select -Skip 1 | Out-File -FilePath $OutputFile -Append -Encoding Unicode
                                Write-Verbose -Message "$(Get-Date -f T)   appended new line to output file $OutputFile"
                                $Repeat = 0
                            } catch {
                                if ($_ -match 'because it is being used by another process') {
                                    Write-Verbose -Message "$(Get-Date -f T)   appending data to output file $OutputFile failed, because file is in use, will retry in 100ms"
                                    $Repeat--
                                    Start-Sleep 100
                                } else {
                                    Write-Error "$FunctionName failed to append data to $OutputFile, entry for $Folder will be skipped.`n$_"
                                    $Repeat = 0
                                }
                            }    
                        } while ($Repeat -gt 0) 
                    }
                }
                # Return to pipeline
                $RetVal
            }
        }
    }

    END {

        # if threads, receive them
        if ($Threads -gt 1) {
            if ($JobList) {
                Write-Verbose -Message "$(Get-Date -f T) $FunctionName waiting for background jobs results."
                Receive-Job $JobList -Wait
                Remove-Job $JobList
            } else {
                Write-Warning -Message "$(Get-Date -f T) $FunctionName have skipped all folders, please recheck results file $OutputFile"
            }
            Remove-Item "$OutputFile$ThreadsLock" -Force -ea 0    
        }
        
        # function closing phase
        Write-Verbose -Message "$(Get-Date -f T) $FunctionName finished"
    }
    
}


Set-Alias -Name gfa -Value Get-FolderAge