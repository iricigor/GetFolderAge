class FolderAgeResult {

    [string]$Path
    [datetime]$LastWriteTime
    [bool]$OlderThan

    # TODO: Add something like confident bool
}

function Get-FolderAge {

    param (

        #
        # Input parameters
        #

        [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0,ParameterSetName='Folders')]
        [Alias('FullName')][string[]]$FolderName,

        [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName='InputFile')]
        [string]$InputFile,

        #
        # Last copy date
        #

        [int]$ModifiedDays,

        [datetime]$TargetDate,

        #
        # Other parameters
        #

        [switch]$QuickTest,
        [switch]$TestSubFolders

    )

    BEGIN {
        # function begin phase
        $FunctionName = $MyInvocation.MyCommand.Name
        Write-Verbose -Message "$(Get-Date -f G) $FunctionName starting"

        if ($InputFile) {
            # TODO: Add error handling
            $FolderName = Get-Content -Path $InputFile
        }
    }

    PROCESS {

        foreach ($FolderEntry in $FolderName) {
            Write-Verbose -Message "$(Get-Date -f T)   PROCESS.foreach $FolderEntry" # remove this later
            if ($FolderName.Count -gt 1) {Write-Verbose -Message "$(Get-Date -f T)   Processing $FolderEntry"}

            if (!(Test-Path -LiteralPath $FolderEntry)) {
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

                while ($i -lt ($queue.Length)) {
                    # TODO: Add jump out condition above
                    
                    #Write-Verbose -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while $i/$($queue.Length) $($queue[$i])"
                    Write-Progress -Activity $Folder -PercentComplete (100 * $i / ($queue.Count)) -Status $queue[$i]
                    $Children = Get-ChildItem -LiteralPath $queue[$i]
                    $ChildLastWriteTime = $Children | Sort-Object LastWriteTime -Descending | Select -First 1 -Expand LastWriteTime
                    if ($ChildLastWriteTime -gt $LastWriteTime) {
                        # newer modification, remember it
                        $LastWriteTime = $ChildLastWriteTime
                        # TODO: Check for exit?
                    }

                    # TODO: If quick check, we add children only if $i = 0
                    if ($QuickTest -and ($i -gt 0)) {
                        # skip adding children
                        # TODO: Add verbose here
                    } else {
                        # add sub-folders for further processing
                        $SubFolders = $Children | ? PSIsContainer
                        if ($SubFolders) {
                            $queue += @($SubFolders.FullName)
                            #Write-Verbose -Message "$(Get-Date -f T)   PROCESS.foreach.foreach.while queue length $($queue.Length), last `'$($queue[$queue.Length-1])`'"
                        }
                    }
                    $i++
                }

                # return value
                Write-Verbose -Message "$(Get-Date -f T)   return value for $Folder"
                New-Object FolderAgeResult -Property @{
                    Path = $Folder
                    LastWriteTime = $LastWriteTime
                    OlderThan = if ($TargetDate) {$LastWriteTime -gt $TargetDate} else {$null} # TODO: Define logic/naming here
                }

            }
        }
    }

    END {
        # function closing phase
        Write-Verbose -Message "$(Get-Date -f T) $FunctionName finished"
}
    
}