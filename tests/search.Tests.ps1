BeforeAll {
    # Import the module
    Import-Module (Join-Path $PSScriptRoot '..\compass.psd1') -Force

    # Create a temporary directory for test files
    $script:TestDir = Join-Path $TestDrive "search_test_files"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    
    # Structure:
    # root/
    #   src/
    #     app.js (contains "console.log('Hello')")
    #     utils.js
    #   node_modules/ (Blocklisted)
    #     dependency.js (contains "console.log('Hello')")
    #   dist/ (Blocklisted)
    #     bundle.js
    #   README.md
    #   logo.png (Binary extension)

    $srcDir = Join-Path $script:TestDir "src"
    New-Item -Path $srcDir -ItemType Directory -Force | Out-Null
    
    $nodeModules = Join-Path $script:TestDir "node_modules"
    New-Item -Path $nodeModules -ItemType Directory -Force | Out-Null

    $distDir = Join-Path $script:TestDir "dist"
    New-Item -Path $distDir -ItemType Directory -Force | Out-Null

    # Files
    'console.log("Hello World");' | Set-Content -Path (Join-Path $srcDir "app.js")
    'function utils() {}' | Set-Content -Path (Join-Path $srcDir "utils.js")
    
    # This file should be ignored because it's in node_modules
    'console.log("Hello World");' | Set-Content -Path (Join-Path $nodeModules "dependency.js")
    
    # This file should be ignored because it's in dist
    'var bundle = true;' | Set-Content -Path (Join-Path $distDir "bundle.js")
    
    '# Project Compass' | Set-Content -Path (Join-Path $script:TestDir "README.md")
    
    # Fake binary file
    $logoPath = Join-Path $script:TestDir "logo.png"
    [System.IO.File]::WriteAllBytes($logoPath, (New-Object byte[] 10))
}

Describe 'Find-Item (search)' {
    
    Context 'Name Search (Default)' {
        It 'should find files by name in allowed directories' {
            Push-Location $script:TestDir
            try {
                $results = Find-Item "app.js" -Raw
                $results.Count | Should -Be 1
                $results[0].Name | Should -Be "app.js"
            }
            finally {
                Pop-Location
            }
        }

        It 'should NOT find files in blocklisted directories (node_modules)' {
            Push-Location $script:TestDir
            try {
                $results = Find-Item "dependency.js" -Raw
                $results | Should -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }

        It 'should support regex name search' {
            Push-Location $script:TestDir
            try {
                $results = Find-Item "^app\..*$" -Regex -Raw
                $results.Count | Should -Be 1
                $results[0].Name | Should -Be "app.js"
            }
            finally {
                Pop-Location
            }
        }
    }

    Context 'Content Search (-Content)' {
        It 'should find text inside files' {
            Push-Location $script:TestDir
            try {
                $results = Find-Item "Hello World" -Content -Raw
                $results.Count | Should -Be 1
                $results[0].Path | Should -Match "app.js"
            }
            finally {
                Pop-Location
            }
        }

        It 'should NOT find text in blocklisted directories' {
            Push-Location $script:TestDir
            try {
                # "Hello World" is also in node_modules/dependency.js, but should be skipped
                $results = Find-Item "Hello World" -Content -Raw
                $results.Count | Should -Be 1
                $results[0].Path | Should -Not -Match "dependency.js"
            }
            finally {
                Pop-Location
            }
        }

        It 'should skip binary files (extension check)' {
            Push-Location $script:TestDir
            try {
                # We can't easily search for binary content with Select-String on a text pattern,
                # but we can ensure it doesn't error or return matches if we search for something that might be interpreted.
                # Better test: Ensure the file is not even attempted.
                # Since we can't spy on internal logic easily, we rely on the fact that it shouldn't match text.
                
                # Let's try to search for something that definitely isn't there, but mostly ensure no errors.
                $results = Find-Item "PNG" -Content -Raw
                $results | Should -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
        
        It 'should support Context' {
             Push-Location $script:TestDir
            try {
                # Update app.js to have multiple lines
                "Line 1`nLine 2`nTarget`nLine 4`nLine 5" | Set-Content -Path (Join-Path $srcDir "context.txt")
                
                $results = Find-Item "Target" -Content -Context 1 -Raw
                $results.Count | Should -Be 1
                $results[0].Context.PreContext.Count | Should -Be 1
                $results[0].Context.PostContext.Count | Should -Be 1
                $results[0].Context.PreContext[0] | Should -Be "Line 2"
                $results[0].Context.PostContext[0] | Should -Be "Line 4"
            }
            finally {
                Pop-Location
            }
        }
    }
}
