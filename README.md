# Compass PowerShell Module

Maintained by `adil-adysh`.

A modern PowerShell module for finding recently modified files with advanced filtering capabilities.

## Features

- 🔍 **Flexible Date Filtering**: Search files modified today, yesterday, or within a custom number of days
- 📝 **Extension Filtering**: Filter by single or multiple file extensions
- 📏 **Size Filtering**: Filter files by minimum and maximum size
- 🎨 **Formatted Output**: Human-readable file sizes and timestamps
- ⚡ **Fast Alias**: Use the `recent` alias for quick searches
- ✅ **Robust Error Handling**: Comprehensive validation and helpful error messages

## Installation

1. Clone or download this repository
2. Import the module:

```powershell
Import-Module .\compass.psd1
```

To install permanently, copy the module folder to your PowerShell modules directory:

```powershell
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\compass"
Copy-Item -Path .\compass -Destination $modulePath -Recurse
```

## Usage

### Basic Examples

```powershell
# Find all files modified in the last 3 days (default)
Show-Recent

# Find files modified today
Show-Recent -Today

# Find files modified yesterday
Show-Recent -Yesterday

# Find files modified in the last 7 days
Show-Recent -Days 7
```

### Extension Filtering

```powershell
# Find PowerShell files modified in the last 5 days
Show-Recent -Days 5 -Extension '*.ps1'

# Find log and text files modified today
Show-Recent -Today -Extension '*.log', '*.txt'
```

### Size Filtering

```powershell
# Find files larger than 10MB modified in the last week
Show-Recent -Days 7 -MinSize 10MB

# Find small files (less than 1MB) modified today
Show-Recent -Today -MaxSize 1MB

# Find files between 5MB and 50MB
Show-Recent -Days 30 -MinSize 5MB -MaxSize 50MB
```

### Combining Filters

```powershell
# Find large log files modified yesterday
Show-Recent -Yesterday -Extension '*.log' -MinSize 10MB

# Find recent PowerShell scripts in a specific directory
Show-Recent -Path C:\Projects -Days 7 -Extension '*.ps1', '*.psm1'
```

### Using the Alias

```powershell
# Quick search using the 'recent' alias
recent
recent -Today
recent -Days 7 -Extension '*.txt'
```

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-Today` | Switch | Find files modified today | - |
| `-Yesterday` | Switch | Find files modified yesterday | - |
| `-Days` | Int | Find files modified in the last N days (1-365) | 3 |
| `-Extension` | String[] | Filter by file extension(s) (e.g., '*.txt', '*.log') | All files |
| `-MinSize` | Int64 | Filter files larger than specified size in bytes | - |
| `-MaxSize` | Int64 | Filter files smaller than specified size in bytes | - |
| `-Path` | String | Root path to search | Current directory |

## Output

The command returns custom objects with the following properties:

- **Name**: File name
- **Type**: File extension
- **Size**: Human-readable file size (B, KB, MB, GB, TB)
- **Modified**: Last modification timestamp (yyyy-MM-dd HH:mm)
- **Path**: Directory path

## Requirements

- PowerShell 7.0 or higher
- Compatible with PowerShell Core and Desktop editions

## Testing

Run the test suite using Pester:

```powershell
Invoke-Pester -Path .\tests\compass.Tests.ps1
```

## Best Practices Applied

This module follows modern PowerShell best practices:

- ✅ **Comprehensive comment-based help** with examples
- ✅ **Parameter validation** with appropriate ranges and types
- ✅ **Proper error handling** with terminating and non-terminating errors
- ✅ **OutputType attribute** for better pipeline behavior
- ✅ **Consistent naming** following PowerShell conventions
- ✅ **Module manifest** with proper metadata
- ✅ **Pester tests** with comprehensive coverage
- ✅ **Helper functions** for code reusability
- ✅ **Proper module member export**
- ✅ **PSCustomObject output** with custom type name

## Contributing

Contributions are welcome! Please ensure:

1. All tests pass: `Invoke-Pester`
2. Code follows PowerShell best practices
3. Add tests for new features

## License

This project is licensed under the Apache License, Version 2.0 - see the [LICENSE](LICENSE) file for details.

## Version History

### 1.0.0 (2025-11-28)

- Initial release
- Show-Recent command with date, extension, and size filtering
- Comprehensive test suite
- Full documentation
