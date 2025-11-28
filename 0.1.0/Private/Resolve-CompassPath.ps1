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
