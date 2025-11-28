# PowerShell module compass

if (-not $Script:CompassClipboard) {
    $Script:CompassClipboard = @{
        Operation = $null
        Items = [System.Collections.Generic.List[string]]::new()
    }
}

function Show-Recent {
    <#
    .SYNOPSIS
        Finds recently modified files with advanced filtering options.

    .DESCRIPTION
        The Show-Recent cmdlet searches for files that have been modified within a specified time period.
        You can filter results by file extension, size, and specify different date ranges (today, yesterday, or custom days).

    .PARAMETER Today
        Find files modified today only.

    .PARAMETER Yesterday
        Find files modified yesterday only.

    .PARAMETER Days
        Find files modified within the last N days. Default is 3 days.

    .PARAMETER Extension
        Filter by file extension(s). Accepts wildcard patterns (*.txt, *.log, etc.).
        Can specify multiple extensions as an array.

    .PARAMETER MinSize
        Filter files larger than the specified size in bytes.
        Supports KB, MB, GB suffixes: 1KB, 5MB, 2GB.

    .PARAMETER MaxSize
        Filter files smaller than the specified size in bytes.
        Supports KB, MB, GB suffixes: 1KB, 5MB, 2GB.

    .PARAMETER Path
        The root path to search. Default is the current directory.

    .EXAMPLE
        Show-Recent
        Shows all files modified in the last 3 days (default) in the current directory.

    .EXAMPLE
        Show-Recent -Today
        Shows all files modified today.

    .EXAMPLE
        Show-Recent -Days 7 -Extension *.ps1, *.psm1
        Shows PowerShell files modified in the last 7 days.

    .EXAMPLE
        Show-Recent -Yesterday -MinSize 1MB -Extension *.log
        Shows log files larger than 1MB that were modified yesterday.

    .EXAMPLE
        recent -Path C:\Projects -Days 5
        Uses the alias 'recent' to find files in C:\Projects modified in the last 5 days.

    .NOTES
        Author: Unknown
        Version: 1.0.0
    #>
    [CmdletBinding(DefaultParameterSetName = 'Days')]
    [OutputType([PSCustomObject])]
    param(
        # Date Selectors
        [Parameter(ParameterSetName = 'Today')]
        [switch]$Today,

        [Parameter(ParameterSetName = 'Yesterday')]
        [switch]$Yesterday,

        [Parameter(ParameterSetName = 'Days')]
        [ValidateRange(1, 365)]
        [int]$Days = 3,

        # Content Filters
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Extension = @('*'),

        [Parameter()]
        [ValidateRange(0, [Int64]::MaxValue)]
        [Int64]$MinSize,

        [Parameter()]
        [ValidateRange(0, [Int64]::MaxValue)]
        [Int64]$MaxSize,

        # Scope
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.'
    )

    begin {
        # Validate Path exists
        if (-not (Test-Path -Path $Path)) {
            $exception = [System.IO.DirectoryNotFoundException]::new("Path not found: $Path")
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                'PathNotFound',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $Path
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        # Validate MinSize/MaxSize relationship
        if ($PSBoundParameters.ContainsKey('MinSize') -and
            $PSBoundParameters.ContainsKey('MaxSize') -and
            $MinSize -gt $MaxSize) {
            $exception = [System.ArgumentException]::new('MinSize cannot be greater than MaxSize')
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                'InvalidSizeRange',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        # Calculate Date Range
        $paramSet = $PSCmdlet.ParameterSetName
        Write-Verbose "Using Parameter Set: $paramSet"

        switch ($paramSet) {
            'Today' {
                $startDate = (Get-Date).Date
                $endDate = (Get-Date)
                $dateFilterDescription = 'Today'
            }
            'Yesterday' {
                $startDate = (Get-Date).AddDays(-1).Date
                $endDate = (Get-Date).Date.AddSeconds(-1)
                $dateFilterDescription = 'Yesterday'
            }
            'Days' {
                $startDate = (Get-Date).AddDays(-$Days)
                $endDate = (Get-Date)
                $dateFilterDescription = "in the last $Days days"
            }
        }

        # Build UI Feedback Header
        $filterParts = [System.Collections.Generic.List[string]]::new()

        if ($Extension -ne @('*') -and $Extension.Count -gt 0) {
            $filterParts.Add("of type '$($Extension -join ', ')'")
        }

        if ($PSBoundParameters.ContainsKey('MinSize')) {
            $friendlyMinSize = Format-FileSize -Bytes $MinSize
            $filterParts.Add("larger than $friendlyMinSize")
        }

        if ($PSBoundParameters.ContainsKey('MaxSize')) {
            $friendlyMaxSize = Format-FileSize -Bytes $MaxSize
            $filterParts.Add("smaller than $friendlyMaxSize")
        }

        $header = "Searching for files modified $dateFilterDescription"
        if ($filterParts.Count -gt 0) {
            $header += " $($filterParts -join ' and ')"
        }
        $header += " in '$Path'"
        Write-Host $header -ForegroundColor Green
    }

    process {
        try {
            # Build Get-ChildItem parameters
            $gciParams = @{
                Path = $Path
                Recurse = $true
                File = $true
                ErrorAction = 'SilentlyContinue'
            }

            # Fix: Only add Include if extensions are specified (not wildcard)
            if ($Extension -ne @('*') -and $Extension.Count -gt 0) {
                $gciParams['Include'] = $Extension
            }

            # Get files and filter by date
            $results = Get-ChildItem @gciParams |
                Where-Object { $_.LastWriteTime -ge $startDate -and $_.LastWriteTime -le $endDate }

            # Apply size filters if specified
            if ($PSBoundParameters.ContainsKey('MinSize')) {
                $results = $results | Where-Object { $_.Length -ge $MinSize }
            }

            if ($PSBoundParameters.ContainsKey('MaxSize')) {
                $results = $results | Where-Object { $_.Length -le $MaxSize }
            }

            # Format and output results
            if ($null -eq $results -or $results.Count -eq 0) {
                Write-Warning 'No files found matching the specified criteria.'
                return
            }

            $results | Sort-Object LastWriteTime -Descending | ForEach-Object {
                [PSCustomObject]@{
                    PSTypeName = 'Compass.RecentFile'
                    Name = $_.Name
                    Type = $_.Extension
                    Size = Format-FileSize -Bytes $_.Length
                    Modified = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                    Path = $_.DirectoryName
                }
            }
        } catch {
            $PSCmdlet.WriteError($_)
        }
    }
}

# Helper function to format file sizes
function Format-FileSize {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [Int64]$Bytes
    )

    switch ($Bytes) {
        { $_ -ge 1TB } { return '{0:N2} TB' -f ($Bytes / 1TB) }
        { $_ -ge 1GB } { return '{0:N2} GB' -f ($Bytes / 1GB) }
        { $_ -ge 1MB } { return '{0:N2} MB' -f ($Bytes / 1MB) }
        { $_ -ge 1KB } { return '{0:N2} KB' -f ($Bytes / 1KB) }
        default { return "$Bytes B" }
    }
}

function Resolve-CompassPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]$InputObject
    )

    $literalPath = switch ($InputObject) {
        { $_ -is [System.Management.Automation.PathInfo] } { $_.ProviderPath }
        { $_ -is [System.IO.FileSystemInfo] } { $_.FullName }
        default { [string]$InputObject }
    }

    try {
        $resolved = (Resolve-Path -LiteralPath $literalPath -ErrorAction Stop).ProviderPath
        Write-Verbose "Resolved clipboard item '$literalPath' -> '$resolved'"
        return $resolved
    } catch {
        Write-Warning "Skipping missing clipboard item: $literalPath"
        return $null
    }
}

function Copy-FilesToBuffer {
    <#
    .SYNOPSIS
        Buffer files and folders for copy operations in the Compass clipboard.
    .DESCRIPTION
        Accepts pipeline input (paths or FileSystemObjects), resolves absolute paths, and stores them for `Paste-Files`.
    .EXAMPLE
        Get-ChildItem -Path .\scripts | ccp
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Path', 'LiteralPath')]
        [Object]$InputObject
    )

    begin {
        $buffer = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $resolved = Resolve-CompassPath -InputObject $InputObject
        if ($resolved) {
            Write-Verbose "Buffering for copy: $resolved"
            $buffer.Add($resolved)
        }
    }

    end {
        if ($buffer.Count -eq 0) {
            Write-Warning 'No valid items were provided to copy to the clipboard.'
            return
        }

        $Script:CompassClipboard = @{
            Operation = 'Copy'
            Items = $buffer
        }

        Write-Host "📋 Copied $($buffer.Count) items"
    }
}

function Cut-FilesToBuffer {
    <#
    .SYNOPSIS
        Buffer files and folders for move operations in the Compass clipboard.
    .DESCRIPTION
        Resolves pipeline input to full paths and marks them for `Paste-Files` to perform a move later.
    .EXAMPLE
        ccut README.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Path', 'LiteralPath')]
        [Object]$InputObject
    )

    begin {
        $buffer = [System.Collections.Generic.List[string]]::new()
    }

    process {
        $resolved = Resolve-CompassPath -InputObject $InputObject
        if ($resolved) {
            Write-Verbose "Buffering for cut: $resolved"
            $buffer.Add($resolved)
        }
    }

    end {
        if ($buffer.Count -eq 0) {
            Write-Warning 'No valid items were provided to cut to the clipboard.'
            return
        }

        $Script:CompassClipboard = @{
            Operation = 'Cut'
            Items = $buffer
        }

        Write-Host "✂️ Cut $($buffer.Count) items (Pending Move)"
    }
}

function Paste-Files {
    <#
    .SYNOPSIS
        Pastes the Compass clipboard contents into the current directory.
    .DESCRIPTION
        Computes destination paths, enforces Ouroboros protection, and executes Copy-Item or Move-Item based on the buffered operation.
    .EXAMPLE
        pp -Force
    #>
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    begin {
        $clipboard = $Script:CompassClipboard
        if (-not $clipboard -or -not $clipboard.Items -or $clipboard.Items.Count -eq 0) {
            Write-Warning 'Clipboard is empty. Use Copy-FilesToBuffer or Cut-FilesToBuffer first.'
            $shouldProcess = $false
            return
        }

        $shouldProcess = $true
        $destinationRoot = (Get-Location).ProviderPath
        $successCount = 0
        Write-Verbose "Clipboard operation: $($clipboard.Operation). Destination root is $destinationRoot"
    }

    process {
        if (-not $shouldProcess) {
            return
        }

        foreach ($item in $clipboard.Items) {
            Write-Verbose "Processing clipboard item: $item"

            if (-not (Test-Path -LiteralPath $item)) {
                Write-Warning "Source missing (ghost), skipping: $item"
                continue
            }

            $targetPath = Join-Path -Path $destinationRoot -ChildPath (Split-Path -Path $item -Leaf)
            $sourceFull = [System.IO.Path]::GetFullPath($item)
            $destinationFull = [System.IO.Path]::GetFullPath($destinationRoot)

            $isContainer = Test-Path -LiteralPath $item -PathType Container
            $isDescendant = $destinationFull -eq $sourceFull -or $destinationFull.StartsWith($sourceFull + [IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)

            if ($isContainer -and $isDescendant) {
                Write-Error "Cannot paste directory '$item' into itself or a child (Ouroboros guard)."
                continue
            }

            if ((Test-Path -LiteralPath $targetPath)) {
                if (-not $Force) {
                    Write-Warning "Target exists, skipping to avoid overwrite: $targetPath"
                    continue
                }
            }

            try {
                $operationParams = @{
                    LiteralPath = $item
                    Destination = $targetPath
                }

                if ($Force) {
                    $operationParams.Force = $true
                }

                if ($clipboard.Operation -eq 'Copy') {
                    $operationParams.Recurse = $true
                    Write-Verbose "Copying '$item' to '$targetPath'"
                    Copy-Item @operationParams
                } elseif ($clipboard.Operation -eq 'Cut') {
                    Write-Verbose "Moving '$item' to '$targetPath'"
                    Move-Item @operationParams
                } else {
                    Write-Warning 'Clipboard operation is invalid. Use Copy-FilesToBuffer or Cut-FilesToBuffer to populate the buffer.'
                    break
                }

                $successCount++
            } catch {
                Write-Warning "Failed to $($clipboard.Operation.ToLower()) '$item': $_"
            }
        }
    }

    end {
        if (-not $shouldProcess) {
            return
        }

        $indicator = if ($clipboard.Operation -eq 'Copy') { '📥' } else { '📤' }
        Write-Host "$indicator Pasted $successCount item(s)."

        if ($clipboard.Operation -eq 'Cut') {
            $Script:CompassClipboard = @{
                Operation = $null
                Items = [System.Collections.Generic.List[string]]::new()
            }
        }
    }
}

# Export aliases and functions
New-Alias -Name recent -Value Show-Recent -Description 'Alias for Show-Recent command'
New-Alias -Name ccp -Value Copy-FilesToBuffer -Description 'Copy items to the Compass clipboard'
New-Alias -Name ccut -Value Cut-FilesToBuffer -Description 'Cut items to the Compass clipboard'
New-Alias -Name pp -Value Paste-Files -Description 'Paste items from the Compass clipboard'
Export-ModuleMember -Function Show-Recent, Copy-FilesToBuffer, Cut-FilesToBuffer, Paste-Files -Alias recent, ccp, ccut, pp
