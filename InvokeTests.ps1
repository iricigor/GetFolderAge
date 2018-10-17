#
# Script which invokes tests inside of Azure DevOps Pipelines
#

#
# Display diagnostic information
#

$PSVersionTable
Get-ChildItem Env:\

#
# Install Pester v4, if needed
#

if (!(Get-Module Pester -List | ? Version -ge 4.0.0)) {
    Write-Host "`nInstalling Pester"
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser -Repository PSGallery
    Get-Module Pester -List    
    Import-Module Pester
}

if (!(Get-Module PlatyPS -List | ? Version -ge 0.11.0)) {
    Write-Host "`nInstalling PlatyPS"
    Install-Module -Name PlatyPS -Force -Scope CurrentUser -Repository PSGallery
    Get-Module PlatyPS -List    
    Import-Module PlatyPS
}

if (!(Get-Module ThreadJob -List)) {
    Write-Host "`nInstalling ThreadJob"
    Install-Module -Name ThreadJob -Force -Scope CurrentUser -Repository PSGallery -ea 0 # not really required
    Get-Module ThreadJob -List    
    Import-Module ThreadJob
}

#
# Run Pester Tests
#

Write-Host "Run Pester tests"
$Result = Invoke-Pester -PassThru -OutputFile PesterTestResults.xml
if ($Result.failedCount -ne 0) {Write-Error "Pester returned errors"}