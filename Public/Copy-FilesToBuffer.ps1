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
        foreach ($item in $InputObject) {
            $resolved = Resolve-CompassPath -InputObject $item
            if ($resolved) {
                Write-Verbose "Buffering for copy: $resolved"
                $buffer.Add($resolved)
            }
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

New-Alias -Name ccp -Value Copy-FilesToBuffer -Description 'Copy items to the Compass clipboard'
