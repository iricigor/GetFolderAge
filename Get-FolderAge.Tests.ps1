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
}


#
# Check functionality, real tests
#

Describe "Proper $CommandName Functionality" {

    It 'Throws an error for non-existing folder' {
        Get-Item 'NonExistingFolder' -ea 0 | Should -Be $null
        {Get-FolderAge -FolderName NonExistingFolder -ea Stop} | Should -Throw
    }

    It 'Runs without an error for existing folder' {
        New-Item 'TestFolder' -ItemType Directory -Force | Out-Null
        Get-FolderAge -FolderName 'TestFolder' | Should -Not -Be $null
    }

    It 'Returns different value if we update test folder' {
        $SubFolder = New-Item (Join-Path 'TestFolder' 'TestSubFolder') -ItemType Directory -Force
        $Result1 = Get-FolderAge -FolderName 'TestFolder'
        $Result2 = Get-FolderAge -FolderName ($SubFolder.FullName)
        $Result2 | Should -Not -Be $null
        $Result2 | Should -Not -BeExactly $Result1
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
        $SubFolder = Get-ChildItem 'TestFolder' -Directory
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
        Get-FolderAge -FolderName 'TestFolder' -TestSubFolders -OutputFile 'TestFolder\AgeResults.csv' | Out-Null
        'TestFolder\AgeResults.csv' | Should -Exist
    }

    It 'Cutoff should add Modified result' {
        Get-FolderAge -FolderName 'TestFolder' | Select -Expand Modified | Should -Be $null
        Get-FolderAge -FolderName 'TestFolder' -CutOffDays 1 | Select -Expand Modified | Should -Not -Be $null
    }

    It 'Cutoff with 0 and 1 value should be different' {
        $Result0 = Get-FolderAge -FolderName 'TestFolder' -CutOffDays 0
        $Result1 = Get-FolderAge -FolderName 'TestFolder' -CutOffDays 1
        $Result0.Modified -eq $Result1.Modified | Should -Be $false
    }

    # TODO: Test 1st level only should give different result if update deep inside
    # TODO: Add documentation validation test

    It 'Cleans up test folders' {
        Remove-Item 'TestFolder' -Force -Recurse
    }
}

# Describe "Proper $CommandName Documentation" {

#     $CmdDef = Get-Command -Name $CommandName -ea 0
#     $CmdFake = Get-Command -Name 'FakeCommandName' -ea 0

#     It "Command should exist" {
#         $CmdDef | Should -Not -Be $null
#         $CmdFake | Should -Be $null
#     }

#     It 'Updates documentation and finds no diff' {
#         if (!(Get-Module platyPS -List -ea 0)) {Install-Module platyPS -Force -Scope CurrentUser}
# 		Import-Module platyPS
#         . .\Get-FolderAge.ps1 # Re-import function
#         # update documentation
#         New-MarkdownHelp -Command $CommandName -Force -OutputFolder . -wa 0
#         $diff = git diff .\Get-FolderAge.md
#         $diff | Should -Be $null
#     }

# }