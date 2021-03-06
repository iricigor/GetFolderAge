#
#  Pester test for Get-FolderAge.ps1
#

#
# Fake test
#

Describe "Fake-Test" {
    It "Should be fixed by developer" {
        $true | Should -Be $true
    }
}



#
# Check definition
#

. .\Get-FolderAge.ps1 # Import function
$CommandName = 'Get-FolderAge'
$ParameterNames = @('FolderName','InputFile')

Describe "Function $CommandName Definition" {

    $CmdDef = Get-Command -Name $CommandName -ea 0
    $CmdFake = Get-Command -Name 'FakeCommandName' -ea 0

    It "Command should exist" {
        $CmdDef | Should -Not -Be $null
        $CmdFake | Should -Be $null
    }

    It 'Command should have parameters' {
        $CmdDef.Parameters.Keys | Should -Not -Contain 'FakeParameterName'
        foreach ($P1 in $ParameterNames) {
            $CmdDef.Parameters.Keys | Should -Contain $P1
        }
    }

    It 'Command should have alias' {
        Get-Alias -Definition $CommandName -ea 0 | Should -Not -Be $null
    }

}


#
# Check functionality, real tests
#

Describe "Proper $CommandName Functionality" {

    It 'Throws an error for non-existing folder' {
        Get-Item 'NonExistingFolder' -ea 0 | Should -Be $null
        Get-Item 'TestFolder' -ea 0 | Should -Be $null # we will create it later, if existing tests are not valid
        {Get-FolderAge -FolderName NonExistingFolder -ea Stop} | Should -Throw
    }

    It 'Runs without an error for existing folder' {
        New-Item 'TestFolder' -ItemType Directory -Force | Out-Null
        Get-FolderAge -FolderName 'TestFolder' | Should -Not -Be $null
    }

    It 'Returns different value if we update test folder' {
        $Result1 = Get-FolderAge -FolderName 'TestFolder'
        Start-Sleep -Seconds 2 # not to get into strange comparison issues
        New-Item (Join-Path 'TestFolder' 'TestSubFolder') -ItemType Directory -Force | Out-Null
        $Result2 = Get-FolderAge -FolderName 'TestFolder'
        $Result2 | Should -Not -Be $null
        $Result2 | Should -Not -BeExactly $Result1
        $Result2.LastWriteTime -gt $Result1.LastWriteTime | Should -Be $true
    }

    It 'Running with text file input should give the same result' {
        $InputFile = New-Item (Join-Path 'TestFolder' 'TestFile.txt') -ItemType File -Force
        'TestFolder' | Out-File ($InputFile.FullName)
        $Result1 = Get-FolderAge -FolderName 'TestFolder'
        $Result2 = Get-FolderAge -InputFile ($InputFile.FullName)
        $Result2 | Should -Not -Be $null
        $Result2 | Should -Not -Be $Result1
    }

    It 'Accepts pipeline input' {
        $Result1 = Get-FolderAge -FolderName 'TestFolder'
        $Result2 = 'TestFolder' | Get-FolderAge
        $Result2 | Should -Not -Be $null
        $Result2.LastWriteTime | Should -BeExactly $Result1.LastWriteTime
    }

    It 'Can check first level folders' {
        $SubFolder = Get-ChildItem 'TestFolder' | ? {$_.PSIsContainer}
        @($SubFolder).Count | Should -Be 1 -Because ($SubFolder.Name -join ',')

        $Result1 = Get-FolderAge -FolderName ($SubFolder.FullName)
        $Result2 = Get-FolderAge -FolderName 'TestFolder' -TestSubFolders
        $Result2 | Should -Not -Be $null
        $Result2.LastWriteTime | Should -BeExactly $Result1.LastWriteTime
    }

    It 'Returns array if more subfolders' {
        New-Item (Join-Path 'TestFolder' 'TestSubFolder2') -ItemType Directory -Force | Out-Null
        (Get-FolderAge -FolderName 'TestFolder' -TestSubFolders).Count | Should -Be 2
    }

    It 'Generates file output if specified' {
        $OutputFile = Join-Path 'TestFolder' 'AgeResults.csv'
        Get-FolderAge -FolderName 'TestFolder' -TestSubFolders -OutputFile $OutputFile | Out-Null
        $OutputFile | Should -Exist
    }

    It 'Cutoff should add Modified result' {
        (Get-FolderAge -FolderName 'TestFolder').Modified | Should -Be $null
        Get-FolderAge -FolderName 'TestFolder' -CutOffDays 1 | Select -Expand Modified | Should -Not -Be $null
    }

    It 'Cutoff with 0 and 1 value should be different' {
        Start-Sleep -Seconds 2 # as tests are running fast, we need to sleep 2 seconds for -CutOffDays 0 to do what we want
        $Result0 = Get-FolderAge -FolderName 'TestFolder' -CutOffDays 0
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -CutOffDays 1
        $Result0.Modified -eq $Result1.Modified | Should -Be $false
    }

    It 'Expands relative path' {
        Get-FolderAge -FolderName '.' | Select -Expand Path | Should -Not -Be '.'
    }

    It 'Quick test does not search all files' {
        New-Item -Path (Join-Path 'TestFolder' 'TestSubFolder2') -Name 'DeepFile.txt' -ItemType File -Force | Out-Null
        $Result0 = Get-FolderAge -FolderName 'TestFolder'
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -QuickTest
        $Result0.TotalFiles -gt $Result1.TotalFiles | Should -Be $true -Because "$($Result0.TotalFiles) and $($Result1.TotalFiles) should not be the same"
    }

    It 'Exits as soon as it finds modified file' {
        $Result0 = Get-FolderAge -FolderName 'TestFolder'
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -CutOffDays 1
        $Result0.TotalFiles -gt $Result1.TotalFiles | Should -Be $true -Because "$($Result0.TotalFiles) and $($Result1.TotalFiles) should not be the same"
    }

    It 'Excludes requested folders' {
        New-Item -Path 'TestFolder' -Name 'ExcludedFolder1' -ItemType Directory -Force | Out-Null
        New-Item -Path 'TestFolder' -Name 'ExcludedFolder2' -ItemType Directory -Force | Out-Null
        Start-Sleep 1
        New-Item -Path (Join-Path 'TestFolder' 'ExcludedFolder1') -Name 'ExcludedFile.txt' -ItemType File -Force | Out-Null
        New-Item -Path (Join-Path 'TestFolder' 'ExcludedFolder2') -Name 'ExcludedFile.txt' -ItemType File -Force | Out-Null
        $Result0 = Get-FolderAge -FolderName 'TestFolder'
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -Exclude 'ExcludedFolder1','ExcludedFolder2'
        # Last item can be either ExcludedFolder or  ExcludedFile.txt
        $Result0.LastItem | Should -Match 'ExcludedFolder' -Because "$($Result0.LastItem)"
        $Result1.LastItem | Should -Not -Match 'ExcludedFolder' -Because "$($Result1.LastItem)"
        $Result0.TotalFiles - $Result1.TotalFiles | Should -Be 4
    }

    It 'Gives the same results if Threads are used' {
        $Result0 = Get-FolderAge -FolderName 'TestFolder'
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -Threads 2 -ea 0 # ignore no threads 
        $Result0.TotalFiles -eq $Result1.TotalFiles | Should -Be $true
    }

    It 'Runs Threads with the same output file' {
        $File1 = Join-Path 'TestFolder' 'NoThreads.csv'
        $File2 = Join-Path 'TestFolder' 'WithThreads.csv'
        $Result0 = Get-FolderAge -FolderName 'TestFolder' -TestSubFolders -OutputFile $File1
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -TestSubFolders -OutputFile $File2 -Threads 2 -ea 0
        $Count1 = (Get-Content $File1).Count
        $Count2 = (Get-Content $File2).Count
        $Count2 | Should -Be $Count1 -Because "NoThreads and WithThreads should be the same"
        $Count2 | Should -Be ($Result1.Count + 1) -Because "Pipeline and File should differ by 1 (header line)"
    }

    if ((Get-PSDrive L -ev PSDriveErr -ea 0) -or ($PSVersionTable.PSVersion -lt '5.0')) {
        # Skipping long path tests if PS v2 or drive L: exists
    } else {
        It 'Processes long names' {
            # assign 2 long names
            $Name1 = (1..200 | %{[char](get-random -InputObject (65..90))}) -join '' # 100 random characters
            $Name2 = (1..200 | %{[char](get-random -InputObject (65..90))}) -join ''
            # setup structure
            $LongFolder = New-Item (Join-Path 'TestFolder' $Name1) -ItemType Directory
            if ($IsLinux) {
                $LongPath = $LongFolder.FullName
            } else {
                $LongPath = 'L:'
                subst $LongPath ($LongFolder.FullName)
                Get-PSDrive | Out-Null # just to rescan drives
            }
            $LongFile = New-Item (Join-Path $LongPath $Name2) -ItemType File
            Start-Sleep -Seconds 2
            'SomeText' | Out-File ($LongFile.FullName) -Append
            # run tests
            {Get-FolderAge -FolderName 'TestFolder'} | Should -Not -Throw
            $Result = Get-FolderAge -FolderName 'TestFolder'
            $Result | Should -Not -Be $null
            $Result.LastItem -match $Name1 | Should -Be $true -Because "$($Result.LastItem) should be part of $Name1 folder"
            # clean up after the test
            if ($IsLinux) {
                Remove-Item $LongPath -Force -Recurse
            } else {
                Remove-Item L:\$Name2 -Force
                subst $LongPath /D
                Remove-Item ($LongFolder.FullName) -Force
            }
        }    
    }

}

Describe "V2 Compatibility check for $CommandName" {
    # this tes runs only if there is powershell version 2 installed
    # it should be possible at least on local test environment

    try {
        powershell -version 2  -NoProfile -NonInteractive -NoLogo -Command Write-Host Hello!
        if ($LASTEXITCODE) {throw 'PowerShell v.2 failed!'}
        # if above OK, proceed with test
        it 'runs v2 properly' {
            # import function and run function on the current folder; we just care not to throw an error
            {PowerShell -Version 2 -NoProfile -NonInteractive -NoLogo -Command ". .\Get-FolderAge.ps1; Get-FolderAge ."} | Should -Not -Throw
        }

        it 'running v2 gives the same result' {
            $ResultV5 = Get-FolderAge -FolderName .
            PowerShell -Version 2 -NoProfile -NonInteractive -NoLogo -Command ". .\Get-FolderAge.ps1; Get-FolderAge . -OutputFile .\TestFolder\V2.csv"
            $ResultV2 = Import-Csv 'TestFolder\V2.csv'
            #$ResultV2.LastWriteTime -eq $ResultV5.LastWriteTime | Should -Be $true # it can be false because of formatting to/from csv
            $ResultV2.TotalFiles -eq $ResultV5.TotalFiles | Should -Be $true
        }

    } catch {
        # skip test as v2 cannot be run
    }
}

Describe "Proper $CommandName Documentation" {

    $CmdDef = Get-Command -Name $CommandName -ea 0
    $CmdFake = Get-Command -Name 'FakeCommandName' -ea 0

    It "Command should exist" {
        $CmdDef | Should -Not -Be $null
        $CmdFake | Should -Be $null
    }

    It 'Updates documentation and finds no diff' {
        #New-MarkdownHelp -Command $CommandName -Force -OutputFolder . -wa 0
        Update-MarkdownHelp -Path '.\Get-FolderAge.md' -WA 0 | Out-Null
        $diff = git diff .\Get-FolderAge.md
        $diff | Should -Be $null
    }

}

Describe "Clean after $CommandName testing" {

    It 'Cleans up test folders' {
        Remove-Item 'TestFolder' -Force -Recurse
    }

}
