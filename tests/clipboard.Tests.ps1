BeforeAll {
    # Import the module
    Import-Module (Join-Path $PSScriptRoot '..\compass.psd1') -Force

    # Create a temporary directory for test files
    $script:TestDir = Join-Path $TestDrive "clipboard_test_files"
    New-Item -Path $script:TestDir -ItemType Directory -Force | Out-Null
    
    # Create source files
    $file1 = Join-Path $script:TestDir "file1.txt"
    'content1' | Set-Content -Path $file1
    
    $file2 = Join-Path $script:TestDir "file2.txt"
    'content2' | Set-Content -Path $file2

    # Create destination directory
    $script:DestDir = Join-Path $TestDrive "clipboard_dest"
    New-Item -Path $script:DestDir -ItemType Directory -Force | Out-Null
}

Describe 'Clipboard Commands' {
    Context 'Copy-FilesToBuffer (ccp)' {
        It 'should add files to the clipboard' {
            Copy-FilesToBuffer -Path $script:TestDir\file1.txt
            
            # Accessing internal state via a public function or just testing behavior?
            # Since state is internal, we test behavior via Paste.
            # But we can check if Paste works.
        }
    }

    Context 'Paste-Files (pp)' {
        It 'should paste copied files' {
            Copy-FilesToBuffer -Path $script:TestDir\file1.txt
            
            Push-Location $script:DestDir
            try {
                Paste-Files
            }
            finally {
                Pop-Location
            }
            
            Test-Path (Join-Path $script:DestDir "file1.txt") | Should -Be $true
            Get-Content (Join-Path $script:DestDir "file1.txt") | Should -Be 'content1'
        }

        It 'should paste multiple files' {
            Copy-FilesToBuffer -Path "$script:TestDir\file1.txt", "$script:TestDir\file2.txt"
            
            $multiDest = Join-Path $TestDrive "multi_dest"
            New-Item -Path $multiDest -ItemType Directory -Force | Out-Null
            
            Push-Location $multiDest
            try {
                Paste-Files
            }
            finally {
                Pop-Location
            }
            
            Test-Path (Join-Path $multiDest "file1.txt") | Should -Be $true
            Test-Path (Join-Path $multiDest "file2.txt") | Should -Be $true
        }
    }

    Context 'Cut-FilesToBuffer (ccut)' {
        It 'should move files on paste' {
            $cutFile = Join-Path $script:TestDir "cut_me.txt"
            'cut content' | Set-Content -Path $cutFile
            
            Cut-FilesToBuffer -Path $cutFile
            
            $cutDest = Join-Path $TestDrive "cut_dest"
            New-Item -Path $cutDest -ItemType Directory -Force | Out-Null
            
            Push-Location $cutDest
            try {
                Paste-Files
            }
            finally {
                Pop-Location
            }
            
            Test-Path (Join-Path $cutDest "cut_me.txt") | Should -Be $true
            Test-Path $cutFile | Should -Be $false
        }
    }
}
