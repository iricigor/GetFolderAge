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

        foreach ($F1 in $FolderName) {
            if ($FolderName.Count -gt 1) {Write-Verbose -Message "$(Get-Date -f T)   Processing $F1"}

            # TODO: Add more verbose
            if ($TestSubFolders) {
                $FolderList = Get-ChildItem $F1 -Directory
            } else {
                $FolderList = @($F1)
            }

            foreach ($Folder in $FolderList) {
                
                # processing single folder $Folder

                # initialize loop
                $i = 0
                $queue = @($Folder)
                $LastWriteTime = Get-Item -Path $Folder | Select -Expand LastWriteTime

                while ($i -lt ($queue.Length)) {
                    # TODO: Add jump out condition above

                    $Children = Get-ChildItem -LiteralPath $Folder
                    $ChildLastWriteTime = $Children | Sort LastWriteTime -Descending | Select -First 1 -Expand LastWriteTime
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
                        $queue += ($Children | ? PSIsContainer) 
                    }
                    
                    $i++

                }

                # return value
                New-Object FolderAgeResult -Property @{
                    Path = $Folder
                    LastWriteTime = $LastWriteTime
                    OlderThan = ($LastWriteTime -lt $TargetDate)
                }

            }
        }
    }

    END {
        # function closing phase
        Write-Verbose -Message "$(Get-Date -f T) $FunctionName finished"
}
    
}