function Find-Item {
    <#
    .SYNOPSIS
        Developer-first search tool for files and content.
    .DESCRIPTION
        Searches for files by name or content, skipping common build/dependency directories (node_modules, .git, etc.) for performance.
    .EXAMPLE
        search "LoginController"
        Finds files with "LoginController" in the name.
    .EXAMPLE
        search "TODO" -Content
        Finds "TODO" inside files.
    .EXAMPLE
        search "error" -Content -Context 2
        Finds "error" inside files and shows 2 lines of context.
    #>
    [CmdletBinding()]
    [Alias('search')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Pattern,

        [switch]$Content,

        [int]$Context = 0,

        [switch]$Regex,

        [switch]$CaseSensitive,

        [switch]$Raw
    )

    begin {
        $Blocklist = @(
            '.git', '.svn', '.hg', '.vscode', '.idea',
            'node_modules', 'bower_components', 'packages',
            'bin', 'obj', 'dist', 'build', 'out', 'target',
            '__pycache__', 'vendor', 'terraform.tfstate.d'
        )

        $BinaryExtensions = @(
            '.exe', '.dll', '.iso', '.png', '.zip', '.jpg', '.jpeg', '.gif', '.bmp', '.ico',
            '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.7z', '.tar', '.gz', '.rar',
            '.pdb', '.suo', '.cache', '.class', '.jar', '.war', '.ear', '.mp3', '.mp4', '.mov'
        )

        $MaxFileSize = 50MB
        $StartPath = (Get-Location).ProviderPath
        $Queue = [System.Collections.Generic.Queue[string]]::new()
        $Queue.Enqueue($StartPath)

        # Compile Regex for highlighting/matching
        $RegexOptions = [System.Text.RegularExpressions.RegexOptions]::None
        if (-not $CaseSensitive) {
            $RegexOptions = $RegexOptions -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        }

        if (-not $Regex) {
            $MatchPattern = [System.Text.RegularExpressions.Regex]::Escape($Pattern)
        } else {
            $MatchPattern = $Pattern
        }
        
        $SearchPatternObj = try {
            [System.Text.RegularExpressions.Regex]::new($MatchPattern, $RegexOptions)
        } catch {
            Write-Error "Invalid Regex Pattern: $_"
            return
        }
    }

    process {
        while ($Queue.Count -gt 0) {
            $currentPath = $Queue.Dequeue()
            
            try {
                $dirInfo = [System.IO.DirectoryInfo]::new($currentPath)
                $entries = $dirInfo.GetFileSystemInfos()
            } catch {
                Write-Verbose "Access denied or error reading: $currentPath"
                continue
            }

            foreach ($entry in $entries) {
                if ($entry.Attributes.HasFlag([System.IO.FileAttributes]::Directory)) {
                    if ($Blocklist -notcontains $entry.Name) {
                        $Queue.Enqueue($entry.FullName)
                    }
                } else {
                    # It's a file
                    if ($Content) {
                        # Content Search Mode
                        if ($BinaryExtensions -contains $entry.Extension) { continue }
                        if ($entry.Length -gt $MaxFileSize) { continue }

                        $slsParams = @{
                            Path = $entry.FullName
                            Pattern = $MatchPattern
                            CaseSensitive = $CaseSensitive
                            Context = $Context
                            AllMatches = $false
                        }
                        
                        $matches = Select-String @slsParams
                        
                        if ($matches) {
                            if ($Raw) {
                                $matches | Write-Output
                            } else {
                                Format-ContentMatch -Matches $matches -PatternObj $SearchPatternObj -File $entry.FullName
                            }
                        }

                    } else {
                        # Name Search Mode
                        if ($SearchPatternObj.IsMatch($entry.Name)) {
                            if ($Raw) {
                                Write-Output $entry
                            } else {
                                Format-NameMatch -FileInfo $entry -Root $StartPath
                            }
                        }
                    }
                }
            }
        }
    }
}
