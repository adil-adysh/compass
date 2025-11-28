BeforeAll {
    . $PSScriptRoot/../Public/Select-Copy.ps1
    
    # Mock Set-Clipboard to verify output without affecting system clipboard
    function Set-Clipboard {
        param([string]$Value)
        $Script:LastClipboardValue = $Value
    }
}

Describe "Select-Copy (scopy)" {
    Context "Slice Mode" {
        BeforeAll {
            $inputData = 1..100 | ForEach-Object { "Line $_" }
        }

        It "Selects First N lines" {
            $result = $inputData | Select-Copy -First 5 -PassThru
            $result | Should -Match "Line 1"
            $result | Should -Match "Line 5"
            ($result -split [Environment]::NewLine).Count | Should -Be 5
        }

        It "Selects Last N lines" {
            $result = $inputData | Select-Copy -Last 5 -PassThru
            $result | Should -Match "Line 96"
            $result | Should -Match "Line 100"
            ($result -split [Environment]::NewLine).Count | Should -Be 5
        }

        It "Selects Range" {
            $result = $inputData | Select-Copy -Range 0,9 -PassThru
            $result | Should -Match "Line 1"
            $result | Should -Match "Line 10"
            ($result -split [Environment]::NewLine).Count | Should -Be 2
        }

        It "Combines First and Last" {
            $result = $inputData | Select-Copy -First 2 -Last 2 -PassThru
            $lines = $result -split [Environment]::NewLine
            $lines.Count | Should -Be 4
            $lines[0] | Should -Be "Line 1"
            $lines[3] | Should -Be "Line 100"
        }
    }

    Context "Search Mode" {
        BeforeAll {
            $inputData = @(
                "Start"
                "Error: Something bad"
                "Detail 1"
                "Detail 2"
                "End"
                "Normal"
                "Error: Another one"
                "Detail 3"
            )
        }

        It "Finds pattern" {
            $result = $inputData | Select-Copy -Pattern "Error" -PassThru
            $lines = $result -split [Environment]::NewLine
            $lines.Count | Should -Be 2
            $lines[0] | Should -Be "Error: Something bad"
            $lines[1] | Should -Be "Error: Another one"
        }

        It "Applies Context" {
            $result = $inputData | Select-Copy -Pattern "Error" -Context 1 -PassThru
            $lines = $result -split [Environment]::NewLine
            # Match 1: Error (1), Context (0, 2) -> Start, Error, Detail 1
            # Match 2: Error (6), Context (5, 7) -> Normal, Error, Detail 3
            $lines.Count | Should -Be 6
            $lines[0] | Should -Be "Start"
            $lines[2] | Should -Be "Detail 1"
        }

        It "Merges overlaps (Merge=$true)" {
            # Match at 1 (Error), Context 1 -> 0,1,2
            # Match at 6 (Error), Context 1 -> 5,6,7
            # No overlap here.
            
            # Let's try overlapping
            # Data: 0,1,2,3,4
            # Match 1, Match 2. Context 1.
            # 1 -> 0,1,2
            # 2 -> 1,2,3
            # Union -> 0,1,2,3
            
            $overlapData = 1..5 | ForEach-Object { "Line $_" }
            # Line 1, Line 2, Line 3, Line 4, Line 5
            # Indices: 0, 1, 2, 3, 4
            
            # Pattern matches Line 2 (idx 1) and Line 3 (idx 2)
            $result = $overlapData | Select-Copy -Pattern "Line [23]" -Context 1 -PassThru
            $lines = $result -split [Environment]::NewLine
            
            # Match idx 1 -> 0,1,2
            # Match idx 2 -> 1,2,3
            # Union -> 0,1,2,3 (Line 1..Line 4)
            
            $lines.Count | Should -Be 4
            $lines[0] | Should -Be "Line 1"
            $lines[3] | Should -Be "Line 4"
            $lines -notcontains "---" | Should -Be $true
        }

        It "Inserts separators (Merge=$false)" {
            # Match at 1 (Error), Context 0 -> 1
            # Match at 6 (Error), Context 0 -> 6
            # Gap between 1 and 6. Should insert ---
            
            $result = $inputData | Select-Copy -Pattern "Error" -Merge:$false -PassThru
            $lines = $result -split [Environment]::NewLine
            
            # Error 1
            # ---
            # Error 2
            
            $lines.Count | Should -Be 3
            $lines[1] | Should -Be "---"
        }
    }
}
