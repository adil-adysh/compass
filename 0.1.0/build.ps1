# Build and Release Script for Compass Module

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Build', 'Test', 'Publish', 'All')]
    [string]$Task = 'All',

    [Parameter()]
    [string]$OutputPath = '.\build',

    [Parameter()]
    [string]$Repository = 'PSGallery',

    [Parameter()]
    [string]$NuGetApiKey
)

function Invoke-Build {
    Write-Host '=== Building Module ===' -ForegroundColor Cyan
    
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Recurse -Force
    }
    
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    
    $modulePath = Join-Path $OutputPath 'compass'
    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
    
    Copy-Item -Path '.\compass.psd1' -Destination $modulePath
    Copy-Item -Path '.\compass.psm1' -Destination $modulePath
    Copy-Item -Path '.\README.md' -Destination $modulePath
    
    Write-Host "Module built successfully in: $modulePath" -ForegroundColor Green
}

function Invoke-Test {
    Write-Host '=== Running Tests ===' -ForegroundColor Cyan
    
    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Warning 'Pester not found. Installing...'
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    $testResults = Invoke-Pester -Path '.\tests\compass.Tests.ps1' -PassThru
    
    if ($testResults.FailedCount -gt 0) {
        throw "Tests failed: $($testResults.FailedCount) test(s) failed"
    }
    
    Write-Host "All tests passed! ($($testResults.PassedCount) tests)" -ForegroundColor Green
}

function Invoke-Publish {
    Write-Host '=== Publishing Module ===' -ForegroundColor Cyan
    
    if (-not $NuGetApiKey) {
        throw 'NuGetApiKey parameter is required for publishing'
    }
    
    Invoke-Build
    
    $modulePath = Join-Path $OutputPath 'compass'
    
    Publish-Module -Path $modulePath -Repository $Repository -NuGetApiKey $NuGetApiKey
    
    Write-Host "Module published successfully to $Repository" -ForegroundColor Green
}

# Main execution
try {
    switch ($Task) {
        'Build' {
            Invoke-Build
        }
        'Test' {
            Invoke-Test
        }
        'Publish' {
            Invoke-Publish
        }
        'All' {
            Invoke-Build
            Invoke-Test
        }
    }
    
    Write-Host "`n=== Task '$Task' completed successfully ===" -ForegroundColor Green
}
catch {
    Write-Error "Task '$Task' failed: $_"
    exit 1
}
