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
        foreach ($item in $InputObject) {
            $resolved = Resolve-CompassPath -InputObject $item
            if ($resolved) {
                Write-Verbose "Buffering for cut: $resolved"
                $buffer.Add($resolved)
            }
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

New-Alias -Name ccut -Value Cut-FilesToBuffer -Description 'Cut items to the Compass clipboard'
