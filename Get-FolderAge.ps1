# class FolderAgeResult {

#     [string]$Path
#     [datetime]$LastWriteTime
#     [Nullable[boolean]]$Modified

#     # TODO: Add something like confident bool
#     # TODO: Add some diagnostics, like folders/files processed
# }

function Get-FolderAge {

    <#

    .SYNOPSIS
    Get-FolderAge returns LastModifiedDate for specified folder(s).

    .DESCRIPTION
    Get-FolderAge returns LastModifiedDate for specified folder(s).
    Input folders can be specified as array or via pipeline, or via input file.
    Function is intended to run on large number of big folders, i.e. in servers environment.

    .INPUTS
    [string[]]
    Input can be specified in three ways:
    - parameter -FolderName followed by string or an array of strings specifying paths to be checked
    - via pipeline - the same values as above can be passed via pipeline, see example with Get-ChildItem
    - parameter -InputFile - a file specifying folders to be processed, one folder per line

    .OUTPUTS
    [FolderAgeResult[]]
    Script outputs array of FolderAgeResult objects. Each object contain these properties:
    - [string]Path - as specified in input parameters (or obtained subfolder names)
    - [DateTime]LastWriteTime - latest write time for all items inside of the folder
    - [bool]Modified - if folder was modified since last cut-off date (or null if date not given)
    It also outputs diagnostic/statistics info which can be seen in full help.
    
    .EXAMPLE
    Get-FolderAge -Folder '\\server\Docs'
    Returns last modification date of the specified folder.

    .EXAMPLE
    Get-FolderAge -Folder '\\FileServer01.Contoso.com\Users -TestSubFolders'
    Returns last modification date for each user share on file server.

    .EXAMPLE
    Get-FolderAge -InputFile 'ShareList.txt'
    Returns last modification date for folders listed in specified input file (one folder per line).

    .EXAMPLE
    Get-ChildItem \\server\share | ? Name -like 'User*' | Get-FolderAge
    Obtains list of folders and filters it by name. Then this list is passed via pipeline to Get-FolderAge

    .PARAMETER FolderName
    FolderName specifies folder which will be evaluated. Parameter accepts multiple values or pipeline input.
    Pipeline input can be obtained for example via Get-ChildItem command (see examples).

    .PARAMETER InputFile
    String specifying file name which contains list of folders to be processed, one folder per line.
    
    .PARAMETER CutOffTime
    Specifies point in time for evaluating "Modified" field in result. If not specified, field will have $null value.
    This can speed up the script as processing will exit once first "modified" file or folder is found.
    Date format is following standard PowerShell definition and script is not handling any additional conversion.
    In case of issues specifying exact date, consider using -CutOffDays parameter.
    
    .PARAMETER CutOffDays
    Integer specifying how many days passed since last cut off point in time.
    With -Verbose output you can see actual point in time used for cutoff time.
    If both CutOffTime and CutOffDays specified, script will throw an error.
    
    .PARAMETER OutputFile
    String specifying file name which will be used for output. If not specified, there will be no file output generated.
    This is specially useful for long running commands. Each folder as soon as processed will be stored in the file.
    
    .PARAMETER QuickTest
    Switch which if specified will force to script to run in quick mode. Default is full depth search.
    QuickTest means only contents of the folder itself will be evaluated, i.e. it will not do recursive scan.
    Results may not be correct. This is useful for testing input file and network connectivity issues.
    
    .PARAMETER TestSubFolders
    Instead of specifying all subfolders inside certain folder or share, you can use switch -TestSubFolders.
    It will generate results for each subfolder inside of specified folder.

    .LINK
    https://github.com/iricigor/GetFolderAge

    .NOTES
    NAME:       Get-FolderAge

    AUTHOR:     Igor Iric, iricigor@gmail.com, github.com/iricigor
    
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
        [switch]$TestSubFolders

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
            }            
        }

        # Process $CutOffDays
        if ($CutOffDays -and $CutOffTime) {
            Write-Verbose -Message "$(Get-Date -f T)   $FunctionName has -CutOffTime specified, ignoring CutOffDays."
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
    }


    PROCESS {

        foreach ($FolderEntry in $FolderName) {
            if ($FolderName.Count -gt 1) {Write-Verbose -Message "$(Get-Date -f T)   Processing $FolderEntry"}

            $RP = Resolve-Path $FolderEntry
            if ($RP.Provider.Name -ne 'FileSystem') {
                Write-Error "$FunctionName provided path $FolderEntry is not on the FileSystem"
                continue
            } elseif ($FolderEntry -ne $RP.ProviderPath) {
                Write-Verbose -Message "$(Get-Date -f T)   Expanding $FolderEntry to $($RP.ProviderPath) via $($RP.Provider.Name) call"
                $FolderEntry = $RP.ProviderPath
            }
            if (!(Test-Path -LiteralPath $FolderEntry)) {
                # non-terminating error, we can proceed to next FolderEntry
                Write-Error "$FunctionName cannot find folder $FolderEntry"
                continue
            }

            if ($TestSubFolders) {
                $FolderList = @(Get-ChildItem $FolderEntry -Directory | Select -Expand FullName)
                Write-Verbose -Message "$(Get-Date -f T)   Processing $($FolderList.Count) subfolders of $FolderEntry"
            } else {
                $FolderList = @($FolderEntry)
            }

            foreach ($Folder in $FolderList) {
                Write-Verbose -Message "$(Get-Date -f T)   PROCESS.foreach.foreach $Folder"
                
                # processing single folder $Folder

                # initialize loop
                $i = 0
                $queue = @($Folder)
                $LastWriteTime = Get-Item -Path $Folder | Select -Expand LastWriteTime
                $TotalFiles = 0
                $LastItemName = $Folder

                #
                # main non-recursive loop
                #

                while ($i -lt ($queue.Length)) {
                    # TODO: Add jump out condition above
                    
                    #Write-Verbose -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while $i/$($queue.Length) $($queue[$i])"
                    Write-Progress -Activity $Folder -PercentComplete (100 * $i / ($queue.Count)) -Status $queue[$i]
                    $Children = Get-ChildItem -LiteralPath $queue[$i]
                    $TotalFiles += @($Children).Count
                    $LastChild = $Children | Sort-Object LastWriteTime -Descending | Select -First 1
                    if ($LastChild.LastWriteTime -gt $LastWriteTime) {
                        # newer modification, remember it
                        $LastWriteTime = $LastChild.LastWriteTime
                        $LastItemName = $LastChild.FullName
                        # TODO: Check for exit?
                    }

                    # TODO: If quick check, we add children only if $i = 0
                    if ($QuickTest) {
                        # skip adding children
                        Write-Verbose -Message "$(Get-Date -f T)   not processing subfolders due to -QuickTest switch"
                    } else {
                        # add sub-folders for further processing
                        $SubFolders = $Children | where {$_.PSIsContainer}
                        if ($SubFolders) {
                            $queue += @($SubFolders.FullName)
                            #Write-Verbose -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while queue length $($queue.Length), last `'$($queue[$queue.Length-1])`'"
                        }
                    }
                    $i++
                }

                #
                # return value
                #

                Write-Verbose -Message "$(Get-Date -f T)   return value for $Folder"
                if (!$CutOffTime) {
                    $Modified = $Confident = $null
                } elseif ($LastWriteTime -gt $CutOffTime) {
                    $Modified = $Confident = $true
                } else {
                    $Modified = $false
                    $Confident = !($QuickTest)
                }
                $RetVal = New-Object PSObject -Property @{
                        Path = $Folder
                        LastWriteTime = $LastWriteTime
                        Modified = $Modified
                        Confident = $Confident
                        TotalFiles = $TotalFiles
                        TotalFolders = $queue.Count
                        LastItem = $LastItemName
                        Depth = ($queue[$i-1].split($Separator)).Count - ($queue[0].split($Separator)).Count + 1
                    }
                # File output, if needed
                if ($OutputFile) {
                    if ($First) {
                        $RetVal | Export-Csv -LiteralPath $OutputFile -Encoding Unicode
                        $First = $false
                    } else {
                        $RetVal | ConvertTo-Csv | Select -Skip 1 | Out-File -LiteralPath $OutputFile -Append -Encoding Unicode
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