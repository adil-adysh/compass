BeforeAll {
    # Import the module
    Import-Module (Join-Path $PSScriptRoot '..\compass.psd1') -Force

    # Create a temporary directory for test files
    $script:TestDir = Join-Path $TestDrive "test_files"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    
    # Define a consistent 'Now' for predictable date calculations
    $script:Now = Get-Date -Date '2025-11-28 12:00:00'
    
    # --- Create Test Files ---
    # Today
    $todaySmall = Join-Path $script:TestDir "today_small.txt"
    'small' | Set-Content -Path $todaySmall
    (Get-Item $todaySmall).LastWriteTime = $script:Now.AddHours(-1)

    $todayLarge = Join-Path $script:TestDir "today_large.log"
    'l' * 20MB | Set-Content -Path $todayLarge
    (Get-Item $todayLarge).LastWriteTime = $script:Now.AddHours(-2)
    
    # Yesterday
    $yesterday = Join-Path $script:TestDir "yesterday.txt"
    'yesterday' | Set-Content -Path $yesterday
    (Get-Item $yesterday).LastWriteTime = $script:Now.AddDays(-1)

    $yesterdayAnother = Join-Path $script:TestDir "yesterday_another.ps1"
    'script' | Set-Content -Path $yesterdayAnother
    (Get-Item $yesterdayAnother).LastWriteTime = $script:Now.AddDays(-1).AddHours(1)
    
    # 2 Days ago
    $twoDaysAgo = Join-Path $script:TestDir "two_days_ago.txt"
    'old' | Set-Content -Path $twoDaysAgo
    (Get-Item $twoDaysAgo).LastWriteTime = $script:Now.AddDays(-2)
    
    # A week ago
    $weekAgo = Join-Path $script:TestDir "week_ago.log"
    'w' * 5MB | Set-Content -Path $weekAgo
    (Get-Item $weekAgo).LastWriteTime = $script:Now.AddDays(-7)
}

Describe 'Show-Recent Command' {
    BeforeEach {
        # Mock Get-Date to return consistent time for each test
        Mock Get-Date { return $script:Now } -ModuleName compass
    }

    Context '-Today switch' {
        It 'should find files modified today' {
            $results = Show-Recent -Path $script:TestDir -Today
            $results.Count | Should -Be 2
            $results.Name | Should -Contain 'today_small.txt'
            $results.Name | Should -Contain 'today_large.log'
        }

        It 'should return objects with correct properties' {
            $results = Show-Recent -Path $script:TestDir -Today
            $results[0].PSObject.Properties.Name | Should -Contain 'Name'
            $results[0].PSObject.Properties.Name | Should -Contain 'Type'
            $results[0].PSObject.Properties.Name | Should -Contain 'Size'
            $results[0].PSObject.Properties.Name | Should -Contain 'Modified'
            $results[0].PSObject.Properties.Name | Should -Contain 'Path'
        }
    }

    Context '-Yesterday switch' {
        It 'should find files modified yesterday' {
            $results = Show-Recent -Path $script:TestDir -Yesterday
            $results.Count | Should -Be 2
            $results.Name | Should -Contain 'yesterday.txt'
            $results.Name | Should -Contain 'yesterday_another.ps1'
        }
    }

    Context '-Days parameter' {
        It 'should find files from the last 3 days (default)' {
            $results = Show-Recent -Path $script:TestDir
            $results.Count | Should -Be 5
        }
        
        It 'should find files from the last 8 days' {
            $results = Show-Recent -Path $script:TestDir -Days 8
            $results.Count | Should -Be 6
        }

        It 'should validate Days parameter range' {
            { Show-Recent -Path $script:TestDir -Days 0 } | Should -Throw
            { Show-Recent -Path $script:TestDir -Days 366 } | Should -Throw
        }
    }

    Context 'Content Filters' {
        It 'should filter by a single extension' {
            $results = Show-Recent -Path $script:TestDir -Days 8 -Extension '*.log'
            $results.Count | Should -Be 2
            $results.Name | Should -Contain 'today_large.log'
            $results.Name | Should -Contain 'week_ago.log'
        }

        It 'should filter by multiple extensions' {
            $results = Show-Recent -Path $script:TestDir -Days 8 -Extension '*.log', '*.ps1'
            $results.Count | Should -Be 3
        }

        It 'should filter by MinSize' {
            $results = Show-Recent -Path $script:TestDir -Days 8 -MinSize 10MB
            $results.Count | Should -Be 1
            $results.Name | Should -Be 'today_large.log'
        }

        It 'should filter by MaxSize' {
            $results = Show-Recent -Path $script:TestDir -Days 8 -MaxSize 10MB
            $results.Count | Should -Be 5
        }
        
        It 'should combine multiple filters' {
            $results = Show-Recent -Path $script:TestDir -Today -Extension '*.log' -MinSize 15MB
            $results.Count | Should -Be 1
            $results.Name | Should -Be 'today_large.log'
        }

        It 'should throw error when MinSize > MaxSize' {
            { Show-Recent -Path $script:TestDir -MinSize 10MB -MaxSize 5MB } | Should -Throw '*MinSize cannot be greater than MaxSize*'
        }
    }

    Context 'Path validation' {
        It 'should throw error for non-existent path' {
            { Show-Recent -Path 'C:\NonExistentPath123456789' } | Should -Throw '*Path not found*'
        }

        It 'should work with relative path' {
            Push-Location $script:TestDir
            try {
                $results = Show-Recent -Path '.' -Days 8
                $results.Count | Should -BeGreaterThan 0
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Edge Cases' {
        It 'should return warning when no files are found' {
            $warningMessage = $null
            Show-Recent -Path $script:TestDir -Days 8 -Extension '*.nonexistent' -WarningVariable warningMessage -WarningAction SilentlyContinue
            $warningMessage | Should -Match 'No files found matching the specified criteria'
        }

        It 'should handle empty directory' {
            $emptyDir = Join-Path $TestDrive 'empty'
            New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
            $warningMessage = $null
            Show-Recent -Path $emptyDir -WarningVariable warningMessage -WarningAction SilentlyContinue
            $warningMessage | Should -Match 'No files found'
        }
    }

    Context 'Alias' {
        It 'should have "recent" alias available' {
            $alias = Get-Alias -Name 'recent' -ErrorAction SilentlyContinue
            $alias | Should -Not -BeNullOrEmpty
            $alias.ResolvedCommandName | Should -Be 'Show-Recent'
        }
    }

    Context 'Output formatting' {
        It 'should format file sizes correctly' {
            $results = Show-Recent -Path $script:TestDir -Days 8
            $results | ForEach-Object {
                $_.Size | Should -Match '^\d+(\.\d{2})?\s+(B|KB|MB|GB|TB)$'
            }
        }

        It 'should sort results by LastWriteTime descending' {
            $results = Show-Recent -Path $script:TestDir -Days 8
            $dates = $results.Modified
            for ($i = 0; $i -lt ($dates.Count - 1); $i++) {
                [DateTime]$dates[$i] | Should -BeGreaterOrEqual ([DateTime]$dates[$i + 1])
            }
        }
    }

    Context 'Verbose output' {
        It 'should produce verbose output when requested' {
            $verboseOutput = Show-Recent -Path $script:TestDir -Verbose 4>&1
            $verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] } | Should -Not -BeNullOrEmpty
        }
    }
}
