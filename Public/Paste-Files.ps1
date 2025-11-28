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

New-Alias -Name pp -Value Paste-Files -Description 'Paste items from the Compass clipboard'
