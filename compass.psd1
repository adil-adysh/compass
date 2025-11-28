@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'compass.psm1'

    # Version number of this module.
    ModuleVersion     = '0.1.0'

    # ID used to uniquely identify this module
    GUID              = 'd2d250b3-766e-4c38-9b76-ba8735a26c89'

    # Author of this module
    Author            = 'adil-adysh'

    # Company or vendor of this module
    CompanyName       = 'adil-adysh'

    # Copyright statement for this module
    Copyright         = '(c) 2025 adil-adysh'

    # Description of the functionality provided by this module
    Description       = 'A PowerShell utility that surfaces recently modified files with date, size, and extension filters plus readable output.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Core', 'Desktop')

    # Functions to export from this module
    FunctionsToExport = @(
        'Show-Recent'
        'Copy-FilesToBuffer'
        'Cut-FilesToBuffer'
        'Paste-Files'
        'Find-Item'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport   = @('recent', 'ccp', 'ccut', 'pp', 'search')

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData       = @{
        PSData = @{
            Tags       = @('Files', 'Search', 'Recent', 'Filtering', 'Utility')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/adil-adysh/compass'
            IconUri    = ''
            ReleaseNotes = '0.1.0 initial packaged release: refactor to Public/Private, added clipboard and search features, and CI/release workflows.'
        }
    }
}
