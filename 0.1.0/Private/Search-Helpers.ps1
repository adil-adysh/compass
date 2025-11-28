function Format-NameMatch {
    param(
        [System.IO.FileInfo]$FileInfo,
        [string]$Root
    )
    
    $relPath = $FileInfo.FullName.Substring($Root.Length)
    if ($relPath.StartsWith('\') -or $relPath.StartsWith('/')) { $relPath = $relPath.Substring(1) }
    
    $icon = "📄"
    
    # Simple size formatting
    $size = $FileInfo.Length
    $sizeStr = if ($size -lt 1KB) { "$size B" }
    elseif ($size -lt 1MB) { "{0:N2} KB" -f ($size / 1KB) }
    else { "{0:N2} MB" -f ($size / 1MB) }

    Write-Host "$icon " -NoNewline -ForegroundColor Cyan
    Write-Host $FileInfo.Name -NoNewline -ForegroundColor White
    Write-Host " ($relPath)" -NoNewline -ForegroundColor DarkGray
    Write-Host " [$sizeStr]" -ForegroundColor Gray
}

function Format-ContentMatch {
    param(
        [Microsoft.PowerShell.Commands.MatchInfo[]]$Matches,
        [System.Text.RegularExpressions.Regex]$PatternObj,
        [string]$File
    )
    
    Write-Host "📂 $File" -ForegroundColor Cyan
    Write-Host "------------------------" -ForegroundColor DarkGray
    
    $lastLine = -100
    
    foreach ($m in $Matches) {
        # Separator
        # Calculate if there is a gap between this match and the previous one (considering context)
        $prevEnd = $lastLine
        $currStart = $m.LineNumber - $m.Context.PreContext.Count
        
        if ($prevEnd -ne -100 -and $currStart -gt $prevEnd + 1) {
             Write-Host "..." -ForegroundColor DarkGray
        }

        # PreContext
        if ($m.Context.PreContext) {
            $startLine = $m.LineNumber - $m.Context.PreContext.Count
            for ($i = 0; $i -lt $m.Context.PreContext.Count; $i++) {
                $ln = $startLine + $i
                Write-Host ("{0,5}: " -f $ln) -NoNewline -ForegroundColor DarkGray
                Write-Host $m.Context.PreContext[$i] -ForegroundColor DarkGray
            }
        }

        # Match Line
        Write-Host ("{0,5}: " -f $m.LineNumber) -NoNewline -ForegroundColor White
        
        # Highlight logic
        $line = $m.Line
        $matchesInLine = $PatternObj.Matches($line)
        $currentIndex = 0
        
        if ($matchesInLine.Count -gt 0) {
            foreach ($match in $matchesInLine) {
                # Before match
                if ($match.Index -gt $currentIndex) {
                    Write-Host $line.Substring($currentIndex, $match.Index - $currentIndex) -NoNewline -ForegroundColor White
                }
                
                # Match
                Write-Host $match.Value -NoNewline -ForegroundColor Black -BackgroundColor DarkYellow
                
                $currentIndex = $match.Index + $match.Length
            }
            
            # Remainder
            if ($currentIndex -lt $line.Length) {
                Write-Host $line.Substring($currentIndex) -NoNewline -ForegroundColor White
            }
        } else {
            # Fallback if regex doesn't match (shouldn't happen if Select-String found it, unless regex logic differs)
            Write-Host $line -NoNewline -ForegroundColor White
        }
        Write-Host "" # Newline

        # PostContext
        if ($m.Context.PostContext) {
            for ($i = 0; $i -lt $m.Context.PostContext.Count; $i++) {
                $ln = $m.LineNumber + 1 + $i
                Write-Host ("{0,5}: " -f $ln) -NoNewline -ForegroundColor DarkGray
                Write-Host $m.Context.PostContext[$i] -ForegroundColor DarkGray
            }
        }
        
        $lastLine = $m.LineNumber + ($m.Context.PostContext.Count)
    }
    Write-Host ""
}
