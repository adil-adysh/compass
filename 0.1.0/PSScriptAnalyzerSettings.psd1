# PSScriptAnalyzer settings for Compass module

@{
    # Use the PowerShell Core and PowerShell 7+ rules
    Severity = @('Error', 'Warning', 'Information')
    
    # Include default rules
    IncludeDefaultRules = $true
    
    # Exclude specific rules that conflict with module conventions
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
        'PSUseApprovedVerbs'
        'PSUseSingularNouns'
        'PSUseBOMForUnicodeEncodedFile'
    )
    
    # Additional rules configuration
    Rules = @{
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            BlockComment = $true
            VSCodeSnippetCorrection = $false
            Placement = 'before'
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
        }
        
        PSAlignAssignmentStatement = @{
            Enable = $false
            CheckHashtable = $false
        }
        
        PSUseCorrectCasing = @{
            Enable = $true
        }
        
        PSPlaceOpenBrace = @{
            Enable = $true
            OnSameLine = $true
            NewLineAfter = $true
            IgnoreOneLineBlock = $true
        }
        
        PSPlaceCloseBrace = @{
            Enable = $true
            NewLineAfter = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore = $false
        }
    }
}
