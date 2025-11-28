function Select-Copy {
    [CmdletBinding(DefaultParameterSetName='Slice')]
    [Alias('scopy')]
    param(
        [Parameter(ParameterSetName='Slice')]
        [int]$First,

        [Parameter(ParameterSetName='Slice')]
        [int]$Last,

        [Parameter(ParameterSetName='Slice')]
        [int[]]$Range,

        [Parameter(ParameterSetName='Search', Mandatory=$true)]
        [string]$Pattern,

        [Parameter(ParameterSetName='Search')]
        [int]$Context = 0,

        [Parameter(ParameterSetName='Search')]
        [switch]$Merge = $true,

        [Parameter(ValueFromPipeline=$true)]
        [psobject]$InputObject,

        [switch]$PassThru
    )

    Begin {
        $lines = [System.Collections.Generic.List[string]]::new()
    }

    Process {
        if ($null -ne $InputObject) {
            # Normalize input: handle strings, arrays, and split by newlines
            # If InputObject is not a string, try to convert it, but usually it's string from logs
            $content = if ($InputObject -is [string]) { $InputObject } else { $InputObject.ToString() }
            
            # Split by regex to handle mixed line endings
            $split = $content -split '\r?\n'
            foreach ($line in $split) {
                $lines.Add($line)
            }
        }
    }

    End {
        $allLines = $lines.ToArray()
        $count = $allLines.Count
        $selectedIndices = [System.Collections.Generic.HashSet[int]]::new()

        if ($PSCmdlet.ParameterSetName -eq 'Slice') {
            $hasSliceParam = $PSBoundParameters.ContainsKey('First') -or 
                             $PSBoundParameters.ContainsKey('Last') -or 
                             $PSBoundParameters.ContainsKey('Range')

            if (-not $hasSliceParam) {
                # If no slice parameters, select all
                for ($i = 0; $i -lt $count; $i++) { [void]$selectedIndices.Add($i) }
            }
            else {
                # First N
                if ($PSBoundParameters.ContainsKey('First')) {
                    $limit = [Math]::Min($First, $count)
                    for ($i = 0; $i -lt $limit; $i++) { [void]$selectedIndices.Add($i) }
                }

                # Last N
                if ($PSBoundParameters.ContainsKey('Last')) {
                    $start = [Math]::Max(0, $count - $Last)
                    for ($i = $start; $i -lt $count; $i++) { [void]$selectedIndices.Add($i) }
                }

                # Range (Indices)
                if ($PSBoundParameters.ContainsKey('Range')) {
                    foreach ($r in $Range) {
                        if ($r -ge 0 -and $r -lt $count) {
                            [void]$selectedIndices.Add($r)
                        }
                    }
                }
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Search') {
            # Find matches
            $matchIndices = [System.Collections.Generic.List[int]]::new()
            for ($i = 0; $i -lt $count; $i++) {
                if ($allLines[$i] -match $Pattern) {
                    $matchIndices.Add($i)
                }
            }

            # Apply Context
            foreach ($idx in $matchIndices) {
                $start = [Math]::Max(0, $idx - $Context)
                $end = [Math]::Min($count - 1, $idx + $Context)
                for ($k = $start; $k -le $end; $k++) {
                    [void]$selectedIndices.Add($k)
                }
            }
        }

        # Sort indices to reconstruct order
        $sortedIndices = $selectedIndices | Sort-Object

        # Build Output
        $outputLines = [System.Collections.Generic.List[string]]::new()

        if ($PSCmdlet.ParameterSetName -eq 'Search' -and -not $Merge) {
            # Insert separators between non-contiguous blocks
            for ($i = 0; $i -lt $sortedIndices.Count; $i++) {
                $currentIndex = $sortedIndices[$i]
                
                if ($i -gt 0) {
                    $prevIndex = $sortedIndices[$i-1]
                    # If there is a gap > 1, insert separator
                    # Gap of 1 means they are adjacent (e.g. 10, 11), so no separator.
                    if ($currentIndex -gt $prevIndex + 1) {
                        $outputLines.Add("---")
                    }
                }
                
                $outputLines.Add($allLines[$currentIndex])
            }
        }
        else {
            # Just add lines
            foreach ($idx in $sortedIndices) {
                $outputLines.Add($allLines[$idx])
            }
        }

        $resultText = $outputLines -join [Environment]::NewLine

        # Send to Clipboard
        if ($resultText) {
            Set-Clipboard -Value $resultText
        }

        # PassThru
        if ($PassThru) {
            Write-Output $resultText
        }
    }
}
