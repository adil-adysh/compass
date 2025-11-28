# PowerShell module compass

# Initialize Clipboard State
if (-not $Script:CompassClipboard) {
    $Script:CompassClipboard = @{
        Operation = $null
        Items = [System.Collections.Generic.List[string]]::new()
    }
}

# Load Private Functions
$privateFunctions = Join-Path $PSScriptRoot 'Private'
if (Test-Path $privateFunctions) {
    Get-ChildItem -Path $privateFunctions -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Load Public Functions
$publicFunctions = Join-Path $PSScriptRoot 'Public'
if (Test-Path $publicFunctions) {
    Get-ChildItem -Path $publicFunctions -Filter '*.ps1' -Recurse | ForEach-Object {
        . $_.FullName
    }
}

# Export Functions and Aliases
Export-ModuleMember -Function Show-Recent, Copy-FilesToBuffer, Cut-FilesToBuffer, Paste-Files -Alias recent, ccp, ccut, pp
