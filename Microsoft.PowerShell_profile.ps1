# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        🎨 POWERSHELL PROFILE PRO                              ║
# ║                           Path: $PROFILE                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

#region ═══════════════════════════════════════════════════════════════════════════
#        🎨 THEME & COLORS
#endregion ════════════════════════════════════════════════════════════════════════

$Script:Theme = @{
    Primary    = 'Cyan'
    Secondary  = 'Magenta'
    Success    = 'Green'
    Warning    = 'Yellow'
    Error      = 'Red'
    Muted      = 'DarkGray'
    Accent     = 'Blue'
    Info       = 'White'
}

#region ═══════════════════════════════════════════════════════════════════════════
#        🖥️ TUI FRAMEWORK (Interactive Menu System with Mouse Support)
#endregion ════════════════════════════════════════════════════════════════════════

$Script:TUI = @{
    BoxChars = @{
        TL = "╭"; TR = "╮"; BL = "╰"; BR = "╯"
        H = "─"; V = "│"; LT = "├"; RT = "┤"
        Cross = "┼"; TT = "┬"; BT = "┴"
    }
    Icons = @{
        Arrow = "❯"; Check = "✓"; Cross = "✗"; Dot = "●"
        Up = "▲"; Down = "▼"; Left = "◀"; Right = "▶"
        Edit = "✏️"; Delete = "🗑️"; Add = "➕"; Search = "🔍"
    }
    Mouse = @{
        Enabled = $false
        LastX = -1
        LastY = -1
        LastClickTime = [DateTime]::MinValue
        DoubleClickThresholdMs = 300
    }
}

# 🖱️ Mouse Helper Functions
function global:Enable-MouseTracking {
    if (-not $Script:TUI.Mouse.Enabled) {
        # Enable VT Mouse Tracking (Legacy Mode - Most Compatible)
        Write-Host "$([char]27)[?1000h" -NoNewline
        # Also enable SGR mode for better coordinate support (optional)
        Write-Host "$([char]27)[?1006h" -NoNewline
        $Script:TUI.Mouse.Enabled = $true
    }
}

function global:Disable-MouseTracking {
    if ($Script:TUI.Mouse.Enabled) {
        Write-Host "$([char]27)[?1006l" -NoNewline
        Write-Host "$([char]27)[?1000l" -NoNewline
        $Script:TUI.Mouse.Enabled = $false
    }
}

function global:Parse-MouseEvent {
    param([ref]$X, [ref]$Y, [ref]$IsDoubleClick, [ref]$Button)
    
    # Check if there's pending input (mouse event)
    if (-not $Host.UI.RawUI.KeyAvailable) { return $false }
    
    try {
        $seq = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($seq.Character -ne '[') { return $false }
        
        $buf = ""
        $timeout = 50
        $start = Get-Date
        
        while ($Host.UI.RawUI.KeyAvailable -or ((Get-Date) - $start).TotalMilliseconds -lt $timeout) {
            if ($Host.UI.RawUI.KeyAvailable) {
                $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                $buf += $k.Character
                
                # Check for terminator
                if ($k.Character -match '[M~mM]') { break }
            } else {
                Start-Sleep -Milliseconds 1
            }
        }
        
        # Parse SGR Mode: <btn;x;yM or Legacy Mode: M<btn><x><y>
        if ($buf -match '^(\d+);(\d+);(\d+)M') {
            # SGR Extended Mode
            $Button.Value = [int]$Matches[1]
            $X.Value = [int]$Matches[2] - 1
            $Y.Value = [int]$Matches[3] - 1
        }
        elseif ($buf.StartsWith("M") -and $buf.Length -ge 4) {
            # Legacy Mode (X10)
            $Button.Value = [int][char]$buf[1] - 32
            $X.Value = [int][char]$buf[2] - 32 - 1
            $Y.Value = [int][char]$buf[3] - 32 - 1
        }
        elseif ($buf -match '^<(\d+);(\d+);(\d+)M') {
            # Alternative SGR
            $Button.Value = [int]$Matches[1]
            $X.Value = [int]$Matches[2] - 1
            $Y.Value = [int]$Matches[3] - 1
        }
        else {
            return $false
        }
        
        # Detect double-click
        $now = Get-Date
        $IsDoubleClick.Value = $false
        
        if ($X.Value -eq $Script:TUI.Mouse.LastX -and 
            $Y.Value -eq $Script:TUI.Mouse.LastY -and
            ($now - $Script:TUI.Mouse.LastClickTime).TotalMilliseconds -lt $Script:TUI.Mouse.DoubleClickThresholdMs) {
            $IsDoubleClick.Value = $true
        }
        
        $Script:TUI.Mouse.LastX = $X.Value
        $Script:TUI.Mouse.LastY = $Y.Value
        $Script:TUI.Mouse.LastClickTime = $now
        
        return $true
        
    } catch {
        return $false
    }
}

# 🎯 Interactive Menu với phím mũi tên và chuột
function global:Show-InteractiveMenu {
    param(
        [string]$Title,
        [array]$Options,
        [string]$Color = "Cyan",
        [switch]$Multi
    )
    
    $selected = 0
    $checked = @()
    $maxWidth = ($Options | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum + 10
    if ($maxWidth -lt $Title.Length + 6) { $maxWidth = $Title.Length + 6 }
    
    $startY = [Console]::CursorTop
    $lastDrawTime = Get-Date
    
    function Draw-Menu {
        param([bool]$Force = $false)
        
        # Throttle redraw to prevent flickering (max 30 FPS)
        $now = Get-Date
        if (-not $Force -and ($now - $script:lastDrawTime).TotalMilliseconds -lt 33) {
            return
        }
        $script:lastDrawTime = $now
        
        [Console]::SetCursorPosition(0, $startY)
        
        # Header
        Write-Host "  $($Script:TUI.BoxChars.TL)$("─" * $maxWidth)$($Script:TUI.BoxChars.TR)" -ForegroundColor $Color
        $pad = [math]::Floor(($maxWidth - $Title.Length) / 2)
        Write-Host "  $($Script:TUI.BoxChars.V)" -NoNewline -ForegroundColor $Color
        Write-Host (" " * $pad) -NoNewline
        Write-Host $Title -NoNewline -ForegroundColor White
        Write-Host (" " * ($maxWidth - $pad - $Title.Length)) -NoNewline
        Write-Host $($Script:TUI.BoxChars.V) -ForegroundColor $Color
        Write-Host "  $($Script:TUI.BoxChars.LT)$("─" * $maxWidth)$($Script:TUI.BoxChars.RT)" -ForegroundColor $Color
        
        # Options
        for ($i = 0; $i -lt $Options.Count; $i++) {
            $prefix = if ($i -eq $selected) { " $($Script:TUI.Icons.Arrow) " } else { "   " }
            $checkMark = if ($Multi -and $checked -contains $i) { "[$($Script:TUI.Icons.Check)]" } else { if ($Multi) { "[ ]" } else { "" } }
            
            $fg = if ($i -eq $selected) { "Black" } else { "White" }
            $bg = if ($i -eq $selected) { $Color } else { $Host.UI.RawUI.BackgroundColor }
            
            Write-Host "  $($Script:TUI.BoxChars.V)" -NoNewline -ForegroundColor $Color
            Write-Host "$prefix$checkMark $($Options[$i])".PadRight($maxWidth) -NoNewline -ForegroundColor $fg -BackgroundColor $bg
            Write-Host $($Script:TUI.BoxChars.V) -ForegroundColor $Color
        }
        
        # Footer
        Write-Host "  $($Script:TUI.BoxChars.BL)$("─" * $maxWidth)$($Script:TUI.BoxChars.BR)" -ForegroundColor $Color
        $hint = if ($Multi) { "🖱️ Click/↑↓:Move  Space:Select  Enter:Confirm  Esc:Cancel" } else { "🖱️ Click/↑↓:Select  Enter/DoubleClick:Confirm  Esc:Cancel" }
        Write-Host "  $hint" -ForegroundColor DarkGray
    }
    
    [Console]::CursorVisible = $false
    Enable-MouseTracking
    
    try {
        Draw-Menu -Force $true
        
        while ($true) {
            if (-not $Host.UI.RawUI.KeyAvailable) {
                Start-Sleep -Milliseconds 10
                continue
            }
            
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            # Handle Mouse Events
            if ($key.VirtualKeyCode -eq 27) {
                $mouseX = 0
                $mouseY = 0
                $isDoubleClick = $false
                $mouseButton = 0
                
                if (Parse-MouseEvent ([ref]$mouseX) ([ref]$mouseY) ([ref]$isDoubleClick) ([ref]$mouseButton)) {
                    # Calculate which option was clicked
                    $firstOptY = $startY + 3 # Header is 3 lines
                    $clickedIndex = $mouseY - $firstOptY
                    
                    if ($clickedIndex -ge 0 -and $clickedIndex -lt $Options.Count) {
                        $oldSelected = $selected
                        $selected = $clickedIndex
                        
                        # Double-click confirms (single-select mode)
                        if ($isDoubleClick -and -not $Multi) {
                            return $Options[$selected]
                        }
                        
                        # Single click toggles in multi-select mode
                        if ($Multi) {
                            if ($checked -contains $selected) { 
                                $checked = $checked | Where-Object { $_ -ne $selected }
                            } else { 
                                $checked += $selected
                            }
                        }
                        
                        Draw-Menu
                    }
                    continue
                }
                
                # Not a mouse event, might be Esc key
                if (-not $Host.UI.RawUI.KeyAvailable) {
                    return $null
                }
            }
            
            switch ($key.VirtualKeyCode) {
                38 { # Up
                    $selected = if ($selected -gt 0) { $selected - 1 } else { $Options.Count - 1 }
                    Draw-Menu
                }
                40 { # Down
                    $selected = if ($selected -lt $Options.Count - 1) { $selected + 1 } else { 0 }
                    Draw-Menu
                }
                32 { # Space
                    if ($Multi) {
                        if ($checked -contains $selected) {
                            $checked = $checked | Where-Object { $_ -ne $selected }
                        } else {
                            $checked += $selected
                        }
                        Draw-Menu
                    }
                }
                13 { # Enter
                    if ($Multi) { return $checked | ForEach-Object { $Options[$_] } }
                    return $Options[$selected]
                }
                27 { # Esc
                    return $null
                }
            }
        }
    } finally {
        Disable-MouseTracking
        [Console]::CursorVisible = $true
    }
}

# 📊 Progress Bar đẹp
function global:Show-ProgressBar {
    param(
        [int]$Percent,
        [int]$Width = 30,
        [string]$Label = "",
        [switch]$NoNewLine
    )
    
    $filled = [math]::Floor($Percent * $Width / 100)
    $empty = $Width - $filled
    
    # Gradient colors
    $colors = @("Red", "DarkYellow", "Yellow", "Green", "Cyan")
    $colorIndex = [math]::Floor($Percent / 25)
    if ($colorIndex -gt 4) { $colorIndex = 4 }
    $barColor = $colors[$colorIndex]
    
    $bar = "█" * $filled + "▒" * $empty
    
    Write-Host "`r  $Label [" -NoNewline -ForegroundColor DarkGray
    Write-Host $bar -NoNewline -ForegroundColor $barColor
    Write-Host "] $Percent%" -NoNewline -ForegroundColor White
    
    if (-not $NoNewLine) { Write-Host "" }
}

# 🎨 Animated Spinner
function global:Show-Spinner {
    param(
        [scriptblock]$Task,
        [string]$Message = "Loading..."
    )
    
    $frames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    $job = Start-Job -ScriptBlock $Task
    $i = 0
    
    while ($job.State -eq "Running") {
        Write-Host "`r  $($frames[$i % $frames.Count]) $Message" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 80
        $i++
    }
    
    $result = Receive-Job $job
    Remove-Job $job
    Write-Host "`r  ✓ $Message" -ForegroundColor Green
    return $result
}

# 📋 Table Display
function global:Show-Table {
    param(
        [array]$Data,
        [array]$Columns,
        [string]$Title = ""
    )
    
    if (-not $Data) { return }
    
    # Calculate column widths
    $widths = @{}
    foreach ($col in $Columns) {
        $maxLen = $col.Length
        foreach ($row in $Data) {
            $val = "$($row.$col)"
            if ($val.Length -gt $maxLen) { $maxLen = $val.Length }
        }
        $widths[$col] = [math]::Min($maxLen + 2, 40)
    }
    
    $totalWidth = ($widths.Values | Measure-Object -Sum).Sum + $Columns.Count + 1
    
    Write-Host ""
    if ($Title) {
        Write-Host "  $($Script:TUI.BoxChars.TL)$("─" * ($totalWidth - 2))$($Script:TUI.BoxChars.TR)" -ForegroundColor Cyan
        $pad = [math]::Floor(($totalWidth - $Title.Length - 2) / 2)
        Write-Host "  │$(" " * $pad)$Title$(" " * ($totalWidth - $pad - $Title.Length - 2))│" -ForegroundColor Yellow
    }
    
    # Header
    Write-Host "  $($Script:TUI.BoxChars.TL)$("─" * ($totalWidth - 2))$($Script:TUI.BoxChars.TR)" -ForegroundColor Cyan
    Write-Host "  │" -NoNewline -ForegroundColor Cyan
    foreach ($col in $Columns) {
        Write-Host ("{0,-$($widths[$col])}" -f " $col") -NoNewline -ForegroundColor Yellow
        Write-Host "│" -NoNewline -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "  $($Script:TUI.BoxChars.LT)$("─" * ($totalWidth - 2))$($Script:TUI.BoxChars.RT)" -ForegroundColor Cyan
    
    # Rows
    foreach ($row in $Data) {
        Write-Host "  │" -NoNewline -ForegroundColor Cyan
        foreach ($col in $Columns) {
            $val = "$($row.$col)"
            if ($val.Length -gt ($widths[$col] - 2)) {
                $val = $val.Substring(0, $widths[$col] - 5) + "..."
            }
            Write-Host ("{0,-$($widths[$col])}" -f " $val") -NoNewline -ForegroundColor White
            Write-Host "│" -NoNewline -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    Write-Host "  $($Script:TUI.BoxChars.BL)$("─" * ($totalWidth - 2))$($Script:TUI.BoxChars.BR)" -ForegroundColor Cyan
    Write-Host ""
}

#region ═══════════════════════════════════════════════════════════════════════════
#        🎮 INPUT HANDLER & KEYS (SMART EXECUTION)
#endregion ════════════════════════════════════════════════════════════════════════

if (Get-Module PSReadLine) {
    
    # 1. Hàm tính khoảng cách chuỗi (Levenshtein) để gợi ý lệnh
    $levenshtein = @"
    using System;
    public class StringDistance {
        public static int Levenshtein(string s, string t) {
            if (string.IsNullOrEmpty(s)) return string.IsNullOrEmpty(t) ? 0 : t.Length;
            if (string.IsNullOrEmpty(t)) return s.Length;
            int n = s.Length; int m = t.Length;
            int[,] d = new int[n + 1, m + 1];
            for (int i = 0; i <= n; d[i, 0] = i++) ;
            for (int j = 0; j <= m; d[0, j] = j++) ;
            for (int i = 1; i <= n; i++) {
                for (int j = 1; j <= m; j++) {
                    int cost = (t[j - 1] == s[i - 1]) ? 0 : 1;
                    d[i, j] = Math.Min(Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1), d[i - 1, j - 1] + cost);
                }
            }
            return d[n, m];
        }
    }
"@
    try { Add-Type -TypeDefinition $levenshtein -ErrorAction SilentlyContinue } catch {}

    # 2. Xử lý phím ENTER (Smart Error Handling + Correction Prep)
    Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # Basic Checks
        if ([string]::IsNullOrWhiteSpace($line)) {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
            return
        }

        # Clear correction state
        $global:LastCommandCorrection = $null

        # Add to history and clear buffer (Mimic standard behavior)
        [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
        [Microsoft.PowerShell.PSConsoleReadLine]::Clear()

        # Execute
        try {
            # === 🧠 INTELLIGENT PATH RESOLVER (REVERSE SCAN) ===
            # Calculates the longest valid path prefix to handle spaces correctly.
            # Example: "My Script Name.ps1 -Verbose" -> Detects "My Script Name.ps1"
            # Example: "Folder A B" -> Detects "Folder A B" (not just "Folder A")

            $cleanLine = $line.Trim()
            $tokens = $cleanLine -split ' '
            
            # 1. PRE-CHECK: COMMAND VS PATH
            # If the first word is a known command AND it doesn't look like an explicit path (./, \, /),
            # assume it's a command and let PowerShell handle it to avoid shadowing.
            $firstWord = $tokens[0]
            $looksLikePath = $firstWord -match '^(\.|\\|/|[a-zA-Z]:)'
            $isCommand = Get-Command $firstWord -ErrorAction SilentlyContinue

            if ($isCommand -and -not $looksLikePath) {
                # Standard execution for commands like 'git', 'npm', 'dir'
                Invoke-Expression $line
                return
            }

            # 2. DEEP SCAN: LONGEST MATCH FIRST
            # Scan backwards from the full string down to the first token
            for ($i = $tokens.Count; $i -ge 1; $i--) {
                # Reconstruct the potential path from tokens 0 to i-1
                $potentialPath = $tokens[0..($i-1)] -join ' '
                
                # Normalize: Remove wrapping quotes for the check
                $testPath = $potentialPath -replace '^"|"$', '' -replace "^'|'$", ''
                
                # Skip checking if empty or just whitespace
                if ([string]::IsNullOrWhiteSpace($testPath)) { continue }

                # Use LiteralPath to handle special chars like [] () '
                if (Test-Path -LiteralPath $testPath) {
                    $item = Get-Item -LiteralPath $testPath -Force
                    
                    # 📂 DIRECTORY DETECTION
                    if ($item.PSIsContainer) {
                        # Only Auto-CD if the path matches the ENTIRE input
                        # (Prevents "MyFolder SomeArg" from cd-ing, which might be confusing)
                        if ($i -eq $tokens.Count) {
                            Write-Host ""
                            Write-Host "  📂 Auto-CD: " -NoNewline -ForegroundColor Cyan
                            Write-Host $item.FullName -ForegroundColor Yellow
                            Write-Host ""
                            
                            if ($Script:DirHistory) { $Script:DirHistory.Add((Get-Location).Path) }
                            Set-Location -LiteralPath $item.FullName
                            
                            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
                            return
                        }
                    }
                    # 🚀 FILE DETECTION
                    else {
                        Write-Host ""
                        Write-Host "  🚀 Auto-Run: " -NoNewline -ForegroundColor Cyan
                        Write-Host $item.Name -ForegroundColor Yellow
                        Write-Host ""

                        # Arguments are the rest of the line
                        $remainingArgs = ""
                        if ($i -lt $tokens.Count) {
                            $remainingArgs = $tokens[$i..($tokens.Count-1)] -join ' '
                        }

                        # Construct Safe Command: & "Path" Args
                        # We use Invoke-Expression to handle the arguments parsing correctly
                        $cmdToRun = "& '$testPath' $remainingArgs"
                        Invoke-Expression $cmdToRun
                        
                        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
                        return
                    }
                }
            }

            # 3. FALLBACK
            # If no path matched, run normally and let PowerShell error handler catch it
            Invoke-Expression $line

        } catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ItemNotFoundException] {
            # === FALLBACK SMART EXECUTE (Retry if missed above) ===
            $cleanLine = $line.Trim()
            $cleanLineUnquoted = $cleanLine -replace '^"|"$', '' -replace "^'|'$", ''
            
            if ($cleanLine -match '^\.?[\/\\]' -and (Test-Path -LiteralPath $cleanLineUnquoted -PathType Leaf)) {
                Write-Host ""
                Write-Host "  🚀 Smart Execute: " -NoNewline -ForegroundColor Cyan
                Write-Host $cleanLineUnquoted -ForegroundColor Yellow
                Write-Host ""
                try { & "$cleanLineUnquoted" } catch { Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red }
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
                return
            }
            # ================================================

            # Capture the bad command
            $failedCmd = $_.TargetObject
            if (-not $failedCmd) { $failedCmd = $line.Split(' ')[0] }

            # UI Error
            Write-Host ""
            Write-Host "  ╭──────────────────────────────────────────────╮" -ForegroundColor Red
            Write-Host "  │ 🚫 LỖI: Lệnh không tồn tại                   │" -ForegroundColor Red
            Write-Host "  │ " -NoNewline -ForegroundColor Red
            Write-Host " '$failedCmd'" -NoNewline -ForegroundColor Yellow
            Write-Host " không được tìm thấy.              │" -ForegroundColor Red
            Write-Host "  ╰──────────────────────────────────────────────╯" -ForegroundColor Red
            
            # Fuzzy Search Logic
            $suggestions = Get-Command | Select-Object -ExpandProperty Name | Where-Object { 
                [Math]::Abs($_.Length - $failedCmd.Length) -le 3 
            }
            
            $bestMatch = $null
            $bestDist = 100
            
            foreach ($s in $suggestions) {
                try {
                    $dist = [StringDistance]::Levenshtein($failedCmd, $s)
                    if ($dist -lt $bestDist) {
                        $bestDist = $dist
                        $bestMatch = $s
                    }
                } catch {}
            }

            if ($bestMatch -and $bestDist -le 3) {
                $global:LastCommandCorrection = $line -replace "^$failedCmd", $bestMatch
                Write-Host ""
                Write-Host "  💡 Có phải ý bạn là: " -NoNewline -ForegroundColor Cyan
                Write-Host "$bestMatch" -ForegroundColor Green
                Write-Host ""
                Write-Host "  (Nhấn TAB để tự động sửa)" -ForegroundColor DarkGray
            }
            Write-Host ""
            
        } catch {
            # General Error
            Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
    }

    # 3. Xử lý phím TAB (Auto Correction)
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        # If line is empty AND we have a pending correction from the last error
        if ([string]::IsNullOrEmpty($line) -and $global:LastCommandCorrection) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($global:LastCommandCorrection)
            $global:LastCommandCorrection = $null # Reset
        } else {
            # Normal Tab behavior
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
        }
    }

    # 3. Giữ lại Ctrl+C custom cũ
    Set-PSReadLineKeyHandler -Key 'Ctrl+c' -ScriptBlock {
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            [Microsoft.PowerShell.PSConsoleReadLine]::CancelLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            return
        }
        
        Write-Host ""
        Write-Host ""
        Write-Host "  ╭──────────────────────────────────╮" -ForegroundColor $Script:Theme.Warning
        Write-Host "  │  ⚠️  Bạn muốn thoát PowerShell?  │" -ForegroundColor $Script:Theme.Warning
        Write-Host "  ╰──────────────────────────────────╯" -ForegroundColor $Script:Theme.Warning
        Write-Host ""
        Write-Host "  [Y] Thoát  [N] Ở lại  [R] Restart" -ForegroundColor $Script:Theme.Muted
        Write-Host ""
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.Character.ToString().ToLower()) {
            'y' { 
                Write-Host "  👋 Tạm biệt!" -ForegroundColor $Script:Theme.Success
                Start-Sleep -Milliseconds 500
                [Environment]::Exit(0)
            }
            'r' {
                Write-Host "  🔄 Đang khởi động lại..." -ForegroundColor $Script:Theme.Primary
                Start-Sleep -Milliseconds 500
                Start-Process pwsh -ArgumentList "-NoExit"
                [Environment]::Exit(0)
            }
            default {
                Write-Host "  ✅ Đã hủy" -ForegroundColor $Script:Theme.Success
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            }
        }
    }
    
    # Các phím tắt hữu ích khác
    Set-PSReadLineKeyHandler -Key 'Ctrl+l' -Function ClearScreen
    Set-PSReadLineKeyHandler -Key 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Key 'Ctrl+Backspace' -Function BackwardKillWord
    Set-PSReadLineKeyHandler -Key 'Alt+.' -Function YankLastArg
    
    # Cấu hình PSReadLine
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    
    # Màu sắc cho syntax highlighting
    Set-PSReadLineOption -Colors @{
        Command            = 'Cyan'
        Parameter          = 'DarkCyan'
        Operator           = 'DarkGray'
        Variable           = 'Green'
        String             = 'Yellow'
        Number             = 'Magenta'
        Type               = 'Gray'
        Comment            = 'DarkGreen'
        Keyword            = 'Blue'
        Error              = 'Red'
        InlinePrediction   = 'DarkGray'
        ListPrediction     = 'DarkYellow'
    }
}


#region ═══════════════════════════════════════════════════════════════════════════
#        💎 ULTIMATE PROMPT V5 (HYBRID LUXURY STYLE)
#endregion ════════════════════════════════════════════════════════════════════════

function global:prompt {
    $lastSuccess = $?
    $lastExitCode = $LASTEXITCODE
    
    # --- 1. CONFIG & ICONS ---
    $user = $env:USERNAME
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    # Nerd Fonts "Pill" Style & Icons
    $i = @{
        # Separators
        Left   = [char]0xe0b6  # 
        Right  = [char]0xe0b4  # 
        Sep    = "│"           # │
        
        # Icons
        Admin  = "⚡"
        User   = "👤"
        Folder = "📂"
        Home   = "🏠"
        Git    = ""
        Mem    = "🧠"
        Time   = "🕒"
        
        # Input Arrows
        Rocket = "🚀"
        Boom   = "💥"
        Arrow  = "❯"
    }

    # --- 2. GATHER INFO ---
    
    # [Path]
    $path = Get-Location
    $displayPath = $path.Path.Replace($HOME, "~")
    # Smart shorten logic
    if ($displayPath.Length -gt 35) {
        $parts = $displayPath -split '\\'
        if ($parts.Count -gt 3) {
            $displayPath = "..." + "\" + $parts[-2] + "\" + $parts[-1]
        }
    }

    # [Git]
    $gitText = $null
    $gitColor = "DarkGray"
    $gitBg = "Black"
    
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branch = git branch --show-current 2>$null
        if ($branch) {
            $status = git status --porcelain 2>$null
            if ($status) {
                # Dirty
                $gitColor = "Black"
                $gitBg = "DarkYellow" # Gold for dirty
                $count = ($status | Measure-Object).Count
                $gitText = "$($i.Git) $branch +$count"
            } else {
                # Clean
                $gitColor = "Black"
                $gitBg = "Green"
                $gitText = "$($i.Git) $branch"
            }
        }
    }

    # [Stats]
    # RAM Calculation
    $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | 
           Select-Object @{N="P";E={[math]::Round(($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize * 100)}}
    $memPercent = if ($mem) { $mem.P } else { 0 }
    $memColor = if ($memPercent -gt 85) { "Red" } elseif ($memPercent -gt 60) { "Yellow" } else { "Cyan" }
    
    # Time
    $time = Get-Date -Format "HH:mm:ss"

    # --- 3. HELPER FOR PILLS ---
    function Write-Pill ($Icon, $Text, $BgColor, $FgColor, $IsFirst=$false) {
        if (-not $IsFirst) { Write-Host " " -NoNewline }
        Write-Host "$($i.Left)" -NoNewline -ForegroundColor $BgColor
        Write-Host " $Icon $Text " -NoNewline -ForegroundColor $FgColor -BackgroundColor $BgColor
        Write-Host "$($i.Right)" -NoNewline -ForegroundColor $BgColor
    }

    Write-Host "" # Empty line top

    # --- 4. RENDER LINE 1 ---
    
    # [User Pill]
    if ($isAdmin) {
        Write-Pill -Icon $i.Admin -Text $user -BgColor "Red" -FgColor "White" -IsFirst $true
    } else {
        Write-Pill -Icon $i.User -Text $user -BgColor "Blue" -FgColor "White" -IsFirst $true
    }
    
    # [Path Pill]
    Write-Pill -Icon $i.Folder -Text $displayPath -BgColor "Cyan" -FgColor "Black"
    
    # [Git Pill]
    if ($gitText) {
        Write-Pill -Icon $null -Text $gitText -BgColor $gitBg -FgColor $gitColor
    }

    # [Right Side Stats]
    # Calculate padding to push stats to the right (Optional, simple version uses fixed spacing)
    Write-Host "  " -NoNewline
    
    # Separator
    Write-Host "$($i.Sep) " -NoNewline -ForegroundColor DarkGray
    
    # RAM
    Write-Host "$($i.Mem) " -NoNewline -ForegroundColor $memColor
    Write-Host "$memPercent% " -NoNewline -ForegroundColor White
    
    # Separator
    Write-Host "$($i.Sep) " -NoNewline -ForegroundColor DarkGray
    
    # Time
    Write-Host "$($i.Time) " -NoNewline -ForegroundColor Magenta
    Write-Host "$time " -NoNewline -ForegroundColor White
    
    # Separator (End)
    Write-Host "$($i.Sep)" -NoNewline -ForegroundColor DarkGray
    
    if (-not $lastSuccess) {
         Write-Host " $($i.Boom) $lastExitCode" -NoNewline -ForegroundColor Red
    }

    Write-Host "" 

    # --- 5. RENDER LINE 2 (Input) ---
    Write-Host "╰─" -NoNewline -ForegroundColor DarkGray
    
    if ($lastSuccess) {
        Write-Host "$($i.Rocket)" -NoNewline -ForegroundColor Cyan
        Write-Host "$($i.Arrow)" -NoNewline -ForegroundColor Cyan
        Write-Host "$($i.Arrow)" -NoNewline -ForegroundColor Blue
        Write-Host "$($i.Arrow) " -NoNewline -ForegroundColor Magenta
    } else {
        Write-Host "$($i.Boom)" -NoNewline -ForegroundColor Red
        Write-Host "$($i.Arrow)" -NoNewline -ForegroundColor Red
        Write-Host "$($i.Arrow)" -NoNewline -ForegroundColor DarkRed
        Write-Host "$($i.Arrow) " -NoNewline -ForegroundColor Yellow
    }

    return " "
}




#region ═══════════════════════════════════════════════════════════════════════════
#        📂 AUTO SWITCH DRIVE KHI CD
#endregion ════════════════════════════════════════════════════════════════════════

Remove-Item Alias:cd -Force -ErrorAction SilentlyContinue

# Lưu lịch sử thư mục
$Script:DirHistory = [System.Collections.Generic.List[string]]::new()
$Script:DirHistoryIndex = -1

    function global:cd {
        [CmdletBinding()]
        param(
            [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
            [string[]]$PathArgs,
            [switch]$PassThru
        )

        # 0. Smart Alias: cd des -> Desktop
        if ($PathArgs -contains 'des' -or ($PathArgs -join '') -eq 'des') {
             if ($Script:DirHistory) { $Script:DirHistory.Add((Get-Location).Path) }
             Set-Location "C:\Users\Administrator.ADMIN\Desktop"
             return
        }
        
        # 1. Standard Smart Join (Ghép thông thường)
    $Path = ($PathArgs -join ' ').Trim()

    # 2. 🛡️ RAW PATH RECOVERY (Khôi phục đường dẫn gốc)
    # Fix lỗi: cd "New folder (3)" bị PowerShell hiểu nhầm thành "New folder 3"
    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) {
        try {
            # Lấy toàn bộ dòng lệnh gốc mà người dùng gõ
            $rawLine = $MyInvocation.Line
            $cmdName = $MyInvocation.InvocationName
            
            # Tách lấy phần sau lệnh cd/cdd/des...
            if ($rawLine -match "$cmdName\s+(.*)") {
                $rawPath = $Matches[1].Trim()
                
                # Loại bỏ tham số -PassThru nếu có
                if ($PassThru) { 
                    $rawPath = $rawPath -replace '-PassThru', '' 
                    $rawPath = $rawPath.Trim()
                }

                # Nếu đường dẫn Raw tồn tại, dùng nó ngay
                if (Test-Path $rawPath) {
                    $Path = $rawPath
                }
                # Nếu Raw Path vẫn chưa chuẩn (vd: chứa dấu ngoặc kép thừa), thử trim
                elseif (Test-Path ($rawPath -replace '^"|"$', "")) {
                    $Path = $rawPath -replace '^"|"$', ""
                }
                elseif (Test-Path ($rawPath -replace "^'|'$", "")) {
                    $Path = $rawPath -replace "^'|'$", ""
                }
            }
        } catch {}
    }

    $currentPath = (Get-Location).Path
    
    # Không có path → về home
    if ([string]::IsNullOrEmpty($Path)) {
        $Script:DirHistory.Add($currentPath)
        Set-Location $HOME
        return
    }
    
    # ~ → home
    if ($Path -eq '~') {
        $Script:DirHistory.Add($currentPath)
        Set-Location $HOME
        return
    }
    
    # - → quay lại
    if ($Path -eq '-') {
        if ($Script:DirHistory.Count -gt 0) {
            $prev = $Script:DirHistory[$Script:DirHistory.Count - 1]
            $Script:DirHistory.RemoveAt($Script:DirHistory.Count - 1)
            Set-Location $prev
            Write-Host "  ↩️  Quay lại: $prev" -ForegroundColor $Script:Theme.Muted
        } else {
            Write-Host "  ⚠️  Không có lịch sử thư mục" -ForegroundColor $Script:Theme.Warning
        }
        return
    }
    
    # .. x n → đi lên nhiều cấp
    if ($Path -match '^\.\.(\d+)$') {
        $levels = [int]$Matches[1]
        $targetPath = $currentPath
        for ($i = 0; $i -lt $levels; $i++) {
            $targetPath = Split-Path $targetPath -Parent
            if ([string]::IsNullOrEmpty($targetPath)) { break }
        }
        if ($targetPath) {
            $Script:DirHistory.Add($currentPath)
            Set-Location $targetPath
            Write-Host "  ⬆️  Lên $levels cấp" -ForegroundColor $Script:Theme.Muted
        }
        return
    }
    
    # Kiểm tra đổi ổ đĩa
    if ($Path -match '^([A-Za-z]):') {
        $targetDrive = $Matches[1].ToUpper()
        $currentDrive = (Get-Location).Drive.Name.ToUpper()
        
        if ($targetDrive -ne $currentDrive) {
            Write-Host "  💽 $currentDrive`: ➜ $targetDrive`:" -ForegroundColor $Script:Theme.Primary
        }
    }
    
    # Chuyển đến đường dẫn
    try {
        $Script:DirHistory.Add($currentPath)
        
        # Ưu tiên LiteralPath để xử lý ký tự đặc biệt như [ ] ( )
        if ($PassThru) {
            Set-Location -LiteralPath $Path -PassThru -ErrorAction Stop
        } else {
            Set-Location -LiteralPath $Path -ErrorAction Stop
        }
    } catch {
        # Fallback về Path thường nếu Literal thất bại (hiếm)
        try {
            if ($PassThru) {
                Set-Location -Path $Path -PassThru -ErrorAction Stop
            } else {
                Set-Location -Path $Path -ErrorAction Stop
            }
        } catch {
            $Script:DirHistory.RemoveAt($Script:DirHistory.Count - 1)
            Write-Host "  ❌ Không thể chuyển đến '$Path'" -ForegroundColor $Script:Theme.Error
            Write-Host "     $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
}

Set-Alias -Name cdd -Value cd -Scope Global

# Alias nhanh đến Desktop (Sửa lại thành Function để tránh lỗi)
function global:des {
    Set-Location "C:\Users\Administrator.ADMIN\Desktop"
}


#region ═══════════════════════════════════════════════════════════════════════════
#        📊 SIZESORT (NÂNG CẤP)
#endregion ════════════════════════════════════════════════════════════════════════

function global:sizesort {
    [CmdletBinding()]
    param(
        [Alias('f', 'p')]
        [string]$Path = '.',
        [switch]$IncludeSelf = $true,
        [Alias('n')]
        [int]$Top = 0,
        [Alias('h')]
        [switch]$Human,
        [switch]$NoProgress
    )

    # Đã xóa Format-Size cục bộ để dùng Global Function

    function Get-SizeBar {
        param([double]$Percent, [int]$Width = 20)
        $filled = [math]::Floor($Percent * $Width / 100)
        $empty = $Width - $filled
        $bar = "█" * $filled + "░" * $empty
        
        $color = switch ($Percent) {
            { $_ -ge 80 } { "Red" }
            { $_ -ge 50 } { "Yellow" }
            default { "Green" }
        }
        return @{ Bar = $bar; Color = $color }
    }

    try {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
        $baseItem = Get-Item -LiteralPath $resolvedPath.Path -ErrorAction Stop

        Write-Host ""
        Write-Host "  📊 Analyzing: " -NoNewline -ForegroundColor $Script:Theme.Primary
        Write-Host $resolvedPath.Path -ForegroundColor White
        Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray

        $dirs = @()
        if ($IncludeSelf) { $dirs += $baseItem }
        $dirs += Get-ChildItem -LiteralPath $resolvedPath.Path -Directory -ErrorAction SilentlyContinue

        if (-not $dirs -or $dirs.Count -eq 0) {
            Write-Host "  ⚠️  Không tìm thấy thư mục nào" -ForegroundColor $Script:Theme.Warning
            return
        }

        $results = @()
        $total = $dirs.Count
        $current = 0

        foreach ($d in $dirs) {
            $current++
            if (-not $NoProgress) {
                $percent = [math]::Floor($current / $total * 100)
                Write-Progress -Activity "Đang quét thư mục..." -Status "$($d.Name)" -PercentComplete $percent
            }
            
            try {
                $sum = (Get-ChildItem -LiteralPath $d.FullName -Recurse -File -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum).Sum
            } catch { $sum = 0 }
            if ($null -eq $sum) { $sum = 0 }

            $results += [PSCustomObject]@{
                Name      = $d.Name
                SizeBytes = [int64]$sum
                SizeHuman = Format-Size -Bytes $sum
                FullName  = $d.FullName
            }
        }
        
        Write-Progress -Activity "Đang quét thư mục..." -Completed

        $sorted = $results | Sort-Object -Property SizeBytes -Descending
        if ($Top -gt 0) { $sorted = $sorted | Select-Object -First $Top }

        $maxSize = ($sorted | Measure-Object -Property SizeBytes -Maximum).Maximum
        if ($maxSize -eq 0) { $maxSize = 1 }

        Write-Host ""
        
        foreach ($item in $sorted) {
            $percent = [math]::Round($item.SizeBytes / $maxSize * 100, 1)
            $barInfo = Get-SizeBar -Percent $percent
            
            $icon = if ($item.Name -eq $baseItem.Name) { "📂" } else { "📁" }
            
            Write-Host "  $icon " -NoNewline
            Write-Host ("{0,-30}" -f ($item.Name.Substring(0, [Math]::Min(30, $item.Name.Length)))) -NoNewline -ForegroundColor White
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            Write-Host $barInfo.Bar -NoNewline -ForegroundColor $barInfo.Color
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            Write-Host ("{0,10}" -f $item.SizeHuman) -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray
        $totalSize = ($sorted | Measure-Object -Property SizeBytes -Sum).Sum
        Write-Host "  📈 Tổng: " -NoNewline -ForegroundColor $Script:Theme.Primary
        Write-Host (Format-Size -Bytes $totalSize) -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "  ❌ Lỗi: $_" -ForegroundColor $Script:Theme.Error
    }
}


#region ═══════════════════════════════════════════════════════════════════════════
#        🔍 TÌM KIẾM NHANH
#endregion ════════════════════════════════════════════════════════════════════════

function global:ff {
    <# .SYNOPSIS Tìm file theo tên #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Pattern,
        [string]$Path = ".",
        [int]$Depth = 5
    )
    
    Write-Host ""
    Write-Host "  🔍 Tìm kiếm: " -NoNewline -ForegroundColor $Script:Theme.Primary
    Write-Host "'$Pattern'" -ForegroundColor Yellow
    Write-Host ""
    
    $results = Get-ChildItem -Path $Path -Recurse -Depth $Depth -ErrorAction SilentlyContinue | 
               Where-Object { $_.Name -like "*$Pattern*" }
    
    if ($results) {
        $results | ForEach-Object {
            $icon = if ($_.PSIsContainer) { "📁" } else { "📄" }
            $size = if (-not $_.PSIsContainer) { " ({0})" -f (Format-Size $_.Length) } else { "" }
            Write-Host "  $icon " -NoNewline
            Write-Host $_.FullName -NoNewline -ForegroundColor Cyan
            Write-Host $size -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "  ✅ Tìm thấy $($results.Count) kết quả" -ForegroundColor $Script:Theme.Success
    } else {
        Write-Host "  ⚠️  Không tìm thấy kết quả" -ForegroundColor $Script:Theme.Warning
    }
    Write-Host ""
}

function global:ftext {
    <# .SYNOPSIS Tìm text trong file #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Pattern,
        [string]$Path = ".",
        [string]$Include = "*.*"
    )
    
    Write-Host ""
    Write-Host "  🔍 Tìm text: " -NoNewline -ForegroundColor $Script:Theme.Primary
    Write-Host "'$Pattern'" -ForegroundColor Yellow
    Write-Host ""
    
    Get-ChildItem -Path $Path -Include $Include -Recurse -ErrorAction SilentlyContinue | 
    Select-String -Pattern $Pattern -ErrorAction SilentlyContinue |
    ForEach-Object {
        Write-Host "  📄 " -NoNewline
        Write-Host "$($_.Path)" -NoNewline -ForegroundColor Cyan
        Write-Host ":$($_.LineNumber)" -NoNewline -ForegroundColor Yellow
        Write-Host " → $($_.Line.Trim())" -ForegroundColor White
    }
    Write-Host ""
}


#region ═══════════════════════════════════════════════════════════════════════════
#        🛠️ TIỆN ÍCH
#endregion ════════════════════════════════════════════════════════════════════════

# Mở thư mục hiện tại trong Explorer
function global:open {
    param([string]$Path = ".")
    $resolved = Resolve-Path $Path -ErrorAction SilentlyContinue
    if ($resolved) {
        explorer.exe $resolved.Path
        Write-Host "  📂 Đã mở: $($resolved.Path)" -ForegroundColor $Script:Theme.Success
    } else {
        Write-Host "  ❌ Không tìm thấy: $Path" -ForegroundColor $Script:Theme.Error
    }
}

# Tạo và chuyển đến thư mục mới
function global:mkcd {
    param([Parameter(Mandatory)][string]$Name)
    New-Item -ItemType Directory -Name $Name -ErrorAction Stop | Out-Null
    Set-Location $Name
    Write-Host "  📁 Đã tạo và chuyển đến: $Name" -ForegroundColor $Script:Theme.Success
}

# Xóa có xác nhận đẹp
function global:del {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [switch]$Force
    )
    
    $item = Get-Item $Path -ErrorAction SilentlyContinue
    if (-not $item) {
        Write-Host "  ❌ Không tìm thấy: $Path" -ForegroundColor $Script:Theme.Error
        return
    }
    
    $icon = if ($item.PSIsContainer) { "📁" } else { "📄" }
    
    if (-not $Force) {
        Write-Host ""
        Write-Host "  ╭────────────────────────────────────╮" -ForegroundColor $Script:Theme.Warning
        Write-Host "  │  ⚠️  Xác nhận xóa?                  │" -ForegroundColor $Script:Theme.Warning
        Write-Host "  ╰────────────────────────────────────╯" -ForegroundColor $Script:Theme.Warning
        Write-Host "  $icon $($item.FullName)" -ForegroundColor White
        Write-Host ""
        Write-Host "  [Y] Xóa  [N] Hủy" -ForegroundColor $Script:Theme.Muted
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.Character -ne 'y' -and $key.Character -ne 'Y') {
            Write-Host "  ✅ Đã hủy" -ForegroundColor $Script:Theme.Success
            return
        }
    }
    
    Remove-Item $Path -Recurse -Force
    Write-Host "  🗑️  Đã xóa: $Path" -ForegroundColor $Script:Theme.Success
}

# Copy siêu cấp vũ trụ
function global:install {
    # Define available tools/languages with their install logic
    $tools = @(
        @{ Name = "Winget";       Id = "winget";       Cmd = "winget";           Install = { install-winget } }
        @{ Name = "Python";       Id = "Python.Python.3"; Cmd = "python";           Install = { winget install -e --id Python.Python.3 } }
        @{ Name = "Node.js";      Id = "OpenJS.NodeJS";   Cmd = "node";             Install = { winget install -e --id OpenJS.NodeJS } }
        @{ Name = "Go";           Id = "GoLang.Go";       Cmd = "go";               Install = { winget install -e --id GoLang.Go } }
        @{ Name = "Rust";         Id = "Rustlang.Rustup"; Cmd = "rustc";            Install = { winget install -e --id Rustlang.Rustup } }
        @{ Name = "C++ (MinGW)";  Id = "MinGW";           Cmd = "gcc";              Install = { winget install -e --id GnuWin32.Make } } # Simplified check
        @{ Name = "Java (JDK)";   Id = "Oracle.JDK.21";   Cmd = "java";             Install = { winget install -e --id Oracle.JDK.21 } }
        @{ Name = "Git";          Id = "Git.Git";         Cmd = "git";              Install = { winget install -e --id Git.Git } }
        @{ Name = "VS Code";      Id = "Microsoft.VisualStudioCode"; Cmd = "code"; Install = { winget install -e --id Microsoft.VisualStudioCode } }
        @{ Name = "GemKit CLI";   Id = "gemkit-cli";      Cmd = "gk";               Install = { npm install -g gemkit-cli } }
        @{ Name = "UiPro CLI";    Id = "uipro-cli";       Cmd = "uipro";            Install = { npm install -g uipro-cli } }
    )

    # Prepare menu options
    $menuOptions = @()
    foreach ($t in $tools) {
        $status = if (Get-Command $t.Cmd -ErrorAction SilentlyContinue) { "[Installed]" } else { "" }
        $menuOptions += "$($t.Name) $status"
    }

    Write-Host ""
    Write-Host "  📦 INSTALLER HUB" -ForegroundColor Cyan
    Write-Host "  ────────────────" -ForegroundColor DarkGray
    Write-Host "  Space: Select/Deselect | Enter: Install | Esc: Cancel" -ForegroundColor DarkGray
    Write-Host ""

    # Use the existing interactive menu system
    $selectedNames = Show-InteractiveMenu -Title "Select Tools to Install" -Options $menuOptions -Multi

    if (-not $selectedNames) {
        Write-Host "  ❌ No selection made." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  🚀 Starting Installation..." -ForegroundColor Magenta
    Write-Host "  ───────────────────────────" -ForegroundColor DarkGray

    foreach ($selection in $selectedNames) {
        # Match selection back to tool object (basic string matching)
        $tool = $tools | Where-Object { $selection -match [regex]::Escape($_.Name) } | Select-Object -First 1
        
        if ($tool) {
            Write-Host "  ⏳ Installing $($tool.Name)..." -ForegroundColor Yellow
            try {
                & $tool.Install
                Write-Host "  ✅ $($tool.Name) installed/checked." -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Failed to install $($tool.Name): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "  ✨ All tasks finished!" -ForegroundColor Cyan
    Write-Host ""
}

function global:antigravity {
    [CmdletBinding()]
    param([switch]$Update)

    # ─── HEADER ────────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  ╔═════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                🌌 ANTIGRAVITY PROTOCOL INITIATED 🌌                     ║" -ForegroundColor Cyan
    Write-Host "  ╚═════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "     Preparing to download skills for antigravity google..." -ForegroundColor DarkGray
    Write-Host ""

    # ─── DOCUMENTATION ─────────────────────────────────────────────────
    Write-Host "  📚 DOCUMENTATION" -ForegroundColor Yellow
    Write-Host "  │" -ForegroundColor DarkGray
    Write-Host "  ├─ GemKit CLI : " -NoNewline -ForegroundColor DarkGray
    Write-Host "https://github.com/therichardngai-code/gemkit-cli" -ForegroundColor Blue
    Write-Host "  └─ UI/UX Pro  : " -NoNewline -ForegroundColor DarkGray
    Write-Host "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill" -ForegroundColor Blue
    Write-Host ""

    # ─── DEPENDENCIES ──────────────────────────────────────────────────
    Write-Host "  🛠️  DEPENDENCY CHECK" -ForegroundColor Yellow
    Write-Host "  │" -ForegroundColor DarkGray
    
    # Helper to check/install tools
    function Check-Tool {
        param($Name, $Cmd, $InstallScript)
        $status = if (Get-Command $Cmd -ErrorAction SilentlyContinue) { "Installed" } else { "Missing" }
        
        Write-Host "  ├─ $Name" -NoNewline -ForegroundColor DarkGray
        Write-Host (" " * (12 - $Name.Length) + ": ") -NoNewline -ForegroundColor DarkGray
        
        if ($status -eq "Installed") {
            if ($Update) {
                Write-Host "🔄 Updating..." -ForegroundColor Cyan
                try {
                    & $InstallScript | Out-Null
                    Write-Host "     └─ ✅ Updated" -ForegroundColor Green
                } catch {
                    Write-Host "     └─ ❌ Update Failed" -ForegroundColor Red
                }
            } else {
                Write-Host "✅ Installed" -ForegroundColor Green
            }
        } else {
            Write-Host "⏳ Installing..." -ForegroundColor Yellow
            try {
                & $InstallScript
                if (Get-Command $Cmd -ErrorAction SilentlyContinue) {
                    Write-Host "     └─ ✅ Install Success" -ForegroundColor Green
                } else {
                    Write-Host "     └─ ❌ Install Failed" -ForegroundColor Red
                }
            } catch {
                Write-Host "     └─ ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    Check-Tool -Name "winget" -Cmd "winget" -InstallScript { install-winget }
    Check-Tool -Name "uipro-cli" -Cmd "uipro" -InstallScript { npm install -g uipro-cli }
    Check-Tool -Name "gemkit-cli" -Cmd "gk" -InstallScript { npm install -g gemkit-cli }
    
    Write-Host ""

    # ─── TARGET SELECTION ──────────────────────────────────────────────
    Write-Host "  📂 TARGET SELECTION" -ForegroundColor Yellow
    Write-Host "  │  Select directory to download file (Enter for current)" -ForegroundColor DarkGray
    Write-Host "  │" -ForegroundColor DarkGray
    Write-Host "  └─ Path: " -NoNewline -ForegroundColor Cyan
    
    $inputDir = Read-Host
    if ([string]::IsNullOrWhiteSpace($inputDir)) {
        $targetDir = Get-Location
        Write-Host "     Using current: $targetDir" -ForegroundColor DarkGray
    } else {
        $targetDir = $inputDir
    }

    if (-not (Test-Path $targetDir)) {
        try {
            New-Item -ItemType Directory -Force -Path $targetDir -ErrorAction Stop | Out-Null
            Write-Host "     ✨ Created directory: $targetDir" -ForegroundColor Green
        } catch {
            Write-Host "     ❌ Error creating directory: $($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }

    # ─── EXECUTION ─────────────────────────────────────────────────────
    Write-Host ""
    Write-Host "  🚀 EXECUTING PROTOCOLS..." -ForegroundColor Magenta
    
    Push-Location $targetDir
    try {
        Write-Host "  ├─ Running: " -NoNewline -ForegroundColor DarkGray
        Write-Host "gk init" -ForegroundColor White
        gk init

        Write-Host "  └─ Running: " -NoNewline -ForegroundColor DarkGray
        Write-Host "uipro init --ai antigravity" -ForegroundColor White
        uipro init --ai antigravity
        
        Write-Host ""
        Write-Host "  ✨ ANTIGRAVITY MISSION ACCOMPLISHED ✨" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "  💥 MISSION FAILED" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function global:uipro {
    # Fix: Do not use named parameters (param($Command)) because it consumes the first argument (e.g., 'init')
    # and prevents it from being passed to the executable in @args.
    
    if ($args.Count -gt 0 -and $args[0] -eq "update") {
        Write-Host ""
        Write-Host "  🔄 UIPRO UPDATE SEQUENCE" -ForegroundColor Cyan
        Write-Host "  ────────────────────────" -ForegroundColor DarkGray
        Write-Host "  Updating uipro-cli and gemkit-cli..." -ForegroundColor Yellow
        
        npm install -g uipro-cli gemkit-cli
        
        if ($?) {
            Write-Host "  ✅ Update Completed Successfully" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Update Failed" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        # Pass ALL arguments (@args) through to the executable
        if (Get-Command uipro.cmd -ErrorAction SilentlyContinue) {
             & uipro.cmd @args
        } elseif (Get-Command uipro.ps1 -ErrorAction SilentlyContinue) {
             & uipro.ps1 @args
        } else {
             Write-Host "  ❌ 'uipro' command not found. Run 'antigravity' to install." -ForegroundColor Red
        }
    }
}


# Thông tin hệ thống - Enhanced Version
function global:sysinfo { & "C:\Users\Administrator.ADMIN\Documents\WindowsPowerShell\sysinfo.ps1" }

#region ═══════════════════════════════════════════════════════════════════════════
#        🌍 TUI ENVIRONMENT MANAGER (Interactive)
#endregion ════════════════════════════════════════════════════════════════════════

function global:env {
    <#
    .SYNOPSIS
        Interactive Environment Variable Manager với TUI
    .DESCRIPTION
        Gõ 'env' để mở TUI quản lý biến môi trường
    #>
    param(
        [ValidateSet("", "tui", "list", "add", "del", "edit", "export", "import")]
        [string]$Action = "tui",
        [string]$Name,
        [string]$Value,
        [string]$Scope = "User"
    )
    
    # === HELPER FUNCTIONS ===
    function Get-AllEnvVars {
        param([string]$ScopeFilter = "All")
        $result = @()
        
        $targets = @{
            "User" = [System.EnvironmentVariableTarget]::User
            "Machine" = [System.EnvironmentVariableTarget]::Machine
            "Process" = [System.EnvironmentVariableTarget]::Process
        }
        
        foreach ($scope in $targets.Keys) {
            if ($ScopeFilter -ne "All" -and $scope -ne $ScopeFilter) { continue }
            
            $vars = [Environment]::GetEnvironmentVariables($targets[$scope])
            foreach ($key in $vars.Keys) {
                $result += [PSCustomObject]@{
                    Name = $key
                    Value = $vars[$key]
                    Scope = $scope
                    Icon = switch($scope) { "User" { "👤" } "Machine" { "💻" } "Process" { "⚡" } }
                }
            }
        }
        return $result | Sort-Object Name
    }
    
    function Show-EnvTUI {
        $currentScope = "All"
        $searchFilter = ""
        $selectedIndex = 0
        $viewMode = "list" # list, detail, edit
        
        [Console]::CursorVisible = $false
        Enable-MouseTracking
        
        try {
            while ($true) {
                Clear-Host
                
                # Header
                Write-Host ""
                Write-Host "  ╭──────────────────────────────────────────────────────────╮" -ForegroundColor Magenta
                Write-Host "  │       🌍 ENVIRONMENT VARIABLE MANAGER (TUI)              │" -ForegroundColor Magenta
                Write-Host "  ╰──────────────────────────────────────────────────────────╯" -ForegroundColor Magenta
                
                $headerEndY = [Console]::CursorTop
                
                # Toolbar
                Write-Host ""
                Write-Host "  Scope: " -NoNewline -ForegroundColor DarkGray
                $scopeStartY = [Console]::CursorTop
                @("All", "User", "Machine", "Process") | ForEach-Object {
                    if ($_ -eq $currentScope) {
                        Write-Host " [$_] " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
                    } else {
                        Write-Host " $_ " -NoNewline -ForegroundColor Cyan
                    }
                }
                Write-Host "    🔍 Filter: " -NoNewline -ForegroundColor DarkGray
                Write-Host $(if ($searchFilter) { $searchFilter } else { "(none)" }) -ForegroundColor Yellow
                Write-Host ""
                
                # Get filtered data
                $envVars = Get-AllEnvVars -ScopeFilter $currentScope
                if ($searchFilter) {
                    $envVars = $envVars | Where-Object { $_.Name -like "*$searchFilter*" -or $_.Value -like "*$searchFilter*" }
                }
                
                # Display list
                Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
                Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
                Write-Host ("{0,-3}" -f "##") -NoNewline -ForegroundColor DarkGray
                Write-Host ("{0,-20}" -f "  NAME") -NoNewline -ForegroundColor Cyan
                Write-Host ("{0,-35}" -f "VALUE") -NoNewline -ForegroundColor DarkCyan
                Write-Host "│" -ForegroundColor DarkGray
                Write-Host "  ├─────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
                
                $listStartY = [Console]::CursorTop
                $displayCount = [math]::Min($envVars.Count, 15)
                $startIdx = [math]::Max(0, $selectedIndex - 7)
                $visibleItems = @()
                
                for ($i = $startIdx; $i -lt [math]::Min($startIdx + $displayCount, $envVars.Count); $i++) {
                    $item = $envVars[$i]
                    $visibleItems += $i
                    $isSelected = ($i -eq $selectedIndex)
                    
                    $prefix = if ($isSelected) { "▶" } else { " " }
                    $fg = if ($isSelected) { "Black" } else { "White" }
                    $bg = if ($isSelected) { "Cyan" } else { $Host.UI.RawUI.BackgroundColor }
                    
                    $displayVal = if ($item.Value.Length -gt 32) { $item.Value.Substring(0,29) + "..." } else { $item.Value }
                    $displayName = if ($item.Name.Length -gt 18) { $item.Name.Substring(0,15) + "..." } else { $item.Name }
                    
                    Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
                    Write-Host "$($item.Icon)" -NoNewline
                    Write-Host "$prefix" -NoNewline -ForegroundColor $(if ($isSelected) { "Yellow" } else { "DarkGray" })
                    Write-Host ("{0,-18}" -f $displayName) -NoNewline -ForegroundColor $fg -BackgroundColor $bg
                    Write-Host ("{0,-35}" -f $displayVal) -NoNewline -ForegroundColor $(if ($isSelected) { "Black" } else { "DarkGray" }) -BackgroundColor $bg
                    Write-Host "│" -ForegroundColor DarkGray
                }
                
                Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
                Write-Host "   Showing $($envVars.Count) variables" -ForegroundColor DarkGray
                
                # Controls
                Write-Host ""
                Write-Host "  ╭─────────────────────────── CONTROLS ───────────────────────────╮" -ForegroundColor DarkGray
                Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
                Write-Host "🖱️ Click/↑↓" -NoNewline -ForegroundColor Yellow
                Write-Host ":Navigate  " -NoNewline -ForegroundColor DarkGray
                Write-Host "1-4" -NoNewline -ForegroundColor Yellow
                Write-Host ":Scope  " -NoNewline -ForegroundColor DarkGray
                Write-Host "/" -NoNewline -ForegroundColor Yellow
                Write-Host ":Search  " -NoNewline -ForegroundColor DarkGray
                Write-Host "Enter" -NoNewline -ForegroundColor Yellow
                Write-Host ":Detail  " -NoNewline -ForegroundColor DarkGray
                Write-Host "A" -NoNewline -ForegroundColor Green
                Write-Host ":Add  " -NoNewline -ForegroundColor DarkGray
                Write-Host "E" -NoNewline -ForegroundColor Cyan
                Write-Host ":Edit  " -NoNewline -ForegroundColor DarkGray
                Write-Host "D" -NoNewline -ForegroundColor Red
                Write-Host ":Del │" -ForegroundColor DarkGray
                Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
                Write-Host "X" -NoNewline -ForegroundColor Yellow
                Write-Host ":Export  " -NoNewline -ForegroundColor DarkGray
                Write-Host "I" -NoNewline -ForegroundColor Yellow
                Write-Host ":Import  " -NoNewline -ForegroundColor DarkGray
                Write-Host "Q/Esc" -NoNewline -ForegroundColor Red
                Write-Host ":Quit" -NoNewline -ForegroundColor DarkGray
                Write-Host (" " * 25) -NoNewline
                Write-Host "│" -ForegroundColor DarkGray
                Write-Host "  ╰────────────────────────────────────────────────────────────────╯" -ForegroundColor DarkGray
                
                # Key handling with mouse support
                if (-not $Host.UI.RawUI.KeyAvailable) {
                    Start-Sleep -Milliseconds 10
                    continue
                }
                
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                
                # Handle Mouse Events
                if ($key.VirtualKeyCode -eq 27) {
                    $mouseX = 0
                    $mouseY = 0
                    $isDoubleClick = $false
                    $mouseButton = 0
                    
                    if (Parse-MouseEvent ([ref]$mouseX) ([ref]$mouseY) ([ref]$isDoubleClick) ([ref]$mouseButton)) {
                        # Check list click
                        if ($mouseY -ge $listStartY -and $mouseY -lt ($listStartY + $visibleItems.Count)) {
                            $clickedRowIndex = $mouseY - $listStartY
                            if ($clickedRowIndex -lt $visibleItems.Count) {
                                $selectedIndex = $visibleItems[$clickedRowIndex]
                            }
                        }
                        
                        # Check scope button clicks
                        if ($mouseY -eq $scopeStartY) {
                            if ($mouseX -ge 10 -and $mouseX -lt 15) { $currentScope = "All"; $selectedIndex = 0 }
                            elseif ($mouseX -ge 16 -and $mouseX -lt 22) { $currentScope = "User"; $selectedIndex = 0 }
                            elseif ($mouseX -ge 23 -and $mouseX -lt 32) { $currentScope = "Machine"; $selectedIndex = 0 }
                            elseif ($mouseX -ge 33 -and $mouseX -lt 42) { $currentScope = "Process"; $selectedIndex = 0 }
                        }
                        
                        continue
                    }
                    
                    # Not a mouse event, check if Esc
                    if (-not $Host.UI.RawUI.KeyAvailable) {
                        return
                    }
                }
                
                switch ($key.VirtualKeyCode) {
                    38 { if ($selectedIndex -gt 0) { $selectedIndex-- } } # Up
                    40 { if ($selectedIndex -lt $envVars.Count - 1) { $selectedIndex++ } } # Down
                    49 { $currentScope = "All"; $selectedIndex = 0 } # 1
                    50 { $currentScope = "User"; $selectedIndex = 0 } # 2
                    51 { $currentScope = "Machine"; $selectedIndex = 0 } # 3
                    52 { $currentScope = "Process"; $selectedIndex = 0 } # 4
                    
                    # Search (/)
                    191 {
                        Write-Host ""
                        Write-Host "  🔍 Enter search term: " -NoNewline -ForegroundColor Cyan
                        $searchFilter = Read-Host
                        $selectedIndex = 0
                    }
                    
                    # Enter - Detail view
                    13 {
                        if ($envVars -and $selectedIndex -lt $envVars.Count) {
                            $item = $envVars[$selectedIndex]
                            Clear-Host
                            Write-Host ""
                            Write-Host "  ╭──────────────── VARIABLE DETAIL ────────────────╮" -ForegroundColor Cyan
                            Write-Host "  │ Name  : " -NoNewline -ForegroundColor DarkGray
                            Write-Host $item.Name -ForegroundColor Yellow
                            Write-Host "  │ Scope : " -NoNewline -ForegroundColor DarkGray
                            Write-Host "$($item.Icon) $($item.Scope)" -ForegroundColor Cyan
                            Write-Host "  │ Value :" -ForegroundColor DarkGray
                            
                            # Show full value, split if PATH
                            if ($item.Name -like "*PATH*" -or $item.Value -like "*;*") {
                                $item.Value -split ";" | ForEach-Object {
                                    if ($_) { Write-Host "  │   → $_" -ForegroundColor White }
                                }
                            } else {
                                Write-Host "  │   $($item.Value)" -ForegroundColor White
                            }
                            
                            Write-Host "  ╰───────────────────────────────────────────────╯" -ForegroundColor Cyan
                            Write-Host ""
                            Write-Host "  Press any key to go back..." -ForegroundColor DarkGray
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        }
                    }
                    
                    # Add (A)
                    65 {
                        Write-Host ""
                        Write-Host "  ➕ ADD NEW VARIABLE" -ForegroundColor Green
                        $newName = Read-Host "     Name"
                        $newValue = Read-Host "     Value"
                        $newScope = Show-InteractiveMenu -Title "Select Scope" -Options @("User", "Machine", "Process") -Color "Green"
                        
                        if ($newName -and $newValue -and $newScope) {
                            $target = switch ($newScope) {
                                "User" { [System.EnvironmentVariableTarget]::User }
                                "Machine" { [System.EnvironmentVariableTarget]::Machine }
                                "Process" { [System.EnvironmentVariableTarget]::Process }
                            }
                            [Environment]::SetEnvironmentVariable($newName, $newValue, $target)
                            Write-Host "  ✅ Added: $newName" -ForegroundColor Green
                            Start-Sleep -Seconds 1
                        }
                    }
                    
                    # Edit (E)
                    69 {
                        if ($envVars -and $selectedIndex -lt $envVars.Count) {
                            $item = $envVars[$selectedIndex]
                            Write-Host ""
                            Write-Host "  ✏️  EDIT: $($item.Name)" -ForegroundColor Cyan
                            Write-Host "     Current: $($item.Value)" -ForegroundColor DarkGray
                            $newValue = Read-Host "     New value (Enter to keep)"
                            
                            if ($newValue) {
                                $target = switch ($item.Scope) {
                                    "User" { [System.EnvironmentVariableTarget]::User }
                                    "Machine" { [System.EnvironmentVariableTarget]::Machine }
                                    "Process" { [System.EnvironmentVariableTarget]::Process }
                                }
                                [Environment]::SetEnvironmentVariable($item.Name, $newValue, $target)
                                Write-Host "  ✅ Updated!" -ForegroundColor Green
                                Start-Sleep -Seconds 1
                            }
                        }
                    }
                    
                    # Delete (D)
                    68 {
                        if ($envVars -and $selectedIndex -lt $envVars.Count) {
                            $item = $envVars[$selectedIndex]
                            Write-Host ""
                            Write-Host "  🗑️  DELETE: $($item.Name)?" -ForegroundColor Red
                            Write-Host "     [Y]es / [N]o" -ForegroundColor DarkGray
                            $confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            
                            if ($confirm.Character -eq 'y' -or $confirm.Character -eq 'Y') {
                                $target = switch ($item.Scope) {
                                    "User" { [System.EnvironmentVariableTarget]::User }
                                    "Machine" { [System.EnvironmentVariableTarget]::Machine }
                                    "Process" { [System.EnvironmentVariableTarget]::Process }
                                }
                                [Environment]::SetEnvironmentVariable($item.Name, $null, $target)
                                Write-Host "  ✅ Deleted!" -ForegroundColor Green
                                Start-Sleep -Seconds 1
                                $selectedIndex = [math]::Max(0, $selectedIndex - 1)
                            }
                        }
                    }
                    
                    # Export (X)
                    88 {
                        $exportPath = Join-Path $HOME "env_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
                        $envVars | ConvertTo-Json | Out-File $exportPath
                        Write-Host ""
                        Write-Host "  📦 Exported to: $exportPath" -ForegroundColor Green
                        Start-Sleep -Seconds 2
                    }
                    
                    # Import (I)
                    73 {
                        Write-Host ""
                        $importPath = Read-Host "  📥 Enter JSON file path"
                        if (Test-Path $importPath) {
                            $imported = Get-Content $importPath | ConvertFrom-Json
                            Write-Host "  Found $($imported.Count) variables. Import all? [Y/N]" -ForegroundColor Yellow
                            $confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            if ($confirm.Character -eq 'y') {
                                foreach ($item in $imported) {
                                    $target = switch ($item.Scope) {
                                        "User" { [System.EnvironmentVariableTarget]::User }
                                        default { [System.EnvironmentVariableTarget]::Process }
                                    }
                                    [Environment]::SetEnvironmentVariable($item.Name, $item.Value, $target)
                                }
                                Write-Host "  ✅ Imported!" -ForegroundColor Green
                            }
                        }
                        Start-Sleep -Seconds 1
                    }
                    
                    # Quit
                    { $_ -in 81, 27 } { return }
                }
            }
        } finally {
            Disable-MouseTracking
            [Console]::CursorVisible = $true
        }
    }
    
    # === DISPATCH ===
    switch ($Action) {
        "tui" { Show-EnvTUI }
        "list" { Get-AllEnvVars -ScopeFilter $Scope | Show-Table -Columns @("Icon", "Name", "Value") -Title "Environment Variables" }
        "add" { 
            if ($Name -and $Value) {
                $target = switch ($Scope) { "User" { [System.EnvironmentVariableTarget]::User } "Machine" { [System.EnvironmentVariableTarget]::Machine } default { [System.EnvironmentVariableTarget]::Process } }
                [Environment]::SetEnvironmentVariable($Name, $Value, $target)
                Write-Host "  ✅ Added: $Name = $Value [$Scope]" -ForegroundColor Green
            } else { Write-Host "  ❌ Usage: env add -Name VAR -Value VALUE -Scope User" -ForegroundColor Red }
        }
        "del" {
            if ($Name) {
                $target = switch ($Scope) { "User" { [System.EnvironmentVariableTarget]::User } "Machine" { [System.EnvironmentVariableTarget]::Machine } default { [System.EnvironmentVariableTarget]::Process } }
                [Environment]::SetEnvironmentVariable($Name, $null, $target)
                Write-Host "  ✅ Deleted: $Name" -ForegroundColor Green
            }
        }
        default { Show-EnvTUI }
    }
}

# Aliases cho backward compatibility
Set-Alias envlist "env list" -Scope Global
Set-Alias envadd "env add" -Scope Global  
Set-Alias envdel "env del" -Scope Global

#region ═══════════════════════════════════════════════════════════════════════════
#        🧰 EXTRA UTILITIES
#endregion ════════════════════════════════════════════════════════════════════════

# 🔄 Restart as Admin
function global:sudo {
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoExit -Command Set-Location '$PWD'"
}

# ⬇️ Drop to User Land (Ring 3)
function global:drop {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "  ⚠️  Bạn đã ở User Mode (Ring 3) rồi!" -ForegroundColor Yellow
        return
    }

    Write-Host "  🔽 Dropping to User Land (Ring 3)..." -ForegroundColor Cyan
    
    # Sử dụng 'runas /trustlevel:0x20000' để chạy với quyền Basic User (tước quyền Admin)
    # Ta phải bọc trong cmd /c để xử lý quoting phức tạp của runas
    $currentPath = $PWD.Path
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c runas /trustlevel:0x20000 ""pwsh -NoExit -Command Set-Location '$currentPath'"""
    $psi.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    
    Write-Host "  ✅ Đã mở shell User Mode mới." -ForegroundColor Green
    Write-Host "  (Gõ 'exit' để đóng cửa sổ Admin này nếu muốn)" -ForegroundColor DarkGray
}

# 📋 Xem processes chiếm RAM/CPU nhiều nhất
function global:top {
    param([int]$Count = 10)
    Write-Host ""
    Write-Host "  📊 TOP $Count PROCESSES (by RAM)" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First $Count | ForEach-Object {
        $mem = [math]::Round($_.WorkingSet64 / 1MB, 1)
        $cpu = [math]::Round($_.CPU, 1)
        Write-Host "  " -NoNewline
        Write-Host ("{0,-25}" -f $_.ProcessName) -NoNewline -ForegroundColor White
        Write-Host ("{0,8} MB" -f $mem) -NoNewline -ForegroundColor $(if($mem -gt 500){"Red"}elseif($mem -gt 200){"Yellow"}else{"Green"})
        Write-Host "  CPU: $cpu" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# 🧹 Dọn thư mục Temp
# 16. 🧹 BLACK HOLE CLEANER (MASSIVE EDITION)
function global:cleantemp {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Disable cursor for TUI feel
    [Console]::CursorVisible = $false
    
    try {
        Clear-Host
        Write-Host ""
        Write-Host "  🌌 BLACK HOLE SYSTEM CLEANER (MASSIVE EDITION)" -ForegroundColor Magenta
        Write-Host "  ──────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  🔍 Scanning system for junk... Please wait." -ForegroundColor Cyan
        Write-Host ""

        # === 1. DEFINE TARGETS ===
        $targets = [System.Collections.Generic.List[PSCustomObject]]::new()
        
        function Add-Target ($Group, $Name, $Path, $Cmd=$null) {
            if ($Cmd -or (Test-Path $Path)) {
                $targets.Add([PSCustomObject]@{ 
                    Group=$Group; Name=$Name; Path=$Path; Cmd=$Cmd; 
                    Size=0; SizeStr="..."; Selected=$true 
                })
            }
        }

        # --- SYSTEM (CORE) ---
        Add-Target "System" "User Temp" "$env:TEMP"
        Add-Target "System" "Crash Dumps" "$env:LOCALAPPDATA\CrashDumps"
        Add-Target "System" "Error Reports" "$env:LOCALAPPDATA\Microsoft\Windows\WER"
        Add-Target "System" "DirectX Shaders" "$env:LOCALAPPDATA\D3DSCache"
        Add-Target "System" "Font Cache" "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
        Add-Target "System" "Recycle Bin" "RecycleBin" 
        
        if ($isAdmin) {
            Add-Target "System" "Windows Temp" "$env:Windir\Temp"
            Add-Target "System" "Prefetch" "$env:Windir\Prefetch"
            Add-Target "System" "Win Update" "$env:Windir\SoftwareDistribution\Download"
            Add-Target "System" "Delivery Opt" "$env:Windir\SoftwareDistribution\DeliveryOptimization"
            Add-Target "System" "Defender Scans" "$env:ProgramData\Microsoft\Windows Defender\Scans\History\Results"
            Add-Target "System" "Event Logs" "EventLogs" -Cmd { Wevtutil el | ForEach-Object { Wevtutil cl "$_" } 2>$null }
        }

        # --- BROWSERS ---
        Add-Target "Browser" "Chrome Cache" "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        Add-Target "Browser" "Edge Cache" "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        Add-Target "Browser" "Firefox Cache" "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2"
        Add-Target "Browser" "Brave Cache" "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
        Add-Target "Browser" "Opera Cache" "$env:APPDATA\Opera Software\Opera Stable\Cache"
        Add-Target "Browser" "Vivaldi Cache" "$env:LOCALAPPDATA\Vivaldi\User Data\Default\Cache"

        # --- APPS ---
        Add-Target "Apps" "Discord Cache" "$env:APPDATA\discord\Cache"
        Add-Target "Apps" "Discord Code" "$env:APPDATA\discord\Code Cache"
        Add-Target "Apps" "Slack Cache" "$env:APPDATA\Slack\Cache"
        Add-Target "Apps" "Telegram Images" "$env:APPDATA\Telegram Desktop\tdata\user_data\cache"
        Add-Target "Apps" "Skype Cache" "$env:APPDATA\Microsoft\Skype for Desktop\Cache"
        Add-Target "Apps" "TeamViewer" "$env:APPDATA\TeamViewer\MRU"
        Add-Target "Apps" "Office Telemetry" "$env:LOCALAPPDATA\Microsoft\Office\16.0\Telemetry"

        # --- IDEs & EDITORS ---
        Add-Target "IDE" "VS Code Cache" "$env:APPDATA\Code\Cache"
        Add-Target "IDE" "VS Code Data" "$env:APPDATA\Code\CachedData"
        Add-Target "IDE" "Visual Studio" "$env:LOCALAPPDATA\Microsoft\VisualStudio\*\ComponentModelCache"
        Add-Target "IDE" "JetBrains" "$env:LOCALAPPDATA\JetBrains\*\caches"

        # --- GAMING ---
        Add-Target "Gaming" "Steam Cache" "$env:LOCALAPPDATA\Steam\htmlcache"
        Add-Target "Gaming" "Epic Games" "$env:LOCALAPPDATA\EpicGamesLauncher\Saved\webcache"
        Add-Target "Gaming" "Battle.net" "$env:LOCALAPPDATA\Battle.net\Cache"
        Add-Target "Gaming" "NVIDIA Cache" "$env:LOCALAPPDATA\NVIDIA Corporation\GLCache"
        Add-Target "Gaming" "AMD Cache" "$env:LOCALAPPDATA\AMD\DxCache"

        # --- DEV TOOLS ---
        if (Get-Command npm -ErrorAction SilentlyContinue) { Add-Target "Dev" "NPM Cache" "" -Cmd { npm cache clean --force 2>&1 | Out-Null } }
        if (Get-Command yarn -ErrorAction SilentlyContinue) { Add-Target "Dev" "Yarn Cache" "" -Cmd { yarn cache clean 2>&1 | Out-Null } }
        if (Get-Command pnpm -ErrorAction SilentlyContinue) { Add-Target "Dev" "PNPM Store" "" -Cmd { pnpm store prune 2>&1 | Out-Null } }
        if (Get-Command pip -ErrorAction SilentlyContinue) { Add-Target "Dev" "Pip Cache" "" -Cmd { pip cache purge 2>&1 | Out-Null } }
        if (Get-Command go -ErrorAction SilentlyContinue) { Add-Target "Dev" "Go Cache" "" -Cmd { go clean -modcache 2>&1 | Out-Null } }
        if (Get-Command docker -ErrorAction SilentlyContinue) { Add-Target "Dev" "Docker Build" "" -Cmd { docker builder prune -f 2>&1 | Out-Null } }
        if (Get-Command dotnet -ErrorAction SilentlyContinue) { Add-Target "Dev" "Nuget Cache" "" -Cmd { dotnet nuget locals all --clear 2>&1 | Out-Null } }
        
        Add-Target "Dev" "Gradle Cache" "$HOME\.gradle\caches"
        Add-Target "Dev" "Maven Repo" "$HOME\.m2\repository"
        Add-Target "Dev" "Chocolatey" "$env:LOCALAPPDATA\Temp\chocolatey"
        Add-Target "Dev" "Scoop Cache" "$HOME\scoop\cache"
        Add-Target "Dev" "Rust Cargo" "$HOME\.cargo\registry"

        # === 2. SCANNING PHASE ===
        $i = 0
        foreach ($t in $targets) {
            $i++
            Write-Progress -Activity "Scanning System" -Status "Analyzing $($t.Name)..." -PercentComplete (($i / $targets.Count) * 100)
            
            if ($t.Path -and $t.Path -ne "RecycleBin" -and (Test-Path $t.Path)) {
                try {
                    $stats = Get-ChildItem -Path $t.Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                    $t.Size = if ($stats.Sum) { $stats.Sum } else { 0 }
                } catch { $t.Size = 0 }
            } elseif ($t.Path -eq "RecycleBin") {
                try {
                    $t.Size = (Get-ChildItem "C:\`$Recycle.Bin" -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                } catch { $t.Size = 0 }
            }
            $t.SizeStr = Format-Size -Bytes $t.Size
            if ($t.Size -eq 0 -and $t.Group -ne "Dev" -and $t.Group -ne "System") { $t.Selected = $false }
        }
        
        # 🟢 FILTER: Hide 0-byte items (Keep if Size > 0 OR has Command)
        $targets = $targets | Where-Object { $_.Size -gt 0 -or $_.Cmd } | Sort-Object Group, Name
        
        Write-Progress -Activity "Scanning System" -Completed

        # === 3. INTERACTIVE MENU ===
        $idx = 0
        $startView = 0
        $maxView = 15
        $doneSelecting = $false
        
        while (-not $doneSelecting) {
            Clear-Host
            Write-Host ""
            Write-Host "  🌌 BLACK HOLE CLEANER" -ForegroundColor Magenta
            Write-Host "  Select targets (Space: Toggle, Enter: Clean)" -ForegroundColor DarkGray
            Write-Host "  ────────────────────────────────────────────" -ForegroundColor DarkGray
            
            $totalSelSize = ($targets | Where-Object Selected | Measure-Object -Property Size -Sum).Sum
            Write-Host "  📦 Potential Reclaim: $(Format-Size $totalSelSize)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "     [X]  TARGET                  SIZE        TYPE" -ForegroundColor Cyan
            
            if ($targets.Count -eq 0) {
                Write-Host ""
                Write-Host "     (Nothing to clean! System is spotless ✨)" -ForegroundColor Green
                Write-Host ""
                Start-Sleep -Seconds 2
                return
            }

            $endView = [math]::Min($targets.Count, $startView + $maxView)
            
            for ($k = $startView; $k -lt $endView; $k++) {
                $t = $targets[$k]
                $isCursor = ($k -eq $idx)
                
                $prefix = if ($isCursor) { "👉" } else { "  " }
                $check  = if ($t.Selected) { "[x]" } else { "[ ]" }
                
                $color = if ($isCursor) { "White" } elseif ($t.Selected) { "Green" } else { "DarkGray" }
                $bgColor = if ($isCursor) { "DarkGray" } else { "Black" }
                
                Write-Host "$prefix $check " -NoNewline -ForegroundColor $color -BackgroundColor $bgColor
                Write-Host ("{0,-23}" -f $t.Name) -NoNewline -ForegroundColor $color -BackgroundColor $bgColor
                
                $sizeCol = if ($t.Size -gt 1GB) { "Red" } elseif ($t.Size -gt 100MB) { "Yellow" } else { "Gray" }
                Write-Host ("{0,10}" -f $t.SizeStr) -NoNewline -ForegroundColor $sizeCol -BackgroundColor $bgColor
                Write-Host ("   {0}" -f $t.Group) -ForegroundColor "DarkCyan" -BackgroundColor $bgColor
            }
            
            Write-Host ""
            Write-Host "  ↑↓:Move  Space:Toggle  A:All  N:None  Enter:CLEAN  Esc:Quit" -ForegroundColor DarkGray

            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            switch ($key.VirtualKeyCode) {
                38 { if ($idx -gt 0) { $idx-- }; if ($idx -lt $startView) { $startView-- } }
                40 { if ($idx -lt $targets.Count - 1) { $idx++ }; if ($idx -ge $startView + $maxView) { $startView++ } }
                32 { $targets[$idx].Selected = -not $targets[$idx].Selected }
                65 { $targets | ForEach-Object { $_.Selected = $true } }
                78 { $targets | ForEach-Object { $_.Selected = $false } }
                13 { $doneSelecting = $true }
                27 { [Console]::CursorVisible = $true; return }
            }
        }

        # === 4. CLEANING PHASE ===
        Clear-Host
        Write-Host ""
        Write-Host "  🚀 INITIATING BLACK HOLE SEQUENCE..." -ForegroundColor Cyan
        Write-Host ""
        
        $selectedTargets = $targets | Where-Object Selected
        $count = 0
        $cleanedSize = 0
        
        foreach ($t in $selectedTargets) {
            $count++
            $pct = [math]::Round(($count / $selectedTargets.Count) * 100)
            $bar = "█" * [math]::Floor($pct * 0.3) + "░" * (30 - [math]::Floor($pct * 0.3))
            
            Write-Host "`r  [$bar] $pct% " -NoNewline -ForegroundColor Cyan
            Write-Host "Cleaning: $($t.Name)... " -NoNewline -ForegroundColor White
            
            # Reset locked counter for this target
            $lockedCount = 0
            
            try {
                if ($t.Path -eq "RecycleBin") {
                    Clear-RecycleBin -Force -ErrorAction SilentlyContinue | Out-Null
                }
                elseif ($t.Cmd) {
                    Invoke-Command -ScriptBlock $t.Cmd
                }
                elseif ($t.Path) {
                    if ($t.Name -like "*Win Update*") { Stop-Service wuauserv -ErrorAction SilentlyContinue }
                    
                    # FORCE DELETE LOGIC (Deep Clean with Consolidated Report)
                    Get-ChildItem -Path $t.Path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                        } catch {
                            # Increment counter instead of spamming console
                            $lockedCount++
                        }
                    }
                    
                    if ($t.Name -like "*Win Update*") { Start-Service wuauserv -ErrorAction SilentlyContinue }
                }
                
                if ($t.Path -ne "RecycleBin" -and $t.Path) { $cleanedSize += $t.Size }
                
                # Report locked files summary if any
                if ($lockedCount -gt 0) {
                    Write-Host "`n    ⚠️  Skipped $lockedCount locked files" -ForegroundColor Yellow
                }
                
            } catch {
                Write-Host "⚠️ Error processing $($t.Name)" -ForegroundColor Red
            }
        }

        ipconfig /flushdns | Out-Null

        Write-Host "`r  [$("█" * 30)] 100% " -NoNewline -ForegroundColor Green
        Write-Host "DONE!                       " -ForegroundColor Green
        Write-Host ""
        Write-Host "  ✨ Disk Space Reclaimed: $(Format-Size $cleanedSize)" -ForegroundColor Yellow
        Write-Host ""

    } finally {
        [Console]::CursorVisible = $true
    }
}

# 📄 TẠO NHIỀU FILE (Batch File Creator)
function global:mkfile {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$FileNames)

    if (-not $FileNames) {
        Write-Host "  ⚠️  Cách dùng: mkfile index.html style.css script.js ..." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  📄 FILE CREATOR" -ForegroundColor Cyan
    Write-Host "  ───────────────" -ForegroundColor DarkGray
    Write-Host "  📝 Files: " -NoNewline -ForegroundColor DarkGray
    Write-Host ($FileNames -join ", ") -ForegroundColor White
    
    Write-Host "  📂 Đích đến (Enter = Thư mục hiện tại): " -NoNewline -ForegroundColor Yellow
    $dest = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($dest)) { $dest = "." }
    
    # Tạo thư mục nếu chưa có
    if (-not (Test-Path $dest)) {
        try {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
            Write-Host "  ✨ Đã tạo thư mục: $dest" -ForegroundColor Cyan
        } catch {
            Write-Host "  ❌ Lỗi tạo thư mục!" -ForegroundColor Red
            return
        }
    }

    foreach ($file in $FileNames) {
        $path = Join-Path $dest $file
        try {
            if (-not (Test-Path $path)) {
                New-Item -ItemType File -Path $path -Force | Out-Null
                Write-Host "  ✅ Created: $file" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Exists : $file" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  ❌ Error  : $file ($($_.Exception.Message))" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# 🔌 Xem ports đang mở
function global:ports {
    param([string]$Filter)
    Write-Host ""
    Write-Host "  🔌 LISTENING PORTS" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    
    Get-NetTCPConnection -State Listen | ForEach-Object {
        $proc = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        $name = if ($proc) { $proc.ProcessName } else { "Unknown" }
        if (-not $Filter -or $name -like "*$Filter*" -or $_.LocalPort -eq $Filter) {
            Write-Host "  :" -NoNewline
            Write-Host ("{0,-6}" -f $_.LocalPort) -NoNewline -ForegroundColor Yellow
            Write-Host " → " -NoNewline -ForegroundColor DarkGray
            Write-Host $name -ForegroundColor Cyan
        }
    }
    Write-Host ""
}

# 📦 Cài/Gỡ nhanh (winget wrapper)
function global:install { winget install $args }
function global:uninstall { winget uninstall $args }
function global:search { winget search $args }
function global:upgrade { winget upgrade --all }

# Reload profile
function global:reload {
    Write-Host "  🔄 Đang reload profile..." -ForegroundColor $Script:Theme.Primary
    . $PROFILE
    Write-Host "  ✅ Đã reload!" -ForegroundColor $Script:Theme.Success
}

# Clipboard utilities
function global:clip { 
    param([Parameter(ValueFromPipeline)][string]$Text)
    process { $Text | Set-Clipboard }
    end { Write-Host "  📋 Đã copy vào clipboard" -ForegroundColor $Script:Theme.Success }
}

function global:paste { Get-Clipboard }

# Quick edit profile
function global:editprofile { 
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $PROFILE
    } elseif (Get-Command notepad++ -ErrorAction SilentlyContinue) {
        notepad++ $PROFILE
    } else {
        notepad $PROFILE
    }
}

# Lịch sử lệnh đẹp
function global:hh {
    param([int]$Count = 20, [string]$Filter = "")
    
    Write-Host ""
    Write-Host "  📜 Lịch sử lệnh gần đây:" -ForegroundColor $Script:Theme.Primary
    Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
    
    $history = Get-History | Select-Object -Last $Count
    if ($Filter) {
        $history = $history | Where-Object { $_.CommandLine -like "*$Filter*" }
    }
    
    $history | ForEach-Object {
        Write-Host "  " -NoNewline
        Write-Host ("{0,4}" -f $_.Id) -NoNewline -ForegroundColor DarkGray
        Write-Host " │ " -NoNewline -ForegroundColor DarkGray
        Write-Host $_.CommandLine -ForegroundColor Cyan
    }
    Write-Host ""
}

# Touch (tạo file trống)
function global:touch {
    param([Parameter(Mandatory)][string]$Name)
    if (Test-Path $Name) {
        (Get-Item $Name).LastWriteTime = Get-Date
        Write-Host "  📄 Đã cập nhật: $Name" -ForegroundColor $Script:Theme.Success
    } else {
        New-Item -ItemType File -Name $Name | Out-Null
        Write-Host "  📄 Đã tạo: $Name" -ForegroundColor $Script:Theme.Success
    }
}

# Đếm file trong thư mục
function global:count {
    param([string]$Path = ".")
    $files = (Get-ChildItem $Path -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    $dirs = (Get-ChildItem $Path -Directory -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    
    Write-Host ""
    Write-Host "  📊 Thống kê: $Path" -ForegroundColor $Script:Theme.Primary
    Write-Host "  ─────────────────────" -ForegroundColor DarkGray
    Write-Host "  📁 Thư mục : $dirs" -ForegroundColor Cyan
    Write-Host "  📄 Files   : $files" -ForegroundColor Green
    Write-Host ""
}

# Hiển thị tree thư mục
function global:tree2 {
    param(
        [string]$Path = ".",
        [int]$Depth = 2
    )
    
    function Show-Tree {
        param([string]$Dir, [int]$Level, [int]$MaxLevel, [string]$Prefix = "")
        
        if ($Level -ge $MaxLevel) { return }
        
        $items = Get-ChildItem $Dir -ErrorAction SilentlyContinue | Sort-Object { -not $_.PSIsContainer }, Name
        $count = $items.Count
        $index = 0
        
        foreach ($item in $items) {
            $index++
            $isLast = $index -eq $count
            $connector = if ($isLast) { "└── " } else { "├── " }
            $icon = if ($item.PSIsContainer) { "📁" } else { "📄" }
            
            Write-Host "$Prefix$connector$icon " -NoNewline -ForegroundColor DarkGray
            $color = if ($item.PSIsContainer) { "Cyan" } else { "White" }
            Write-Host $item.Name -ForegroundColor $color
            
            if ($item.PSIsContainer) {
                $newPrefix = $Prefix + $(if ($isLast) { "    " } else { "│   " })
                Show-Tree -Dir $item.FullName -Level ($Level + 1) -MaxLevel $MaxLevel -Prefix $newPrefix
            }
        }
    }
    
    Write-Host ""
    Write-Host "📂 $(Resolve-Path $Path)" -ForegroundColor $Script:Theme.Primary
    Show-Tree -Dir $Path -Level 0 -MaxLevel $Depth
    Write-Host ""
}


#region ═══════════════════════════════════════════════════════════════════════════
#        🎨 UI & UX HELPERS (FRAMEWORK)
#endregion ════════════════════════════════════════════════════════════════════════

function global:Show-Header {
    param([string]$Title, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host "  ╭──────────────────────────────────────────────────╮" -ForegroundColor $Color
    Write-Host "  │ " -NoNewline -ForegroundColor $Color
    Write-Host ("{0,-48}" -f $Title) -NoNewline -ForegroundColor "White"
    Write-Host " │" -ForegroundColor $Color
    Write-Host "  ╰──────────────────────────────────────────────────╯" -ForegroundColor $Color
}

function global:Show-Row {
    param([string]$Label, [string]$Value, [string]$Icon="🔹")
    Write-Host "   $Icon " -NoNewline 
    Write-Host ("{0,-15}" -f $Label) -NoNewline -ForegroundColor "DarkGray"
    Write-Host " : " -NoNewline -ForegroundColor "DarkGray"
    Write-Host $Value -ForegroundColor "White"
}

#region ═══════════════════════════════════════════════════════════════════════════
#region ═══════════════════════════════════════════════════════════════════════════
#        ⌨️ TUI ALIAS MANAGER (Interactive)
#endregion ════════════════════════════════════════════════════════════════════════

function global:als {
    <#
    .SYNOPSIS
        Interactive Alias Manager với TUI
    #>
    param(
        [ValidateSet("", "tui", "list", "add", "del", "edit", "export")]
        [string]$Action = "tui",
        [string]$Name,
        [string]$Value
    )
    
    $profilePath = $PROFILE
    $markerStart = "#region CUSTOM_USER_ALIASES"
    $markerEnd = "#endregion CUSTOM_USER_ALIASES"
    
    function Get-UserAliases {
        $aliases = @()
        
        # Get from profile file
        if (Test-Path $profilePath) {
            $content = Get-Content $profilePath -Raw
            $matches = [regex]::Matches($content, "Set-Alias\s+-Name\s+(\w+)\s+-Value\s+['\`"](.+?)['\`"]")
            foreach ($m in $matches) {
                $aliases += [PSCustomObject]@{
                    Name = $m.Groups[1].Value
                    Command = $m.Groups[2].Value
                    Type = "📌 Persistent"
                    Source = "Profile"
                }
            }
        }
        
        # Get current session aliases (not system)
        Get-Alias | Where-Object { $_.Options -notmatch "ReadOnly" -and $_.Source -eq "" } | ForEach-Object {
            if (-not ($aliases | Where-Object { $_.Name -eq $_.Name })) {
                $aliases += [PSCustomObject]@{
                    Name = $_.Name
                    Command = $_.Definition
                    Type = "⚡ Session"
                    Source = "Session"
                }
            }
        }
        
        return $aliases | Sort-Object Name
    }
    
    function Save-Alias {
        param($AliasName, $AliasValue)
        
        # Add to current session
        Set-Alias -Name $AliasName -Value $AliasValue -Scope Global -Force
        
        # Add to profile
        $content = Get-Content $profilePath
        $newLine = "Set-Alias -Name $AliasName -Value '$AliasValue' -Scope Global -Force"
        
        # Remove old definition if exists
        $content = $content | Where-Object { $_ -notmatch "Set-Alias -Name $AliasName " }
        
        # Insert into CUSTOM_USER_ALIASES region
        $newContent = @()
        $inserted = $false
        foreach ($line in $content) {
            $newContent += $line
            if ($line.Trim() -eq $markerStart -and -not $inserted) {
                $newContent += $newLine
                $inserted = $true
            }
        }
        
        if (-not $inserted) {
            $newContent += "`n$markerStart"
            $newContent += $newLine
            $newContent += $markerEnd
        }
        
        $newContent | Set-Content $profilePath
    }
    
    function Remove-CustomAlias {
        param($AliasName)
        
        # Remove from session
        Remove-Item Alias:$AliasName -ErrorAction SilentlyContinue
        
        # Remove from profile
        $content = Get-Content $profilePath
        $newContent = $content | Where-Object { $_ -notmatch "Set-Alias -Name $AliasName " }
        $newContent | Set-Content $profilePath
    }
    
    function Show-AliasTUI {
        $selectedIndex = 0
        $filterText = ""
        
        [Console]::CursorVisible = $false
        # Enable Mouse Tracking
        Write-Host "$([char]27)[?1000h" -NoNewline
        
        try {
            while ($true) {
                Clear-Host
                
                $aliases = Get-UserAliases
                if ($filterText) {
                    $aliases = $aliases | Where-Object { $_.Name -like "*$filterText*" -or $_.Command -like "*$filterText*" }
                }
                
                # Header
                Write-Host ""
                Write-Host "  ╭─────────────────────────────────────────────────────────────╮" -ForegroundColor Yellow
                Write-Host "  │          ⌨️  ALIAS MANAGER (TUI)                             │" -ForegroundColor Yellow
                Write-Host "  │     Create shortcuts for your favorite commands             │" -ForegroundColor DarkGray
                Write-Host "  ╰─────────────────────────────────────────────────────────────╯" -ForegroundColor Yellow
                
                # Filter bar
                Write-Host ""
                Write-Host "  🔍 Filter: " -NoNewline -ForegroundColor DarkGray
                Write-Host $(if ($filterText) { $filterText } else { "(type to filter)" }) -ForegroundColor Yellow
                Write-Host ""
                
                # Table header
                Write-Host "  ┌────────────────┬────────────────────────────────┬────────────┐" -ForegroundColor DarkGray
                Write-Host "  │ ALIAS          │ COMMAND                        │ TYPE       │" -ForegroundColor Cyan
                Write-Host "  ├────────────────┼────────────────────────────────┼────────────┤" -ForegroundColor DarkGray
                
                # Display aliases
                $displayCount = [math]::Min($aliases.Count, 12)
                $startIdx = [math]::Max(0, $selectedIndex - 6)
                $visibleItems = @()
                
                for ($i = $startIdx; $i -lt [math]::Min($startIdx + $displayCount, $aliases.Count); $i++) {
                    $item = $aliases[$i]
                    $visibleItems += $i
                    $isSelected = ($i -eq $selectedIndex)
                    
                    $prefix = if ($isSelected) { "▶" } else { " " }
                    $fg = if ($isSelected) { "Black" } else { "White" }
                    $bg = if ($isSelected) { "Yellow" } else { $Host.UI.RawUI.BackgroundColor }
                    
                    $displayName = if ($item.Name.Length -gt 13) { $item.Name.Substring(0,10) + "..." } else { $item.Name }
                    $displayCmd = if ($item.Command.Length -gt 29) { $item.Command.Substring(0,26) + "..." } else { $item.Command }
                    
                    Write-Host "  │" -NoNewline -ForegroundColor DarkGray
                    Write-Host "$prefix" -NoNewline -ForegroundColor $(if ($isSelected) { "Cyan" } else { "DarkGray" })
                    Write-Host ("{0,-14}" -f $displayName) -NoNewline -ForegroundColor $fg -BackgroundColor $bg
                    Write-Host "│" -NoNewline -ForegroundColor DarkGray
                    Write-Host ("{0,-32}" -f $displayCmd) -NoNewline -ForegroundColor $(if ($isSelected) { "Black" } else { "Gray" }) -BackgroundColor $bg
                    Write-Host "│" -NoNewline -ForegroundColor DarkGray
                    Write-Host ("{0,-12}" -f $item.Type) -NoNewline -ForegroundColor $(if ($item.Source -eq "Profile") { "Green" } else { "Cyan" })
                    Write-Host "│" -ForegroundColor DarkGray
                }
                
                if ($aliases.Count -eq 0) {
                    Write-Host "  │            No aliases found. Press 'A' to add!             │" -ForegroundColor DarkGray
                }
                
                Write-Host "  └────────────────┴────────────────────────────────┴────────────┘" -ForegroundColor DarkGray
                Write-Host "   Total: $($aliases.Count) aliases" -ForegroundColor DarkGray
                
                # Controls
                Write-Host ""
                Write-Host "  ╭──────────────────────── CONTROLS ─────────────────────────╮" -ForegroundColor DarkGray
                Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
                Write-Host "↑↓" -NoNewline -ForegroundColor Yellow
                Write-Host ":Move " -NoNewline -ForegroundColor DarkGray
                Write-Host "/" -NoNewline -ForegroundColor Yellow
                Write-Host ":Filter " -NoNewline -ForegroundColor DarkGray
                Write-Host "A" -NoNewline -ForegroundColor Green
                Write-Host ":Add " -NoNewline -ForegroundColor DarkGray
                Write-Host "E" -NoNewline -ForegroundColor Cyan
                Write-Host ":Edit " -NoNewline -ForegroundColor DarkGray
                Write-Host "D" -NoNewline -ForegroundColor Red
                Write-Host ":Delete " -NoNewline -ForegroundColor DarkGray
                Write-Host "Enter" -NoNewline -ForegroundColor Yellow
                Write-Host ":Test " -NoNewline -ForegroundColor DarkGray
                Write-Host "Q" -NoNewline -ForegroundColor Red
                Write-Host ":Quit" -NoNewline -ForegroundColor DarkGray
                Write-Host "  │" -ForegroundColor DarkGray
                Write-Host "  ╰───────────────────────────────────────────────────────────╯" -ForegroundColor DarkGray
                
                # Key handling
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                
                # Handle Escape Sequence (Mouse)
                if ($key.VirtualKeyCode -eq 27 -and $Host.UI.RawUI.KeyAvailable) {
                    $seq = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    if ($seq.Character -eq '[') {
                        $buf = ""
                        while ($Host.UI.RawUI.KeyAvailable) {
                            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            $buf += $k.Character
                            if ($k.Character -match '[M~a-zA-Z]') { break }
                        }
                        
                        # Parse Legacy Mouse: M<btn><x><y>
                        if ($buf.StartsWith("M") -and $buf.Length -ge 4) {
                            $mouseY = [int][char]$buf[3] - 32
                            $bufferY = $mouseY - 1
                            
                            # Row 11 is where items start approx:
                            # 0:Empty, 1-4:Head, 5:Empty, 6:Filter, 7:Empty, 8-10:TableHead, 11:FirstItem
                            
                            if ($bufferY -ge 11 -and $bufferY -lt (11 + $visibleItems.Count)) {
                                $clickedRowIndex = $bufferY - 11
                                if ($clickedRowIndex -lt $visibleItems.Count) {
                                    $selectedIndex = $visibleItems[$clickedRowIndex]
                                }
                            }
                        }
                    }
                    continue
                }
                
                switch ($key.VirtualKeyCode) {
                    38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }
                    40 { if ($selectedIndex -lt $aliases.Count - 1) { $selectedIndex++ } }
                    
                    # Filter (/)
                    191 {
                        Write-Host ""
                        Write-Host "  🔍 Filter: " -NoNewline -ForegroundColor Cyan
                        $filterText = Read-Host
                        $selectedIndex = 0
                    }
                    
                    # Add (A)
                    65 {
                        Write-Host ""
                        Write-Host "  ➕ ADD NEW ALIAS" -ForegroundColor Green
                        Write-Host "  ──────────────────" -ForegroundColor DarkGray
                        $newName = Read-Host "     Alias name"
                        $newCmd = Read-Host "     Command"
                        
                        if ($newName -and $newCmd) {
                            Save-Alias -AliasName $newName -AliasValue $newCmd
                            Write-Host "  ✅ Created: $newName → $newCmd" -ForegroundColor Green
                            Start-Sleep -Seconds 1
                        }
                    }
                    
                    # Edit (E)
                    69 {
                        if ($aliases -and $selectedIndex -lt $aliases.Count) {
                            $item = $aliases[$selectedIndex]
                            Write-Host ""
                            Write-Host "  ✏️  EDIT: $($item.Name)" -ForegroundColor Cyan
                            Write-Host "     Current: $($item.Command)" -ForegroundColor DarkGray
                            $newCmd = Read-Host "     New command"
                            
                            if ($newCmd) {
                                Save-Alias -AliasName $item.Name -AliasValue $newCmd
                                Write-Host "  ✅ Updated!" -ForegroundColor Green
                                Start-Sleep -Seconds 1
                            }
                        }
                    }
                    
                    # Delete (D)
                    68 {
                        if ($aliases -and $selectedIndex -lt $aliases.Count) {
                            $item = $aliases[$selectedIndex]
                            Write-Host ""
                            Write-Host "  🗑️  DELETE '$($item.Name)'? [Y/N]" -ForegroundColor Red
                            $confirm = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            
                            if ($confirm.Character -eq 'y') {
                                Remove-CustomAlias -AliasName $item.Name
                                Write-Host "  ✅ Deleted!" -ForegroundColor Green
                                $selectedIndex = [math]::Max(0, $selectedIndex - 1)
                                Start-Sleep -Seconds 1
                            }
                        }
                    }
                    
                    # Test (Enter)
                    13 {
                        if ($aliases -and $selectedIndex -lt $aliases.Count) {
                            $item = $aliases[$selectedIndex]
                            Write-Host ""
                            Write-Host "  🧪 Testing: $($item.Name)" -ForegroundColor Cyan
                            Write-Host "  Command: $($item.Command)" -ForegroundColor DarkGray
                            Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
                            try {
                                Invoke-Expression $item.Command
                            } catch {
                                Write-Host "  ❌ Error: $_" -ForegroundColor Red
                            }
                            Write-Host ""
                            Write-Host "  Press any key..." -ForegroundColor DarkGray
                            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        }
                    }
                    
                    # Quit
                    { $_ -in 81, 27 } { return }
                }
            }
        } finally {
            # Disable Mouse Tracking & Restore Cursor
            Write-Host "$([char]27)[?1000l" -NoNewline
            [Console]::CursorVisible = $true
        }
    }
    
    # === DISPATCH ===
    switch ($Action) {
        "tui" { Show-AliasTUI }
        "list" { Get-UserAliases | Show-Table -Columns @("Name", "Command", "Type") -Title "Aliases" }
        "add" { if ($Name -and $Value) { Save-Alias -AliasName $Name -AliasValue $Value; Write-Host "  ✅ Added: $Name → $Value" -ForegroundColor Green } }
        "del" { if ($Name) { Remove-CustomAlias -AliasName $Name; Write-Host "  ✅ Deleted: $Name" -ForegroundColor Green } }
        default { Show-AliasTUI }
    }
}

#region ═══════════════════════════════════════════════════════════════════════════
#        📍 BOOKMARK MANAGER (Directory Favorites)
#endregion ════════════════════════════════════════════════════════════════════════

$Script:BookmarkFile = Join-Path $HOME ".ps_bookmarks.json"

function global:bm {
    <#
    .SYNOPSIS
        Quản lý thư mục yêu thích
    .DESCRIPTION
        bm add [name]  : Bookmark thư mục hiện tại
        bm go [name]   : Chuyển đến bookmark
        bm del [name]  : Xóa bookmark
        bm list        : Xem danh sách
        bm (no args)   : TUI Interactive
    #>
    param(
        [ValidateSet("", "add", "go", "del", "list")]
        [string]$Action = "",
        [string]$Name
    )
    
    # Load bookmarks
    function Get-Bookmarks {
        if (Test-Path $Script:BookmarkFile) {
            return Get-Content $Script:BookmarkFile | ConvertFrom-Json
        }
        return @()
    }
    
    function Save-Bookmarks {
        param($Bookmarks)
        $Bookmarks | ConvertTo-Json | Set-Content $Script:BookmarkFile
    }
    
    function Show-BookmarkTUI {
        $bookmarks = @(Get-Bookmarks)
        $selectedIndex = 0
        
        [Console]::CursorVisible = $false
        # Enable Mouse Tracking
        Write-Host "$([char]27)[?1000h" -NoNewline
        
        try {
            while ($true) {
                Clear-Host
                Write-Host ""
                Write-Host "  ╭────────────────────────────────────────────╮" -ForegroundColor Magenta
                Write-Host "  │       📍 BOOKMARK MANAGER                  │" -ForegroundColor Magenta
                Write-Host "  ╰────────────────────────────────────────────╯" -ForegroundColor Magenta
                Write-Host ""
                
                if ($bookmarks.Count -eq 0) {
                    Write-Host "  No bookmarks yet. Press 'A' to add current directory!" -ForegroundColor DarkGray
                } else {
                    for ($i = 0; $i -lt $bookmarks.Count; $i++) {
                        $bm = $bookmarks[$i]
                        $isSelected = ($i -eq $selectedIndex)
                        $prefix = if ($isSelected) { " ▶ " } else { "   " }
                        $fg = if ($isSelected) { "Black" } else { "White" }
                        $bg = if ($isSelected) { "Magenta" } else { $Host.UI.RawUI.BackgroundColor }
                        $exists = Test-Path $bm.Path
                        $icon = if ($exists) { "📂" } else { "❌" }
                        
                        Write-Host "$prefix$icon " -NoNewline
                        Write-Host ("{0,-15}" -f $bm.Name) -NoNewline -ForegroundColor $fg -BackgroundColor $bg
                        Write-Host " → $($bm.Path)" -ForegroundColor $(if ($exists) { "Cyan" } else { "DarkGray" })
                    }
                }
                
                Write-Host ""
                Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
                Write-Host "  ↑↓:Move  Enter:Go  A:Add  D:Delete  Q:Quit" -ForegroundColor DarkGray
                
                $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                
                # Handle Escape Sequence (Mouse)
                if ($key.VirtualKeyCode -eq 27 -and $Host.UI.RawUI.KeyAvailable) {
                    $seq = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    if ($seq.Character -eq '[') {
                        $buf = ""
                        while ($Host.UI.RawUI.KeyAvailable) {
                            $k = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            $buf += $k.Character
                            if ($k.Character -match '[M~a-zA-Z]') { break }
                        }
                        
                        # Parse Legacy Mouse: M<btn><x><y>
                        if ($buf.StartsWith("M") -and $buf.Length -ge 4) {
                            $mouseY = [int][char]$buf[3] - 32
                            $bufferY = $mouseY - 1
                            
                            # Row 5 is where items start (0-based):
                            # 0:Empty, 1-3:Head, 4:Empty, 5:FirstItem
                            
                            if ($bufferY -ge 5 -and $bufferY -lt (5 + $bookmarks.Count)) {
                                $selectedIndex = $bufferY - 5
                            }
                        }
                    }
                    continue
                }
                
                switch ($key.VirtualKeyCode) {
                    38 { if ($selectedIndex -gt 0) { $selectedIndex-- } }
                    40 { if ($selectedIndex -lt $bookmarks.Count - 1) { $selectedIndex++ } }
                    
                    13 { # Enter
                        if ($bookmarks.Count -gt 0 -and $bookmarks[$selectedIndex].Path) {
                            $path = $bookmarks[$selectedIndex].Path
                            if (Test-Path $path) {
                                Set-Location $path
                                Write-Host "  📍 → $path" -ForegroundColor Green
                                return
                            } else {
                                Write-Host "  ❌ Path no longer exists!" -ForegroundColor Red
                                Start-Sleep -Seconds 1
                            }
                        }
                    }
                    
                    65 { # A - Add
                        Write-Host ""
                        $newName = Read-Host "  Name for bookmark"
                        if ($newName) {
                            $bookmarks += [PSCustomObject]@{ Name = $newName; Path = (Get-Location).Path }
                            Save-Bookmarks $bookmarks
                            Write-Host "  ✅ Bookmarked!" -ForegroundColor Green
                            Start-Sleep -Seconds 1
                        }
                    }
                    
                    68 { # D - Delete
                        if ($bookmarks.Count -gt 0) {
                            $bookmarks = @($bookmarks | Where-Object { $_ -ne $bookmarks[$selectedIndex] })
                            Save-Bookmarks $bookmarks
                            $selectedIndex = [math]::Max(0, $selectedIndex - 1)
                        }
                    }
                    
                    { $_ -in 81, 27 } { return }
                }
            }
        } finally {
            # Disable Mouse Tracking & Restore Cursor
            Write-Host "$([char]27)[?1000l" -NoNewline
            [Console]::CursorVisible = $true
        }
    }
    
    # Dispatch
    switch ($Action) {
        "" { Show-BookmarkTUI }
        "add" {
            $bookmarks = @(Get-Bookmarks)
            if (-not $Name) { $Name = Split-Path (Get-Location) -Leaf }
            $bookmarks += [PSCustomObject]@{ Name = $Name; Path = (Get-Location).Path }
            Save-Bookmarks $bookmarks
            Write-Host "  ✅ Bookmarked: $Name → $((Get-Location).Path)" -ForegroundColor Green
        }
        "go" {
            $bookmarks = Get-Bookmarks
            $target = $bookmarks | Where-Object { $_.Name -eq $Name }
            if ($target) {
                Set-Location $target.Path
                Write-Host "  📍 → $($target.Path)" -ForegroundColor Cyan
            } else {
                Write-Host "  ❌ Bookmark '$Name' not found" -ForegroundColor Red
            }
        }
        "del" {
            $bookmarks = @(Get-Bookmarks)
            $bookmarks = @($bookmarks | Where-Object { $_.Name -ne $Name })
            Save-Bookmarks $bookmarks
            Write-Host "  🗑️  Deleted: $Name" -ForegroundColor Yellow
        }
        "list" {
            Write-Host ""
            Write-Host "  📍 BOOKMARKS" -ForegroundColor Magenta
            Write-Host "  ─────────────" -ForegroundColor DarkGray
            $bookmarks = Get-Bookmarks
            foreach ($bm in $bookmarks) {
                $icon = if (Test-Path $bm.Path) { "✅" } else { "❌" }
                Write-Host "  $icon $($bm.Name)" -NoNewline -ForegroundColor Yellow
                Write-Host " → $($bm.Path)" -ForegroundColor Cyan
            }
            Write-Host ""
        }
    }
}

# Trình chỉnh sửa văn bản thông minh (Smart Editor)
function global:nano {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        Write-Host "  ⚠️  Cách dùng: nano <tên_file>" -ForegroundColor Yellow
        return
    }

    # 1. Ưu tiên các editor CLI xịn nếu đã cài (micro là best choice trên Win)
    $editors = @("micro", "nano", "vim", "nvim")
    foreach ($cmd in $editors) {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            & $cmd $Path
            return
        }
    }

    # 2. Fallback về Notepad nếu không có CLI editor
    $resolved = $Path
    if (-not (Test-Path $Path)) {
        # File chưa tồn tại -> Tạo file rỗng để Notepad không báo lỗi
        try {
            New-Item -Path $Path -ItemType File -Force -ErrorAction Stop | Out-Null
            Write-Host "  📄 Đã tạo file mới: $Path" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Không thể tạo file: $_" -ForegroundColor Red
            return
        }
    }
    $resolved = (Resolve-Path $Path).Path
    
    Write-Host "  📝 Đang mở Notepad..." -ForegroundColor Cyan
    Write-Host "     (Mẹo: Cài 'micro' bằng lệnh 'winget install micro' để có giao diện chuẩn Linux)" -ForegroundColor DarkGray
    Start-Process notepad $resolved
}

# 💎 Danh sách tính năng đẹp (Features Distribution Table)
function global:features {
    Clear-Host
    
    # --- Config ---
    $i = @{
        Left  = [char]0xe0b6; Right = [char]0xe0b4
        Sep   = "│"
        Nav   = "🚀"; File  = "📦"; Search= "🔍"; Sys   = "💻"
        Arrow = "➜"
    }
    
    # --- Data ---
    $cats = @(
        @{
            Name  = "NAVIGATION"
            Color = "Magenta"
            Icon  = $i.Nav
            Items = @(
                @{ Cmd="des";         Desc="Về Desktop siêu tốc" }
                @{ Cmd="cdd";         Desc="Alias của cd (hỗ trợ lịch sử)" }
                @{ Cmd="mkcd <name>"; Desc="Tạo & vào thư mục ngay lập tức" }
                @{ Cmd="..n";         Desc="Lên n cấp (vd: ..2, ..3)" }
                @{ Cmd="-";           Desc="Quay lại thư mục trước" }
            )
        },
            @{
            Name  = "FILE OPS"
            Color = "Green"
            Icon  = $i.File
            Items = @(
                @{ Cmd="mkfile <files>"; Desc="Tạo nhiều file nhanh chóng" }
                @{ Cmd="nano <file>"; Desc="Sửa file (Smart Editor)" }
                @{ Cmd="antigravity"; Desc="Copy kho 'SuperSkill' về đây" }
                @{ Cmd="open .";      Desc="Mở Explorer tại thư mục này" }
                @{ Cmd="del <path>";  Desc="Xóa an toàn (Hỏi trước khi xóa)" }
            )
        },
        @{
            Name  = "SEARCH & ANA"
            Color = "Yellow"
            Icon  = $i.Search
            Items = @(
                @{ Cmd="ff <name>";   Desc="Tìm file theo tên cực nhanh" }
                @{ Cmd="ftext <txt>"; Desc="Tìm nội dung bên trong file" }
                @{ Cmd="sizesort";    Desc="Phân tích dung lượng thư mục đẹp" }
            )
        },
        @{
            Name  = "SYSTEM"
            Color = "Cyan"
            Icon  = $i.Sys
            Items = @(
                @{ Cmd="sysinfo";     Desc="Xem thông tin hệ thống chi tiết" }
                @{ Cmd="features";    Desc="Xem bảng này" }
            )
        }
    )

    # --- Render ---
    Write-Host "`n"
    Write-Host "  ╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║             💎 ULTIMATE FEATURES MATRIX                ║" -ForegroundColor Cyan
    Write-Host "  ╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    foreach ($cat in $cats) {
        # Render Header Pill
        Write-Host "  " -NoNewline
        Write-Host $i.Left -NoNewline -ForegroundColor $cat.Color
        Write-Host " $($cat.Icon) $($cat.Name) " -NoNewline -ForegroundColor Black -BackgroundColor $cat.Color
        Write-Host $i.Right -ForegroundColor $cat.Color
        
        # Render Items Table
        Write-Host "  ┌──────────────────────┬─────────────────────────────────┐" -ForegroundColor DarkGray
        
        foreach ($item in $cat.Items) {
            Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
            Write-Host $item.Cmd.PadRight(20) -NoNewline -ForegroundColor White
            Write-Host " │ " -NoNewline -ForegroundColor DarkGray
            Write-Host $item.Desc.PadRight(31) -NoNewline -ForegroundColor $cat.Color
            Write-Host " │" -ForegroundColor DarkGray
        }
        
        Write-Host "  └──────────────────────┴─────────────────────────────────┘" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    Write-Host "  💡 Tip: Nhấn Tab để tự động hoàn thành lệnh." -ForegroundColor DarkGray
    Write-Host "`n"
}

# Quick jump alias
function global:j { bm go $args[0] }

#region ═══════════════════════════════════════════════════════════════════════════
#        🐳 DOCKER SHORTCUTS (Nếu có Docker)
#endregion ════════════════════════════════════════════════════════════════════════

if (Get-Command docker -ErrorAction SilentlyContinue) {
    
    function global:dps { docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" }
    function global:dpsa { docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" }
    function global:dimg { docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" }
    function global:dlog { param($Name) docker logs -f $Name }
    function global:dsh { param($Name) docker exec -it $Name /bin/sh }
    function global:dbash { param($Name) docker exec -it $Name /bin/bash }
    function global:dstop { docker stop $(docker ps -q) }
    function global:dclean { docker system prune -af }
    
    # Interactive Docker TUI
    function global:dk {
        Write-Host ""
        Write-Host "  🐳 DOCKER QUICK COMMANDS" -ForegroundColor Cyan
        Write-Host "  ────────────────────────" -ForegroundColor DarkGray
        Write-Host "  dps     : Running containers"
        Write-Host "  dpsa    : All containers"
        Write-Host "  dimg    : Images"
        Write-Host "  dlog    : Follow logs"
        Write-Host "  dsh/dbash : Shell into container"
        Write-Host "  dstop   : Stop all"
        Write-Host "  dclean  : Prune system"
        Write-Host ""
    }
}

# Windows Apps & Default Aliases
Set-Alias winget "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_1.27.440.0_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue

# Navigation functions thay vì alias
function global:.. { Set-Location .. }
function global:... { Set-Location ../.. }
function global:.... { Set-Location ../../.. }
function global:home { Set-Location $HOME }
function global:desk { Set-Location "$HOME\Desktop" }
function global:docs { Set-Location "$HOME\Documents" }
function global:dl { Set-Location "$HOME\Downloads" }

# Utils
Set-Alias ll "Get-ChildItem"
function global:la { Get-ChildItem -Force }
Set-Alias c "Clear-Host"
Set-Alias h "hh"
Set-Alias ep "editprofile"
Set-Alias which "Get-Command"
Set-Alias grep "Select-String"

# Git shortcuts (nếu có git)
if (Get-Command git -ErrorAction SilentlyContinue) {
    function global:gs { git status }
    function global:ga { git add $args }
    function global:gaa { git add --all }
    function global:gc { git commit -m $args }
    function global:gp { git push }
    function global:gl { git pull }
    function global:glog { git log --oneline --graph -20 }
    function global:gd { git diff $args }
    function global:gb { git branch $args }
    function global:gco { git checkout $args }
}


#region ═══════════════════════════════════════════════════════════════════════════
#        🚀 BANNER KHỞI ĐỘNG CŨ (Sẽ bị Override bên dưới)
#endregion ════════════════════════════════════════════════════════════════════════

# ... (Hàm cũ đã bị ghi đè bởi hàm Show-StartupBanner mới bên dưới) ...
# Để giữ tương thích, ta sẽ không xóa đoạn này nhưng nó sẽ không chạy
# vì hàm mới bên dưới sẽ định nghĩa lại.

# Helper function for Format-Size (used in multiple places)
function global:Format-Size {
    param([int64]$Bytes)
    switch ($Bytes) {
        { $_ -ge 1TB } { return "{0:N2} TB" -f ($_ / 1TB) }
        { $_ -ge 1GB } { return "{0:N2} GB" -f ($_ / 1GB) }
        { $_ -ge 1MB } { return "{0:N2} MB" -f ($_ / 1MB) }
        { $_ -ge 1KB } { return "{0:N2} KB" -f ($_ / 1KB) }
        default { return "$_ B" }
    }
}

#region ═══════════════════════════════════════════════════════════════════════════
#        🎁 NEW FEATURES (UTILITIES PACK)
#endregion ════════════════════════════════════════════════════════════════════════

# 1. 🌦️ Weather (Standard UI)
function global:weather {
    param([string]$City)
    $url = "wttr.in"
    if ($City) { $url += "/$City" }
    try {
        $request = [System.Net.WebRequest]::Create($url)
        $request.UserAgent = "curl"
        $response = $request.GetResponse()
        $stream = $response.GetResponseStream()
        $reader = [System.IO.StreamReader]::new($stream)
        $content = $reader.ReadToEnd()
        $reader.Close()
        $response.Close()
        Write-Host $content
    } catch {
        Write-Host "  ❌ Cannot fetch weather data." -ForegroundColor Red
    }
}

# 2. 🌐 NETWORK INFO - Enhanced Version
function global:myip {
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║              🌐 NETWORK INFORMATION                           ║" -ForegroundColor Cyan
    Write-Host "  ╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # === 1. NETWORK ADAPTERS ===
    Write-Host "  ┌─ 🔌 Network Adapters ─────────────────────────────────────────┐" -ForegroundColor Green
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    
    foreach ($adapter in $adapters) {
        $ipv4 = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        $ipv6 = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue | 
                Where-Object { $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1
        
        $statusColor = switch ($adapter.Status) {
            'Up' { 'Green' }
            'Down' { 'Red' }
            default { 'Yellow' }
        }
        
        Write-Host "  │" -ForegroundColor Green
        Write-Host "  │ 📡 " -NoNewline -ForegroundColor Green
        Write-Host $adapter.Name -ForegroundColor White
        Write-Host "  │    Status     : " -NoNewline -ForegroundColor DarkGray
        Write-Host $adapter.Status -ForegroundColor $statusColor
        Write-Host "  │    Link Speed : " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($adapter.LinkSpeed)" -ForegroundColor Cyan
        Write-Host "  │    MAC Address: " -NoNewline -ForegroundColor DarkGray
        Write-Host $adapter.MacAddress -ForegroundColor Yellow
        
        if ($ipv4) {
            Write-Host "  │    IPv4       : " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($ipv4.IPAddress)/$($ipv4.PrefixLength)" -ForegroundColor Green
        }
        
        if ($ipv6) {
            Write-Host "  │    IPv6       : " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($ipv6.IPAddress)" -ForegroundColor Magenta
        }
    }
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    Write-Host ""
    
    # === 2. PUBLIC IP & GEOLOCATION ===
    Write-Host "  ┌─ 🌍 Public IP & Location ─────────────────────────────────────┐" -ForegroundColor Yellow
    
    try {
        # Get public IP info with geolocation
        Write-Host "  │  ⏳ Fetching public IP info..." -ForegroundColor DarkGray
        $ipInfo = Invoke-RestMethod -Uri "http://ip-api.com/json/" -TimeoutSec 5 -ErrorAction Stop
        
        Write-Host "`r  │  " -NoNewline
        Write-Host "🌐 Public IP  : " -NoNewline -ForegroundColor DarkGray
        Write-Host $ipInfo.query -ForegroundColor Yellow
        Write-Host "  │  📍 Location   : " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($ipInfo.city), $($ipInfo.regionName), $($ipInfo.country)" -ForegroundColor Cyan
        Write-Host "  │  🏢 ISP        : " -NoNewline -ForegroundColor DarkGray
        Write-Host $ipInfo.isp -ForegroundColor White
        Write-Host "  │  🏛️  Org        : " -NoNewline -ForegroundColor DarkGray
        Write-Host $ipInfo.org -ForegroundColor White
        Write-Host "  │  🗺️  Coordinates: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$($ipInfo.lat), $($ipInfo.lon)" -ForegroundColor DarkCyan
        Write-Host "  │  🕐 Timezone   : " -NoNewline -ForegroundColor DarkGray
        Write-Host $ipInfo.timezone -ForegroundColor Magenta
        
    } catch {
        Write-Host "`r  │  " -NoNewline
        Write-Host "❌ Could not fetch public IP info" -ForegroundColor Red
        Write-Host "  │     Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    }
    
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    
    # === 3. DNS SERVERS ===
    Write-Host "  ┌─ 🔍 DNS Servers ──────────────────────────────────────────────┐" -ForegroundColor Magenta
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | 
                  Where-Object { $_.ServerAddresses.Count -gt 0 }
    
    foreach ($dns in $dnsServers) {
        if ($dns.InterfaceAlias -notlike "*Loopback*") {
            Write-Host "  │  📡 $($dns.InterfaceAlias)" -ForegroundColor White
            foreach ($server in $dns.ServerAddresses) {
                Write-Host "  │     → $server" -ForegroundColor Cyan
            }
        }
    }
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
    
    # === 4. ACTIVE CONNECTIONS ===
    Write-Host "  ┌─ 🔗 Active Connections (Top 10) ──────────────────────────────┐" -ForegroundColor Blue
    $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | 
                   Select-Object -First 10
    
    if ($connections) {
        Write-Host "  │  Local Address          Remote Address         State      PID" -ForegroundColor DarkGray
        Write-Host "  │  ───────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        foreach ($conn in $connections) {
            $localAddr = "$($conn.LocalAddress):$($conn.LocalPort)"
            $remoteAddr = "$($conn.RemoteAddress):$($conn.RemotePort)"
            Write-Host "  │  " -NoNewline -ForegroundColor Blue
            Write-Host ("{0,-23}" -f $localAddr) -NoNewline -ForegroundColor Cyan
            Write-Host ("{0,-22}" -f $remoteAddr) -NoNewline -ForegroundColor Yellow
            Write-Host ("{0,-10}" -f $conn.State) -NoNewline -ForegroundColor Green
            Write-Host $conn.OwningProcess -ForegroundColor White
        }
    } else {
        Write-Host "  │  No active connections" -ForegroundColor DarkGray
    }
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor Blue
    Write-Host ""
    
    # === 5. NETWORK STATISTICS ===
    Write-Host "  ┌─ 📊 Network Statistics ───────────────────────────────────────┐" -ForegroundColor DarkCyan
    $stats = Get-NetAdapterStatistics | Where-Object { $_.Name -in $adapters.Name }
    
    foreach ($stat in $stats) {
        $receivedGB = [math]::Round($stat.ReceivedBytes / 1GB, 2)
        $sentGB = [math]::Round($stat.SentBytes / 1GB, 2)
        
        Write-Host "  │  📡 $($stat.Name)" -ForegroundColor White
        Write-Host "  │     ↓ Received : " -NoNewline -ForegroundColor DarkGray
        Write-Host "$receivedGB GB" -ForegroundColor Green
        Write-Host "  │     ↑ Sent     : " -NoNewline -ForegroundColor DarkGray
        Write-Host "$sentGB GB" -ForegroundColor Yellow
    }
    Write-Host "  └───────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

# 3. 📦 Smart Extract
function global:extract {
    param([Parameter(Mandatory)]$Path)
    if (-not (Test-Path $Path)) { Write-Host "  ❌ File not found!" -ForegroundColor Red; return }
    $ext = [System.IO.Path]::GetExtension($Path).ToLower()
    Write-Host "  📦 Extracting '$Path'..." -ForegroundColor Cyan
    try {
        switch ($ext) {
            ".zip" { Expand-Archive -Path $Path -DestinationPath . -Force; break }
            ".tar" { tar -xvf $Path; break }
            ".gz"  { tar -xvf $Path; break }
            default { 
                if (Get-Command 7z -ErrorAction SilentlyContinue) { 7z x $Path } 
                else { Write-Host "  ⚠️  Need 7-Zip or WinRAR for '$ext'." -ForegroundColor Yellow }
            }
        }
        Write-Host "  ✅ Done!" -ForegroundColor Green
    } catch { Write-Host "  ❌ Error: $_" -ForegroundColor Red }
}

# ⚡ Copy đa luồng (Robocopy Wrapper)
function global:fastcopy {
    param(
        [Parameter(Mandatory, Position=0)][string]$Source,
        [Parameter(Mandatory, Position=1)][string]$Destination,
        [int]$Threads = 8
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  ❌ Nguồn không tồn tại: $Source" -ForegroundColor Red
        return
    }

    # Tạo thư mục đích nếu chưa có
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    $srcPath = Resolve-Path $Source
    $destPath = Resolve-Path $Destination
    
    Write-Host ""
    Write-Host "  🚀 FAST COPY (Multi-thread: $Threads)" -ForegroundColor Magenta
    Write-Host "  📂 Từ : $srcPath" -ForegroundColor DarkGray
    Write-Host "  📂 Đến: $destPath" -ForegroundColor DarkGray
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray

    # Robocopy flags: /E (đệ quy), /MT (đa luồng), /Z (restartable), /J (unbuffered I/O cho file lớn)
    # /NP (no progress để tránh spam console), /NFL /NDL (bớt log rác)
    $args = @("/E", "/MT:$Threads", "/Z", "/J", "/R:3", "/W:1", "/NP", "/NFL", "/NDL")
    
    # Nếu là file lẻ
    if ((Get-Item $Source).PSIsContainer) {
        robocopy $srcPath $destPath $args
    } else {
        $fileName = Split-Path $srcPath -Leaf
        $dirName = Split-Path $srcPath -Parent
        robocopy $dirName $destPath $fileName $args
    }

    if ($LASTEXITCODE -lt 8) {
        Write-Host ""
        Write-Host "  ✅ Copy hoàn tất!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "  ⚠️  Copy có lỗi (ExitCode: $LASTEXITCODE)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# 4. 🔗 Up? (Check Website)
function global:up {
    param([Parameter(Mandatory)]$Domain)
    if ($Domain -notmatch "^http") { $Domain = "https://$Domain" }
    Write-Host "  🔍 Connecting to $Domain..." -ForegroundColor DarkGray
    try {
        $response = Invoke-WebRequest -Uri $Domain -Method Head -UseBasicParsing -TimeoutSec 5
        Write-Host "  ✅ UP ($($response.StatusCode)) " -NoNewline -ForegroundColor Green
        Write-Host $Domain -ForegroundColor Cyan
    } catch {
        Write-Host "  ❌ DOWN " -NoNewline -ForegroundColor Red
        Write-Host $Domain -ForegroundColor DarkGray
    }
}

# 5. 🔌 Kill Port
function global:killport {
    param([Parameter(Mandatory)][int]$Port)
    $tcp = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if ($tcp) {
        $pidTarget = $tcp.OwningProcess
        $proc = Get-Process -Id $pidTarget -ErrorAction SilentlyContinue
        if ($proc) {
            Stop-Process -Id $pidTarget -Force
            Write-Host "  🔫 Killed $($proc.ProcessName) (PID: $pidTarget) on port $Port" -ForegroundColor Green
        }
    } else { Write-Host "  ⚪ No process on port $Port" -ForegroundColor DarkGray }
}

#region ═══════════════════════════════════════════════════════════════════════════
#        💎 OFFICE PACK & UI UPGRADE (OVERRIDE)
#endregion ════════════════════════════════════════════════════════════════════════

# 6. ✅ Quản lý công việc (Todo)
function global:todo {
    param(
        [string]$Action,
        [string]$Content
    )
    
    $todoFile = Join-Path $HOME ".todo_list.txt"
    if (-not (Test-Path $todoFile)) { New-Item $todoFile -ItemType File -Force | Out-Null }
    
    if ($Action -eq "add") {
        Add-Content -Path $todoFile -Value "☐ $Content"
        Write-Host "  ✅ Đã thêm: $Content" -ForegroundColor Green
    }
    elseif ($Action -eq "done" -and $Content) {
        $todos = @(Get-Content $todoFile -ErrorAction SilentlyContinue)
        if (-not $todos) { $todos = @() }
        $index = [int]$Content - 1
        if ($index -ge 0 -and $index -lt $todos.Count) {
            $todos[$index] = $todos[$index] -replace "☐", "☑" -replace "\[ \]", "[x]"
            $todos | Set-Content $todoFile
            Write-Host "  🎉 Đã hoàn thành task #$($index + 1)!" -ForegroundColor Cyan
        }
    }
    elseif ($Action -eq "clear") {
        Clear-Content $todoFile
        Write-Host "  🧹 Đã xóa danh sách!" -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "  📋 DANH SÁCH CÔNG VIỆC" -ForegroundColor Magenta
        Write-Host "  ──────────────────────" -ForegroundColor DarkGray
        $i = 1
        $todos = Get-Content $todoFile
        if ($todos) {
            foreach ($t in $todos) {
                $color = if ($t -match "☑|\[x\]") { "DarkGray" } else { "White" }
                Write-Host "  $i. $t" -ForegroundColor $color
                $i++
            }
        } else {
            Write-Host "  (Trống) Hãy thêm việc mới: todo add 'Mua cafe'" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "  👉 todo add <text> │ todo done <id> │ todo clear" -ForegroundColor Cyan
        Write-Host ""
    }
}

# 7. 🧮 Máy tính nhanh
function global:calc {
    param([Parameter(Mandatory)][string]$Expression)
    try {
        $result = Invoke-Expression $Expression
        Write-Host ""
        Write-Host "  🧮 $Expression = " -NoNewline -ForegroundColor Cyan
        Write-Host "$result" -ForegroundColor Green -NoNewline
        Write-Host "  (Đã copy)" -ForegroundColor DarkGray
        Set-Clipboard $result
        Write-Host ""
    } catch {
        Write-Host "  ❌ Lỗi tính toán" -ForegroundColor Red
    }
}

# 8. 💡 CheatSheet (Tra cứu nhanh)
function global:cheat {
    Write-Host ""
    Write-Host "  💡 CHEAT SHEET" -ForegroundColor Yellow
    Write-Host "  ──────────────" -ForegroundColor DarkGray
    Write-Host "  🔍 Tìm kiếm" -ForegroundColor Cyan
    Write-Host "     ff <name>           : Tìm file theo tên"
    Write-Host "     ftext <text>        : Tìm nội dung trong file"
    Write-Host "     which <cmd>         : Xem đường dẫn lệnh"
    Write-Host ""
    Write-Host "  🛠️ Tiện ích" -ForegroundColor Cyan
    Write-Host "     weather <city>      : Xem thời tiết"
    Write-Host "     myip                : Xem IP"
    Write-Host "     killport <port>     : Diệt process chiếm port"
    Write-Host "     up <url>            : Kiểm tra web sống/chết"
    Write-Host "     extract <file>      : Giải nén đa năng"
    Write-Host ""
    Write-Host "  📂 Điều hướng" -ForegroundColor Cyan
    Write-Host "     .. / ...            : Lên 1/2 cấp thư mục"
    Write-Host "     tree2               : Xem cây thư mục đẹp"
    Write-Host "     sizesort            : Phân tích dung lượng folder"
    Write-Host ""
    Write-Host "  ⌨️ Khác" -ForegroundColor Cyan
    Write-Host "     calc <1+1>          : Tính toán"
    Write-Host "     todo                : Quản lý task"
    Write-Host "     editprofile (ep)    : Sửa profile"
    Write-Host "     reload              : Nạp lại profile"
    Write-Host ""
}

# 9. ⏱️ Timer (Bấm giờ)
function global:timer {
    param([int]$Seconds = 60)
    $start = Get-Date
    $end = $start.AddSeconds($Seconds)
    try {
        Write-Host ""
        while ((Get-Date) -lt $end) {
            $ts = $end - (Get-Date)
            $str = "{0:mm}:{0:ss}" -f [datetime]$ts.Ticks
            Write-Progress -Activity "⏳ Timer" -Status $str -PercentComplete (100 - ($ts.TotalSeconds / $Seconds * 100))
            Start-Sleep -Milliseconds 100
        }
        Write-Progress -Activity "⏳ Timer" -Completed
        [console]::Beep(1000, 500)
        Write-Host "  ⏰ HẾT GIỜ! ($Seconds s)" -ForegroundColor Red
        Write-Host ""
    } catch { }
}

# 10. 🔐 PassGen (Tạo Password)
function global:passgen {
    param([int]$Length = 16)
    $chars = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*"
    $pass = -join ((1..$Length) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    Write-Host ""
    Write-Host "  🔐 Password ($Length chars): " -NoNewline -ForegroundColor DarkGray
    Write-Host $pass -ForegroundColor Green
    $pass | Set-Clipboard
    Write-Host "  (Đã copy vào clipboard)" -ForegroundColor DarkGray
    Write-Host ""
}

# 11. 🔗 Shorten URL (Is.gd)
function global:short {
    param([Parameter(Mandatory)]$Url)
    try {
        $api = "https://is.gd/create.php?format=simple&url=$Url"
        $short = (Invoke-RestMethod $api).Trim()
        Write-Host ""
        Write-Host "  🔗 Original: $Url" -ForegroundColor DarkGray
        Write-Host "  ✨ Shortened: " -NoNewline -ForegroundColor DarkGray
        Write-Host $short -ForegroundColor Cyan
        $short | Set-Clipboard
        Write-Host "  (Đã copy)" -ForegroundColor DarkGray
        Write-Host ""
    } catch {
        Write-Host "  ❌ Lỗi khi rút gọn link." -ForegroundColor Red
    }
}

# 12. 🔋 Battery Info (Laptop)
function global:battery {
    $bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    if ($bat) {
        $charge = $bat.EstimatedChargeRemaining
        $status = switch ($bat.BatteryStatus) {
            1 { "Discharging" }
            2 { "Charging" }
            3 { "Fully Charged" }
            default { "Unknown" }
        }
        $color = if ($charge -gt 60) { "Green" } elseif ($charge -gt 20) { "Yellow" } else { "Red" }
        Write-Host ""
        Write-Host "  🔋 Battery Status" -ForegroundColor Cyan
        Write-Host "  ─────────────────" -ForegroundColor DarkGray
        Write-Host "  ⚡ Level  : $charge%" -ForegroundColor $color
        Write-Host "  🔌 State  : $status" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  🚫 No battery detected (Desktop?)" -ForegroundColor DarkGray
    }
}

# 13. 🌐 Web Search
function global:web {
    param(
        [Parameter(Position=0)][string]$Service = "google",
        [Parameter(ValueFromRemainingArguments)][string[]]$Query
    )
    $q = ($Query -join " ")
    if (-not $q) { $q = $Service; $Service = "google" } # If only 1 arg, treat as google query
    
    $url = switch ($Service) {
        "gh"    { "https://github.com/search?q=$q" }
        "so"    { "https://stackoverflow.com/search?q=$q" }
        "bing"  { "https://www.bing.com/search?q=$q" }
        "yt"    { "https://www.youtube.com/results?search_query=$q" }
        default { "https://www.google.com/search?q=$q" }
    }
    
    Start-Process $url
    Write-Host "  🌍 Opening $($Service): '$q'..." -ForegroundColor Cyan
}

# 14. 📦 Compress (Smart Zip)
function global:compress {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Destination
    )
    
    if (-not (Test-Path $Path)) { Write-Host "  ❌ Input not found!" -ForegroundColor Red; return }
    
    $name = Split-Path $Path -Leaf
    if (-not $Destination) { $Destination = "$name.zip" }
    
    Write-Host "  📦 Compressing '$Path' to '$Destination'..." -ForegroundColor Cyan
    try {
        Compress-Archive -Path $Path -DestinationPath $Destination -Force
        Write-Host "  ✅ Done!" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
    }
}

# 15. 📄 Make File (Smart Batch Creator)
function global:mkfile {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$FileNames)

    if (-not $FileNames) {
        Write-Host "  ⚠️  Usage: mkfile index.html src/style.css components/Header.jsx ..." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "  📄 SMART FILE CREATOR" -ForegroundColor Cyan
    Write-Host "  ─────────────────────" -ForegroundColor DarkGray
    
    # Optional Base Destination
    Write-Host "  📂 Base Destination (Enter for current): " -NoNewline -ForegroundColor Yellow
    $baseDest = Read-Host
    if ([string]::IsNullOrWhiteSpace($baseDest)) { $baseDest = "." }

    # Create base dir if needed
    if ($baseDest -ne "." -and -not (Test-Path $baseDest)) {
        try {
            New-Item -ItemType Directory -Path $baseDest -Force | Out-Null
            Write-Host "  ✨ Created base dir: $baseDest" -ForegroundColor Cyan
        } catch {
            Write-Host "  ❌ Failed to create base dir!" -ForegroundColor Red
            return
        }
    }

    foreach ($file in $FileNames) {
        try {
            # Resolve full path
            $fullPath = Join-Path $baseDest $file
            $parentDir = Split-Path $fullPath -Parent

            # 1. Recursive Directory Creation
            if ($parentDir -and -not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                Write-Host "  📂 Created dir: $parentDir" -ForegroundColor DarkGray
            }

            # 2. Check Existence & Prompt
            if (Test-Path $fullPath -PathType Leaf) {
                Write-Host "  ⚠️  EXISTS: $file" -NoNewline -ForegroundColor Yellow
                $choice = Read-Host " - Overwrite? (y/n)"
                
                if ($choice -eq 'y') {
                    New-Item -ItemType File -Path $fullPath -Force | Out-Null
                    Write-Host "  ♻️  Overwritten: $file" -ForegroundColor Cyan
                } else {
                    Write-Host "  ⏭️  Skipped: $file" -ForegroundColor DarkGray
                }
            } else {
                # 3. Create New
                New-Item -ItemType File -Path $fullPath -Force | Out-Null
                Write-Host "  ✅ Created: $file" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ❌ Error processing '$file': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# 🔄 CẬP NHẬT BANNER MỚI (RESPONSIVE - KHÔNG VỠ KHUNG)
#region ═══════════════════════════════════════════════════════════════════════════
#        🎯 COMMAND PALETTE (Ctrl+Shift+P style)
#endregion ════════════════════════════════════════════════════════════════════════

function global:cmd {
    $commands = @(
        @{ Name = "📂 Bookmark Manager"; Cmd = "bm" }
        @{ Name = "🌍 Environment Manager"; Cmd = "env" }
        @{ Name = "⌨️  Alias Manager"; Cmd = "als" }
        @{ Name = "📊 Size Sort"; Cmd = "sizesort" }
        @{ Name = "🔍 Find Files"; Cmd = "ff" }
        @{ Name = "💻 System Info"; Cmd = "sysinfo" }
        @{ Name = "📋 Todo List"; Cmd = "todo" }
        @{ Name = "🔌 Listening Ports"; Cmd = "ports" }
        @{ Name = "📈 Top Processes"; Cmd = "top" }
        @{ Name = "🌐 My IP"; Cmd = "myip" }
        @{ Name = "🔋 Battery"; Cmd = "battery" }
        @{ Name = "⏱️  Timer"; Cmd = "timer" }
        @{ Name = "🔐 Password Generator"; Cmd = "passgen" }
        @{ Name = "💡 Cheat Sheet"; Cmd = "cheat" }
        @{ Name = "📚 All Features"; Cmd = "features" }
        @{ Name = "🔄 Reload Profile"; Cmd = "reload" }
        @{ Name = "✏️  Edit Profile"; Cmd = "editprofile" }
    )
    
    $selected = Show-InteractiveMenu -Title "🎯 COMMAND PALETTE" -Options ($commands | ForEach-Object { $_.Name }) -Color "Magenta"
    
    if ($selected) {
        $cmd = ($commands | Where-Object { $_.Name -eq $selected }).Cmd
        if ($cmd) {
            Write-Host ""
            Write-Host "  ▶ Running: $cmd" -ForegroundColor Cyan
            Write-Host ""
            Invoke-Expression $cmd
        }
    }
}

# Hotkey Ctrl+P cho Command Palette
Set-PSReadLineKeyHandler -Chord 'Ctrl+p' -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("cmd")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

function Show-StartupBanner {
    $width = $Host.UI.RawUI.WindowSize.Width
    if ($width -gt 100) { $width = 100 }
    if ($width -lt 60) { $width = 60 }
    
    $innerW = $width - 6
    
    Clear-Host
    Write-Host ""
    
    # Modern compact banner
    $title = "POWERSHELL PRO"
    $subtitle = "Enhanced Terminal Experience"
    
    # Top border
    Write-Host "  ╔$("═" * ($width - 4))╗" -ForegroundColor Cyan
    
    # Title with gradient
    $padT = [math]::Floor(($innerW - $title.Length) / 2)
    Write-Host "  ║$(" " * $padT)" -NoNewline -ForegroundColor Cyan
    
    $gradColors = @("Cyan", "Blue", "Magenta")
    for ($i = 0; $i -lt $title.Length; $i++) {
        $colorIdx = [math]::Floor($i / ($title.Length / $gradColors.Count))
        if ($colorIdx -ge $gradColors.Count) { $colorIdx = $gradColors.Count - 1 }
        Write-Host $title[$i] -NoNewline -ForegroundColor $gradColors[$colorIdx]
    }
    Write-Host "$(" " * ($innerW - $padT - $title.Length))║" -ForegroundColor Cyan
    
    # Subtitle
    $padS = [math]::Floor(($innerW - $subtitle.Length) / 2)
    Write-Host "  ║$(" " * $padS)$subtitle$(" " * ($innerW - $padS - $subtitle.Length))║" -ForegroundColor DarkGray
    
    Write-Host "  ╠$("═" * ($width - 4))╣" -ForegroundColor Cyan
    
    # Info line
    $user = "$env:USERNAME"
    $comp = "$env:COMPUTERNAME"
    $ps = "PS $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $badge = if ($isAdmin) { "👑 ADMIN" } else { "⚡ USER" }
    
    $info = "  ║  $badge  │  👤 $user@$comp  │  💎 $ps"
    $pad = $width - 4 - $info.Length + 5
    Write-Host "$info$(" " * [math]::Max(1, $pad))║" -ForegroundColor Yellow
    
    Write-Host "  ╠$("═" * ($width - 4))╣" -ForegroundColor Cyan
    
    # Quick commands (2 rows)
    $cmds1 = "  ║  🎯 cmd (Ctrl+P) │ 🌍 env │ ⌨️  als │ 📂 bm │ 💡 features │ 🔄 reload"
    $pad1 = $width - 4 - $cmds1.Length + 5
    Write-Host "$cmds1$(" " * [math]::Max(1, $pad1))║" -ForegroundColor Green
    
    $cmds2 = "  ║  📊 sysinfo │ 🧮 calc │ 📋 todo │ 🔐 passgen │ 🌐 myip │ 🔍 ff/ftext"
    $pad2 = $width - 4 - $cmds2.Length + 5
    Write-Host "$cmds2$(" " * [math]::Max(1, $pad2))║" -ForegroundColor DarkCyan
    
    Write-Host "  ╚$("═" * ($width - 4))╝" -ForegroundColor Cyan
    
    # Random tip
    $tips = @(
        "💡 Tip: Gõ 'cmd' hoặc nhấn Ctrl+P để mở Command Palette"
        "💡 Tip: Dùng 'env' để quản lý environment variables với TUI"
        "💡 Tip: Gõ 'features' để xem danh sách đầy đủ các lệnh"
        "💡 Tip: 'als' để quản lý alias, 'bm' để bookmark thư mục"
        "💡 Tip: Click chuột trong TUI menu để chọn nhanh (nếu hỗ trợ)"
        "💡 Tip: 'todo add' để thêm task, 'calc 1+1' để tính toán"
        "💡 Tip: Double-click trong menu để confirm nhanh"
    )
    $tip = $tips | Get-Random
    Write-Host ""
    Write-Host "  $tip" -ForegroundColor DarkGray
    Write-Host ""
}

# 12. 📚 LIST ALL FEATURES (INTERACTIVE TABBED DASHBOARD)
function global:features {
    # 1. Định nghĩa dữ liệu
    $tabs = [ordered]@{
        "📂 CORE" = @{
            Color = "Cyan"
            Items = @(
                @{ C="cmd (Ctrl+P)"; D="Command Palette - Menu lệnh nhanh" },
                @{ C="cd ..."; D="Smart CD (History, Auto-drive)" },
                @{ C="mkcd <dir>"; D="Tạo thư mục & CD vào luôn" },
                @{ C="mkfile"; D="Tạo file + thư mục cha tự động" },
                @{ C="nano"; D="Trình sửa file đơn giản" },
                @{ C="open ."; D="Mở trong File Explorer" },
                @{ C="touch"; D="Tạo file / Cập nhật timestamp" },
                @{ C="del"; D="Xóa an toàn có xác nhận" },
                @{ C="fastcopy"; D="Copy đa luồng (Robocopy wrapper)" },
                @{ C="antigravity"; D="Teleport files (Siêu cấp)" },
                @{ C="compress / extract"; D="Nén & Giải nén đa năng" },
                @{ C="tree2 / sizesort"; D="Xem cây thư mục & Phân tích size" },
                @{ C="count"; D="Đếm số lượng file/folder" }
            )
        }
        "🔍 FIND" = @{
            Color = "Blue"
            Items = @(
                @{ C="ff <name>"; D="Tìm file theo tên" },
                @{ C="ftext <text>"; D="Tìm nội dung trong file" },
                @{ C="grep <regex>"; D="Tìm kiếm Regex (Select-String)" },
                @{ C="which <cmd>"; D="Xem đường dẫn lệnh" },
                @{ C="bm"; D="Quản lý Bookmark (TUI)" },
                @{ C="j <name>"; D="Nhảy nhanh đến Bookmark" },
                @{ C="web <q>"; D="Tìm kiếm Google/Github/StackOverflow" }
            )
        }
        "🧰 SYSTEM" = @{
            Color = "Magenta"
            Items = @(
                @{ C="rings"; D="Kiểm tra cấp độ quyền lực" },
                @{ C="sudo / drop"; D="Admin Mode / User Mode" },
                @{ C="god / ti"; D="SYSTEM Mode / TrustedInstaller" },
                @{ C="sysinfo"; D="Thông tin hệ thống chi tiết" },
                @{ C="top"; D="Xem process ngốn RAM nhất" },
                @{ C="cleantemp"; D="Dọn dẹp rác hệ thống sâu" },
                @{ C="star / unstar"; D="Khóa/Mở khóa cửa sổ (Chống tắt)" },
                @{ C="install / uninstall"; D="Cài đặt/Gỡ bỏ phần mềm (Winget)" },
                @{ C="upgrade"; D="Cập nhật toàn bộ phần mềm" },
                @{ C="reload / editprofile"; D="Nạp lại / Chỉnh sửa Profile" }
            )
        }
        "☢️ NUCLEAR" = @{
            Color = "Red"
            Items = @(
                @{ C="powerup"; D="⚡ Unlock ALL Privileges (Token Overdrive)" },
                @{ C="zkill <pid>"; D="💀 Native API Kill (Bypass)" },
                @{ C="def off/on"; D="🛡️ Tắt/Bật Windows Defender" },
                @{ C="avkill"; D="🦠 Diệt MỌI Antivirus (Kaspersky/ESET...)" },
                @{ C="nuke <name>"; D="💣 Hủy diệt Process & Service" },
                @{ C="ghost"; D="👻 Xóa sạch Event Logs & History" }
            )
        }
        "🌀 HYPER" = @{
            Color = "DarkCyan"
            Items = @(
                @{ C="hyp"; D="Kiểm tra trạng thái Hypervisor / VBS" },
                @{ C="uefi"; D="Đọc thông tin Firmware / Secure Boot" },
                @{ C="vmx <vm> <cmd>"; D="Tiêm code vào VM (PowerShell Direct)" },
                @{ C="dps / dpsa"; D="[Docker] Xem containers" },
                @{ C="dstop / dclean"; D="[Docker] Quản lý containers" }
            )
        }
        "🌐 NET" = @{
            Color = "Green"
            Items = @(
                @{ C="myip"; D="Xem Public IP & Local IP" },
                @{ C="ports"; D="Xem các port đang mở" },
                @{ C="killport <p>"; D="Diệt process đang chiếm port" },
                @{ C="up <url>"; D="Ping kiểm tra web sống/chết" },
                @{ C="weather"; D="Xem dự báo thời tiết" }
            )
        }
        "🛠️ TOOLS" = @{
            Color = "Yellow"
            Items = @(
                @{ C="todo"; D="Quản lý công việc (TUI)" },
                @{ C="env / als"; D="Quản lý Environment / Alias (TUI)" },
                @{ C="calc"; D="Máy tính nhanh" },
                @{ C="passgen"; D="Tạo mật khẩu mạnh" },
                @{ C="timer"; D="Đồng hồ đếm ngược" },
                @{ C="short"; D="Rút gọn link (is.gd)" },
                @{ C="cheat"; D="Cheat Sheet lệnh nhanh" },
                @{ C="clip / paste"; D="Clipboard tools" },
                @{ C="hh / c"; D="Lịch sử lệnh / Xóa màn hình" }
            )
        }
    }

    $tabNames = $tabs.Keys | ForEach-Object { $_ }
    $activeIdx = 0
    
    # Ẩn con trỏ chuột
    [Console]::CursorVisible = $false
    
    try {
        while ($true) {
            Clear-Host
            
            # --- HEADER ---
            Write-Host ""
            Write-Host "  🌟 POWERSHELL PRO FEATURES" -ForegroundColor Cyan
            Write-Host "  Use Left/Right Arrow to switch tabs. Esc/Q to quit." -ForegroundColor DarkGray
            Write-Host ""
            
            # --- TABS BAR ---
            Write-Host "  " -NoNewline
            for ($i = 0; $i -lt $tabNames.Count; $i++) {
                $name = $tabNames[$i]
                $isActive = ($i -eq $activeIdx)
                $tabColor = $tabs[$name].Color
                
                if ($isActive) {
                    Write-Host " " -NoNewline -BackgroundColor $tabColor
                    Write-Host "$name" -NoNewline -ForegroundColor Black -BackgroundColor $tabColor
                    Write-Host " " -NoNewline -BackgroundColor $tabColor
                } else {
                    Write-Host " $name " -NoNewline -ForegroundColor DarkGray
                }
                Write-Host "  " -NoNewline -BackgroundColor Black
            }
            Write-Host "`n"

            # --- CONTENT ---
            $currentTabName = $tabNames[$activeIdx]
            $currentData = $tabs[$currentTabName]
            $items = $currentData.Items
            $themeColor = $currentData.Color
            
            # Border Top
            Write-Host "  $($Script:TUI.BoxChars.TL)$("─"*70)$($Script:TUI.BoxChars.TR)" -ForegroundColor $themeColor
            
            foreach ($item in $items) {
                Write-Host "  $($Script:TUI.BoxChars.V) " -NoNewline -ForegroundColor $themeColor
                Write-Host ("{0,-25}" -f $item.C) -NoNewline -ForegroundColor $themeColor
                Write-Host " : " -NoNewline -ForegroundColor DarkGray
                Write-Host ("{0,-41}" -f $item.D) -NoNewline -ForegroundColor White
                Write-Host "$($Script:TUI.BoxChars.V)" -ForegroundColor $themeColor
            }
            
            # Fill empty lines to maintain height
            for ($k = $items.Count; $k -lt 14; $k++) {
                Write-Host "  $($Script:TUI.BoxChars.V)$(" "*70)$($Script:TUI.BoxChars.V)" -ForegroundColor $themeColor
            }
            
            # Border Bottom
            Write-Host "  $($Script:TUI.BoxChars.BL)$("─"*70)$($Script:TUI.BoxChars.BR)" -ForegroundColor $themeColor
            
            # --- KEY HANDLING ---
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            switch ($key.VirtualKeyCode) {
                37 { # Left
                    $activeIdx--
                    if ($activeIdx -lt 0) { $activeIdx = $tabNames.Count - 1 }
                }
                39 { # Right
                    $activeIdx++
                    if ($activeIdx -ge $tabNames.Count) { $activeIdx = 0 }
                }
                { $_ -in 27, 81 } { # Esc or Q
                    return
                }
            }
        }
    } finally {
        [Console]::CursorVisible = $true
    }
}

#region ═══════════════════════════════════════════════════════════════════════════
#        ⭐ WINDOW PROTECTION (STAR/UNSTAR) - ADVANCED VERSION
#endregion ════════════════════════════════════════════════════════════════════════

# Global state for window protection
$global:WindowProtected = $false
$global:ProtectionRunspace = $null
$global:ProtectionPowerShell = $null

# Add Windows API types for advanced protection
if (-not ([System.Management.Automation.PSTypeName]'WindowProtection').Type) {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    using System.Diagnostics;
    
    public delegate bool ConsoleCtrlDelegate(int ctrlType);
    
    public static class WindowProtection {
        // Console Control Handler
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool SetConsoleCtrlHandler(ConsoleCtrlDelegate handler, bool add);
        
        // Get console window
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        
        // Get system menu
        [DllImport("user32.dll")]
        public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);
        
        // Enable/disable menu item
        [DllImport("user32.dll")]
        public static extern bool EnableMenuItem(IntPtr hMenu, uint uIDEnableItem, uint uEnable);
        
        // Delete menu item
        [DllImport("user32.dll")]
        public static extern bool DeleteMenu(IntPtr hMenu, uint uPosition, uint uFlags);
        
        // Constants
        public const uint SC_CLOSE = 0xF060;
        public const uint MF_BYCOMMAND = 0x00000000;
        public const uint MF_GRAYED = 0x00000001;
        public const uint MF_DISABLED = 0x00000002;
        public const uint MF_ENABLED = 0x00000000;
        
        // Control event types
        public const int CTRL_C_EVENT = 0;
        public const int CTRL_BREAK_EVENT = 1;
        public const int CTRL_CLOSE_EVENT = 2;
        public const int CTRL_LOGOFF_EVENT = 5;
        public const int CTRL_SHUTDOWN_EVENT = 6;
        
        // Static field to keep delegate alive (prevent GC)
        private static ConsoleCtrlDelegate handler;
        
        public static bool EnableProtection(ConsoleCtrlDelegate handlerDelegate) {
            handler = handlerDelegate;
            
            // Disable the close button
            IntPtr consoleWindow = GetConsoleWindow();
            IntPtr systemMenu = GetSystemMenu(consoleWindow, false);
            
            if (systemMenu != IntPtr.Zero) {
                DeleteMenu(systemMenu, SC_CLOSE, MF_BYCOMMAND);
            }
            
            // Set console control handler
            return SetConsoleCtrlHandler(handler, true);
        }
        
        public static bool DisableProtection() {
            // Re-enable the close button
            IntPtr consoleWindow = GetConsoleWindow();
            GetSystemMenu(consoleWindow, true); // Restore original menu
            
            // Remove console control handler
            if (handler != null) {
                SetConsoleCtrlHandler(handler, false);
                handler = null;
                return true;
            }
            return false;
        }
    }
"@
}

# Console control handler function
$global:CtrlHandler = {
    param([int]$ctrlType)
    
    if ($global:WindowProtected) {
        if ($ctrlType -eq 2) { # CTRL_CLOSE_EVENT
            try {
                [Console]::Beep(800, 200)
                [Console]::Beep(600, 200)
                
                # Write to a file since console output might not work during close event
                $msg = @"

╔════════════════════════════════════════════════╗
║  ⭐ CỬA SỔ ĐANG BỊ KHÓA BẢO VỆ!               ║
║                                                ║
║  Không thể đóng cửa sổ này!                    ║
║  Gõ lệnh 'unstar' để mở khóa trước khi đóng.   ║
╚════════════════════════════════════════════════╝

"@
                # Try to display in console
                [Console]::WriteLine($msg)
                
                # Sleep to let user see the message
                Start-Sleep -Milliseconds 2000
            } catch {
                # Ignore errors during close event
            }
            
            return $true  # Block close
        }
    }
    
    return $false  # Allow other events
}

# ⭐ STAR - Lock window from being closed
function global:star {
    if ($global:WindowProtected) {
        Write-Host "  ⭐ Cửa sổ đã được bảo vệ rồi!" -ForegroundColor Yellow
        return
    }
    
    try {
        # Create delegate
        $delegate = [ConsoleCtrlDelegate]$global:CtrlHandler
        
        # Enable protection (disable close button + set handler)
        $success = [WindowProtection]::EnableProtection($delegate)
        
        if ($success) {
            $global:WindowProtected = $true
            
            Write-Host ""
            Write-Host "  ⭐ WINDOW PROTECTION ACTIVATED" -ForegroundColor Cyan
            Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
            Write-Host "  ✅ Close button disabled" -ForegroundColor Green
            Write-Host "  ✅ Close event intercepted" -ForegroundColor Green
            Write-Host ""
            Write-Host "  🔒 Cửa sổ này đã được bảo vệ khỏi việc đóng nhầm." -ForegroundColor White
            Write-Host "  🔑 Gõ 'unstar' để mở khóa." -ForegroundColor Yellow
            Write-Host ""
        } else {
            Write-Host "  ❌ Không thể kích hoạt bảo vệ!" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 🔓 UNSTAR - Unlock window
function global:unstar {
    if (-not $global:WindowProtected) {
        Write-Host "  🔓 Cửa sổ không bị khóa." -ForegroundColor Yellow
        return
    }
    
    try {
        $success = [WindowProtection]::DisableProtection()
        
        if ($success -or $true) { # Sometimes returns false but works
            $global:WindowProtected = $false
            
            Write-Host ""
            Write-Host "  🔓 WINDOW UNLOCKED" -ForegroundColor Yellow
            Write-Host "  ──────────────────" -ForegroundColor DarkGray
            Write-Host "  ⚠️  Bạn có thể đóng cửa sổ này ngay bây giờ." -ForegroundColor Red
            Write-Host ""
        }
    } catch {
        Write-Host "  ❌ Lỗi khi mở khóa: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Override default exit to prevent accidental closing if protected
function global:exit {
    if ($global:WindowProtected) {
        Write-Host ""
        Write-Host "  ⭐ CỬA SỔ ĐANG ĐƯỢC BẢO VỆ!" -ForegroundColor Red
        Write-Host "  Gõ 'unstar' trước khi thoát." -ForegroundColor Yellow
        Write-Host ""
        return
    }
    Microsoft.PowerShell.Core\Stop-Process -Id $PID
}

# 16. ⚡ GOD MODE (SYSTEM SHELL)
function global:god {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  ❌ Bạn cần chạy PowerShell dưới quyền Administrator trước!" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "  ⚡ GOD MODE (NT AUTHORITY\SYSTEM) INITIATED" -ForegroundColor Magenta
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray

    # Kiểm tra PsExec
    $binDir = "$HOME\Documents\WindowsPowerShell\Bin"
    $psexec = "$binDir\PsExec64.exe"
    
    if (-not (Test-Path $psexec)) {
        # Check path hệ thống trước
        if (Get-Command PsExec.exe -ErrorAction SilentlyContinue) {
            $psexec = "PsExec.exe"
        } else {
            Write-Host "  🛠️  Đang tải PsExec (Sysinternals) từ Microsoft..." -ForegroundColor Yellow
            if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
            
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri "https://live.sysinternals.com/PsExec64.exe" -OutFile $psexec
                Write-Host "  ✅ Đã tải xong công cụ." -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Không thể tải PsExec. Vui lòng kiểm tra mạng." -ForegroundColor Red
                return
            }
        }
    }

    Write-Host "  🚀 Launching SYSTEM shell..." -ForegroundColor Cyan
    
    try {
        # -i: Interactive, -s: System, -d: Don't wait
        # Ép buộc nạp profile bằng cách gọi: pwsh -Command ". 'ProfilePath'"
        $profilePath = $PROFILE
        $innerCmd = "powershell.exe -NoExit -ExecutionPolicy Bypass -Command `". '$profilePath'; `$Host.UI.RawUI.WindowTitle = '⚡ GOD MODE (SYSTEM)'; cd '$($PWD.Path)'; Write-Host '  💀 WARNING: YOU ARE NOW RUNNING AS SYSTEM!' -ForegroundColor Red; Write-Host '  💀 POWERS UNLIMITED. TREAD LIGHTLY.' -ForegroundColor Red;`""
        
        Start-Process -FilePath $psexec -ArgumentList "-i", "-s", "-d", $innerCmd -Verb RunAs -WindowStyle Normal
        Write-Host "  ✨ Done." -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Lỗi khởi chạy: $_" -ForegroundColor Red
    }
    Write-Host ""
}

#region ═══════════════════════════════════════════════════════════════════════════
#        ☢️ NUCLEAR ADMIN TOOLS (HANDLE WITH CARE)
#endregion ════════════════════════════════════════════════════════════════════════

# 18. 🛡️ DEFENDER MANAGER (Toggle AV)
function global:def {
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("on", "off", "status")]
        [string]$Action = "status"
    )

    if (-not (Assert-Ring -ReqLevel 3 -CmdName "def")) { return } # Yêu cầu System/TI

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  ❌ Yêu cầu quyền Administrator/SYSTEM/TrustedInstaller!" -ForegroundColor Red
        return
    }

    if ($Action -eq "status") {
        Write-Host ""
        Write-Host "  🛡️  TRẠNG THÁI WINDOWS DEFENDER" -ForegroundColor Cyan
        Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
        try {
            $mp = Get-MpPreference
            $status = if ($mp.DisableRealtimeMonitoring) { "❌ ĐÃ TẮT (Disabled)" } else { "✅ ĐANG BẬT (Active)" }
            $color = if ($mp.DisableRealtimeMonitoring) { "Red" } else { "Green" }
            
            Write-Host "  📡 Bảo vệ thời gian thực: " -NoNewline -ForegroundColor DarkGray
            Write-Host $status -ForegroundColor $color
            
            Write-Host "  ☁️  Bảo vệ đám mây      : " -NoNewline -ForegroundColor DarkGray
            Write-Host $(if ($mp.DisableBlockAtFirstSeen) { "❌ TẮT" } else { "✅ BẬT" }) -ForegroundColor White
        } catch {
            Write-Host "  ⚠️  Không thể lấy trạng thái (Service đang tắt?)" -ForegroundColor Yellow
        }
        Write-Host ""
        return
    }

    if ($Action -eq "off") {
        Write-Host "  📉 Đang vô hiệu hóa Windows Defender..." -ForegroundColor Yellow
        try {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction Stop
            Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableBlockAtFirstSeen $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableScanningNetworkFiles $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
            Write-Host "  💀 Defender Real-time Protection đã bị DIỆT." -ForegroundColor Red
        } catch {
            Write-Host "  ❌ Thất bại. Hãy thử chạy lệnh 'ti' trước!" -ForegroundColor Red
            Write-Host "  Lỗi: $($_.Exception.Message)" -ForegroundColor DarkRed
        }
    }
    elseif ($Action -eq "on") {
        Write-Host "  📈 Đang bật lại Windows Defender..." -ForegroundColor Green
        try {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
            Write-Host "  🛡️  Defender đã hoạt động trở lại." -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 18.5 🦠 AVKILL (DEATH MARK EDITION)
function global:avkill {
    # Yêu cầu tối thiểu TrustedInstaller (Ring 4)
    if (-not (Assert-Ring -ReqLevel 4 -CmdName "avkill")) { return }
    
    [NativeKiller]::EnablePrivilege("SeDebugPrivilege") | Out-Null

    Write-Host ""
    Write-Host "  🦠 AV KILLER: DEATH MARK PROTOCOL" -ForegroundColor Red
    Write-Host "  ──────────────────────────────────────────────────" -ForegroundColor DarkGray

    # Map: Process Name -> Service Name
    $Targets = @{
        "MsMpEng" = "WinDefend"; "NisSrv" = "WdNisSvc"; "Sense" = "Sense"; 
        "SecurityHealthService" = "SecurityHealthService"; "WdBnService" = "WdBnService";
        "avp" = "AVP"; "ekrn" = "ekrn"; "AvastSvc" = "Avast"; "mcshield" = "McAfeeFramework";
        "bdservicehost" = "vsserv"; "mbamservice" = "MBAMService"
    }

    $hitList = @()

    # 1. SCANNING
    foreach ($procName in $Targets.Keys) {
        $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($p in $procs) {
                Write-Host "  🎯 FOUND: $($p.Name) (PID: $($p.Id))" -ForegroundColor Yellow
                $hitList += @{ Name=$p.Name; Svc=$Targets[$procName]; Id=$p.Id }
            }
        }
    }

    if ($hitList.Count -eq 0) {
        Write-Host "  🤷 Không tìm thấy mục tiêu nào đang chạy." -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "  ⚔️  EXECUTING KILL CHAIN..." -ForegroundColor Cyan
    
    foreach ($item in $hitList) {
        Write-Host "  [" -NoNewline -ForegroundColor DarkGray
        Write-Host "☠️" -NoNewline -ForegroundColor Red
        Write-Host "] Target: $($item.Name)" -ForegroundColor White
        
        # PHASE 1: TRY INSTANT KILL (Native API)
        $killResult = [NativeKiller]::ZeroKill($item.Id)
        
        if ($killResult -eq "Success") {
            Write-Host "      ⚡ STATUS: TERMINATED (INSTANT KILL)" -ForegroundColor Green
        } else {
            Write-Host "      🛡️ STATUS: RESISTED ($killResult)" -ForegroundColor DarkGray
            
            # PHASE 2: GOD SLAYER (Registry Annihilation)
            # Chỉ hoạt động nếu đang ở chế độ TrustedInstaller
            if ((Get-RingLevel) -ge 4) {
                Write-Host "      🔨 ACTIVATING GOD SLAYER (Registry Destroy)..." -ForegroundColor Magenta
                godslayer -ServiceName $item.Svc -Silent $true
            } else {
                Write-Host "      ❌ Cần quyền 'ti' để phá hủy Registry!" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "  🏁 REPORT:" -ForegroundColor Cyan
    Write-Host "  Nếu trạng thái là 'REGISTRY DESTROYED', AV đã bị vô hiệu hóa." -ForegroundColor Yellow
    Write-Host "  👉 HÃY KHỞI ĐỘNG LẠI MÁY ĐỂ HOÀN TẤT VIỆC HỦY DIỆT." -ForegroundColor Green
    Write-Host ""
}

# 18.6 💀 GOD SLAYER (Registry Annihilator)
function global:godslayer {
    param(
        [string]$ServiceName,
        [bool]$Silent = $false
    )
    
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    
    if (-not (Test-Path $regPath)) {
        if (-not $Silent) { Write-Host "  ⚪ Service '$ServiceName' not found in Registry." -ForegroundColor DarkGray }
        return
    }

    try {
        # 1. Disable Service (Start = 4)
        Set-ItemProperty -Path $regPath -Name "Start" -Value 4 -Type DWord -ErrorAction Stop
        
        # 2. Corrupt ImagePath (Neutering)
        # Trỏ về svchost rỗng để nó không thể load file exe của AV nữa
        Set-ItemProperty -Path $regPath -Name "ImagePath" -Value "svchost.exe -k LocalService" -ErrorAction SilentlyContinue
        
        # 3. Remove FailureActions (Prevent Auto-Restart)
        Remove-ItemProperty -Path $regPath -Name "FailureActions" -ErrorAction SilentlyContinue

        if ($Silent) {
            Write-Host "      ✅ RESULT: REGISTRY DESTROYED (Start=Disabled)" -ForegroundColor Green
        } else {
            Write-Host "  ✅ Service '$ServiceName' has been NEUTERED." -ForegroundColor Green
        }
    } catch {
        if ($Silent) {
            Write-Host "      ❌ RESULT: FAILED (Access Denied?)" -ForegroundColor Red
        } else {
            Write-Host "  ❌ Failed to slay '$ServiceName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 19. 💣 NUKE (Destroy Process/Service Forcefully)
function global:nuke {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Assert-Ring -ReqLevel 2 -CmdName "nuke")) { return }

    Write-Host "  💣 NUKING TARGET: $Name" -ForegroundColor Red
    
    # 1. Try killing as Process
    $procs = Get-Process -Name $Name -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            Write-Host "  🔫 Killing Process: $($p.Name) (PID: $($p.Id))..." -NoNewline -ForegroundColor Yellow
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction Stop
                Write-Host " DEAD." -ForegroundColor Red
            } catch {
                # Fallback to taskkill (mạnh hơn Stop-Process)
                taskkill /F /PID $p.Id | Out-Null
                if (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) {
                    Write-Host " FAILED." -ForegroundColor DarkGray
                } else {
                    Write-Host " DESTROYED (via taskkill)." -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "  ⚪ No active process found." -ForegroundColor DarkGray
    }

    # 2. Try killing as Service (Disable + Stop)
    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $svc) { $svc = Get-Service -DisplayName $Name -ErrorAction SilentlyContinue }
    
    if ($svc) {
        Write-Host "  ⚙️  Found Service: $($svc.Name) ($($svc.Status))" -ForegroundColor Cyan
        if ($svc.Status -ne 'Stopped') {
            Write-Host "  🔻 Stopping service..." -NoNewline -ForegroundColor Yellow
            try {
                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                Write-Host " STOPPED & DISABLED." -ForegroundColor Red
            } catch {
                # Force kill via SC & Taskkill if access denied
                sc.exe config $svc.Name start= disabled | Out-Null
                $svcPID = (Get-CimInstance Win32_Service -Filter "Name='$($svc.Name)'").ProcessId
                if ($svcPID -gt 0) {
                    taskkill /F /PID $svcPID | Out-Null
                    Write-Host " FORCE KILLED (PID $svcPID)." -ForegroundColor Red
                } else {
                    Write-Host " FAILED (Access Denied? Use 'ti')." -ForegroundColor DarkRed
                }
            }
        } else {
            Write-Host "  💤 Service already stopped." -ForegroundColor DarkGray
        }
    }
}

# 20. 👻 GHOST (Clear Logs/Tracks)
function global:ghost {
    if (-not (Assert-Ring -ReqLevel 2 -CmdName "ghost")) { return }

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  ❌ Admin rights required to clear logs." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "  👻 GHOST PROTOCOL (CLEARING LOGS)" -ForegroundColor DarkGray
    Write-Host "  ─────────────────────────────────" -ForegroundColor DarkGray

    $logs = Wevtutil el
    $total = $logs.Count
    $i = 0
    
    foreach ($log in $logs) {
        $i++
        $pct = [math]::Round(($i / $total) * 100)
        Write-Progress -Activity "Wiping Logs" -Status "$log" -PercentComplete $pct
        
        # Chỉ xóa log có dữ liệu để tiết kiệm thời gian
        try {
             Wevtutil cl "$log" 2>$null
        } catch {}
    }
    Write-Progress -Activity "Wiping Logs" -Completed
    
    # Clear PowerShell History
    Clear-History
    Remove-Item (Get-PSReadlineOption).HistorySavePath -ErrorAction SilentlyContinue
    
    Write-Host "  ✨ All Event Logs CLEARED." -ForegroundColor Green
    Write-Host "  ✨ PowerShell History WIPED." -ForegroundColor Green
    Write-Host "  🕶️  System is clean." -ForegroundColor Cyan
    Write-Host ""
}

#region ═══════════════════════════════════════════════════════════════════════════
#        💀 KERNEL-LEVEL BRIDGE (NATIVE API CALLS)
#endregion ════════════════════════════════════════════════════════════════════════

# C# Bridge để gọi Native API (ntdll.dll) và Token Manipulation
if (-not ([System.Management.Automation.PSTypeName]'NativeKiller').Type) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public static class NativeKiller {
    [DllImport("ntdll.dll")]
    public static extern uint NtTerminateProcess(IntPtr ProcessHandle, int ExitStatus);

    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);

    [DllImport("kernel32.dll", ExactSpelling = true)]
    internal static extern IntPtr GetCurrentProcess();

    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);

    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid {
        public int Count;
        public long Luid;
        public int Attr;
    }

    // Các hằng số quyền hạn
    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    
    // Enable Privilege (SeDebugPrivilege is key for killing system processes)
    public static bool EnablePrivilege(string privilege) {
        try {
            IntPtr hproc = GetCurrentProcess();
            IntPtr htok = IntPtr.Zero;
            if (!OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok)) return false;

            TokPriv1Luid tp;
            tp.Count = 1;
            tp.Luid = 0;
            tp.Attr = SE_PRIVILEGE_ENABLED;
            
            if (!LookupPrivilegeValue(null, privilege, ref tp.Luid)) return false;

            if (!AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero)) return false;
            
            return true;
        } catch { return false; }
    }

    public static string ZeroKill(int pid) {
        // PROCESS_TERMINATE = 0x0001
        IntPtr hProc = OpenProcess(0x0001, false, pid);
        
        if (hProc == IntPtr.Zero) {
            return "Failed to open handle (Protected Process?)";
        }

        // Gọi trực tiếp NT API -> Bỏ qua win32 checks
        uint status = NtTerminateProcess(hProc, 0);
        CloseHandle(hProc);

        if (status == 0) return "Success"; // STATUS_SUCCESS
        return "NtStatus Error: " + status;
    }
}
"@
}

# 21. ⚡ POWERUP (TITAN EDITION - ENABLE ALL 36 PRIVILEGES)
function global:powerup {
    Write-Host ""
    Write-Host "  ⚡ POWERUP PROTOCOL: TITAN EDITION" -ForegroundColor Magenta
    Write-Host "  ─────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  🔓 Attempting to UNLOCK ALL Windows Privileges..." -ForegroundColor Cyan
    Write-Host ""

    # Danh sách đầy đủ 36 quyền của Windows (The God List)
    $GodPrivileges = @(
        # --- Critical / System Core ---
        "SeDebugPrivilege",             # Debug programs (God mode for processes)
        "SeTcbPrivilege",               # Act as part of the operating system
        "SeAssignPrimaryTokenPrivilege",# Replace a process level token
        "SeLoadDriverPrivilege",        # Load and unload device drivers
        "SeBackupPrivilege",            # Back up files and directories (Read All)
        "SeRestorePrivilege",           # Restore files and directories (Write All)
        "SeTakeOwnershipPrivilege",     # Take ownership of files or other objects
        "SeCreateTokenPrivilege",       # Create a token object
        "SeImpersonatePrivilege",       # Impersonate a client after authentication
        "SeRelabelPrivilege",           # Modify an object label
        
        # --- System Management ---
        "SeSystemEnvironmentPrivilege", # Modify firmware environment values
        "SeSystemProfilePrivilege",     # Profile system performance
        "SeSystemtimePrivilege",        # Change the system time
        "SeShutdownPrivilege",          # Shut down the system
        "SeUndockPrivilege",            # Remove computer from docking station
        "SeManageVolumePrivilege",      # Perform volume maintenance tasks
        "SeLockMemoryPrivilege",        # Lock pages in memory
        "SeIncreaseBasePriorityPrivilege", # Increase scheduling priority
        "SeIncreaseQuotaPrivilege",     # Adjust memory quotas for a process
        
        # --- Security & Audit ---
        "SeSecurityPrivilege",          # Manage auditing and security log
        "SeAuditPrivilege",             # Generate security audits
        "SeChangeNotifyPrivilege",      # Bypass traverse checking
        "SeCreateGlobalPrivilege",      # Create global objects
        "SeCreatePagefilePrivilege",    # Create a pagefile
        "SeCreatePermanentPrivilege",   # Create permanent shared objects
        "SeCreateSymbolicLinkPrivilege",# Create symbolic links
        "SeDelegateSessionUserImpersonatePrivilege",
        "SeEnableDelegationPrivilege",
        "SeMachineAccountPrivilege",    # Add workstations to domain
        "SeProfileSingleProcessPrivilege",
        "SeRemoteShutdownPrivilege",    # Force shutdown from a remote system
        "SeSyncAgentPrivilege",
        "SeTimeZonePrivilege",
        "SeTrustedCredManAccessPrivilege"
    )

    $successCount = 0
    $failCount = 0

    foreach ($p in $GodPrivileges) {
        # Visual delay for effect (can be removed for speed)
        # Start-Sleep -Milliseconds 10 
        
        if ([NativeKiller]::EnablePrivilege($p)) {
            $status = "✅ ENABLED"
            $color = "Green"
            $successCount++
        } else {
            $status = "❌ DENIED "
            $color = "DarkGray"
            $failCount++
        }

        # Hiển thị dạng bảng Matrix 2 cột
        Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-35}" -f $p) -NoNewline -ForegroundColor White
        Write-Host "│ " -NoNewline -ForegroundColor DarkGray
        Write-Host $status -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "  ─────────────────────────────────" -ForegroundColor DarkGray
    
    if ($successCount -ge 5) {
        Write-Host "  🔥 OVERDRIVE COMPLETE." -ForegroundColor Magenta
    } else {
        Write-Host "  ⚠️  LIMITED POWER." -ForegroundColor Yellow
        Write-Host "  💡 Tip: Run as 'ti' (TrustedInstaller) or 'god' (System) to unlock more." -ForegroundColor DarkGray
    }
    
    Write-Host "  📊 Result: " -NoNewline -ForegroundColor Cyan
    Write-Host "$successCount Unlocked" -NoNewline -ForegroundColor Green
    Write-Host " / " -NoNewline -ForegroundColor DarkGray
    Write-Host "$failCount Locked" -ForegroundColor Red
    Write-Host ""
}

#region ═══════════════════════════════════════════════════════════════════════════
#        🛡️ RING SECURITY GATEKEEPER
#endregion ════════════════════════════════════════════════════════════════════════

function global:Get-RingLevel {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]$id
    $isAdmin = $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $isSystem = $id.IsSystem
    
    # Check Ring -1 (SeDebugPrivilege Enabled)
    $hasDebug = $false
    try { if ((whoami /priv) -match "SeDebugPrivilege.*Enabled") { $hasDebug = $true } } catch {}
    if ($hasDebug) { return 5 } 

    # Check Ring 0 (TrustedInstaller)
    if ($isSystem -and ($Host.UI.RawUI.WindowTitle -match "TrustedInstaller")) { return 4 }
    
    # Check Ring 1 (System)
    if ($isSystem) { return 3 }
    
    # Check Ring 2 (Admin)
    if ($isAdmin) { return 2 }
    
    # Ring 3 (User)
    return 1
}

function global:Assert-Ring {
    param(
        [int]$ReqLevel,
        [string]$CmdName
    )
    
    $curLevel = Get-RingLevel
    $ringNames = @{1="User (Ring 3)"; 2="Admin (Ring 2)"; 3="System (Ring 1)"; 4="TrustedInstaller (Ring 0)"; 5="PowerUp (Ring -1)"}
    
    if ($curLevel -lt $ReqLevel) {
        # Xác định phương thức mở
        $method = ""
        $action = ""
        switch ($ReqLevel) {
            2 { $method = "Run 'sudo'"; $action = "New Window (Admin)" }
            3 { $method = "Run 'god'"; $action = "New Window (System)" }
            4 { $method = "Run 'ti'"; $action = "New Window (TrustedInstaller)" }
            5 { $method = "Run 'powerup'"; $action = "In-Place Token Overdrive" }
        }

        Write-Host ""
        Write-Host "  🛑 ACCESS DENIED: INSUFFICIENT PRIVILEGE" -ForegroundColor Red
        Write-Host "     Command : " -NoNewline -ForegroundColor DarkGray
        Write-Host $CmdName -ForegroundColor White
        Write-Host "     Current : " -NoNewline -ForegroundColor DarkGray
        Write-Host $ringNames[$curLevel] -ForegroundColor Yellow
        Write-Host "     Required: " -NoNewline -ForegroundColor DarkGray
        Write-Host $ringNames[$ReqLevel] -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "  🔓 UNLOCK METHOD: " -NoNewline -ForegroundColor DarkGray
        Write-Host "$method " -NoNewline -ForegroundColor Green
        Write-Host "($action)" -ForegroundColor DarkGray
        Write-Host ""
        
        # Hỏi user
        Write-Host "  👉 [Y] Unlock Now (Mở quyền)  │  [N] Continue Anyway (Chạy cố)" -ForegroundColor White
        $choice = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        if ($choice.VirtualKeyCode -eq 89) { # Y (89 is keycode for Y)
            Write-Host "  🚀 Launching elevation protocol..." -ForegroundColor Green
            Start-Sleep -Milliseconds 500
            
            switch ($ReqLevel) {
                2 { sudo }
                3 { god }
                4 { ti }
                5 { powerup } 
            }
            
            # Nếu là PowerUp (Level 5), nó chạy tại chỗ nên ta cho phép lệnh gốc tiếp tục
            # Các level khác mở cửa sổ mới nên ta dừng lệnh gốc ở cửa sổ hiện tại
            if ($ReqLevel -eq 5) { return $true } 
            return $false 
        } else {
            Write-Host "  ⚠️  Proceeding with limited privileges (Might fail)..." -ForegroundColor DarkGray
            return $true 
        }
    }
    return $true
}

# 23. 💍 RINGS (QUÉT CẤP ĐỘ QUYỀN LỰC)
function global:rings {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = [Security.Principal.WindowsPrincipal]$id
    $isAdmin = $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $isSystem = $id.IsSystem
    $userName = $id.Name
    
    # Check Integrity Level
    $integrity = "Trung Bình (User)"
    $groups = whoami /groups
    if ($groups -match "High Mandatory Level") { $integrity = "Cao (Admin)" }
    if ($groups -match "System Mandatory Level") { $integrity = "Hệ Thống (Kernel-Equivalent)" }

    # Check PowerUp Status
    $hasDebug = $false
    try {
        $whoamiPrivs = whoami /priv
        if ($whoamiPrivs -match "SeDebugPrivilege.*Enabled") { $hasDebug = $true }
    } catch {}

    # Check TrustedInstaller
    $isTI = ($isSystem -and ($Host.UI.RawUI.WindowTitle -match "TrustedInstaller"))

    # --- UI RENDERING ---
    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║                🛡️  THẺ NHẬN DIỆN BẢO MẬT (RINGS)                  ║" -ForegroundColor Cyan
    Write-Host "  ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # --- LEVEL 1: RING 3 ---
    if (-not $isAdmin) {
        Write-Host "  ║  🟢 NGƯỜI DÙNG (Ring 3)        : ĐANG HOẠT ĐỘNG                   ║" -ForegroundColor Green
    } else {
        Write-Host "  ║  ⚫ Người dùng (Ring 3)        : Không hoạt động                  ║" -ForegroundColor DarkGray
    }
    
    # --- LEVEL 2: ADMIN ---
    if ($isAdmin -and -not $isSystem) {
        Write-Host "  ║  🔵 QUẢN TRỊ VIÊN (Ring 2)     : ĐANG HOẠT ĐỘNG                   ║" -ForegroundColor Cyan
    } else {
        Write-Host "  ║  ⚫ Quản trị viên (Ring 2)     : Không hoạt động                  ║" -ForegroundColor DarkGray
    }

    # --- LEVEL 3: SYSTEM ---
    if ($isSystem) {
        Write-Host "  ║  🟣 HỆ THỐNG / GOD (Ring 1)    : ĐANG HOẠT ĐỘNG                   ║" -ForegroundColor Magenta
    } else {
        Write-Host "  ║  ⚫ Hệ thống / GOD (Ring 1)    : Không hoạt động                  ║" -ForegroundColor DarkGray
    }

    Write-Host "  ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "  ║              ⚙️  CỔNG KẾT NỐI KERNEL (RING 0 GATEWAY)              ║" -ForegroundColor Cyan
    Write-Host "  ╠═══════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan

    # --- LEVEL 4: TRUSTED INSTALLER ---
    if ($isTI) {
        Write-Host "  ║  🟠 TRUSTED INSTALLER (Ring 0) : ĐANG HOẠT ĐỘNG (FILE OWNER)      ║" -ForegroundColor Yellow
    } else {
        Write-Host "  ║  ⚫ Trusted Installer (Ring 0) : Không hoạt động                  ║" -ForegroundColor DarkGray
    }

    # --- LEVEL 5: POWERUP ---
    if ($hasDebug) {
        Write-Host "  ║  ☢️  POWERUP (Ring -1 Bridge)   : ĐÃ BẺ KHÓA (SeDebug Enabled)     ║" -ForegroundColor Red
    } else {
        Write-Host "  ║  ⚫ PowerUp (Ring -1 Bridge)   : Đang khóa (Chưa Unlock)          ║" -ForegroundColor DarkGray
    }

    Write-Host "  ╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # --- BADGE ---
    Write-Host "   👉 CẤP ĐỘ HIỆN TẠI: " -NoNewline -ForegroundColor White
    
    if ($hasDebug) { 
        Write-Host " CẤP 5 - POWERUP (SIÊU CẤP) " -ForegroundColor White -BackgroundColor Red
    } elseif ($isTI) {
        Write-Host " CẤP 4 - TRUSTED INSTALLER (CHỦ SỞ HỮU) " -ForegroundColor Black -BackgroundColor Yellow
    } elseif ($isSystem) {
        Write-Host " CẤP 3 - HỆ THỐNG (GOD MODE) " -ForegroundColor White -BackgroundColor Magenta
    } elseif ($isAdmin) {
        Write-Host " CẤP 2 - QUẢN TRỊ VIÊN (ADMIN) " -ForegroundColor Black -BackgroundColor Cyan
    } else {
        Write-Host " CẤP 1 - NGƯỜI DÙNG (USER) " -ForegroundColor Black -BackgroundColor Green
    }
    Write-Host ""
}

# 22. 💀 ZKILL (Native API Terminator)
function global:zkill {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Assert-Ring -ReqLevel 5 -CmdName "zkill")) { return } # Yêu cầu PowerUp

    # Tự động PowerUp trước khi giết
    [NativeKiller]::EnablePrivilege("SeDebugPrivilege") | Out-Null

    Write-Host "  💀 ZERO KILL (Native API): $Name" -ForegroundColor Magenta
    
    $procs = Get-Process -Name $Name -ErrorAction SilentlyContinue
    if (-not $procs) { 
        # Thử tìm theo ID nếu input là số
        if ($Name -match "^\d+$") {
             $procs = Get-Process -Id $Name -ErrorAction SilentlyContinue
        }
    }

    if ($procs) {
        foreach ($p in $procs) {
            Write-Host "  Target: $($p.Name) (PID: $($p.Id))..." -NoNewline -ForegroundColor White
            
            # Gọi hàm C# Native
            $result = [NativeKiller]::ZeroKill($p.Id)
            
            if ($result -eq "Success") {
                Write-Host " TERMINATED." -ForegroundColor Red
            } else {
                Write-Host " FAILED ($result)." -ForegroundColor DarkGray
                # Fallback: Nếu Native API thất bại (do PPL), gợi ý TrustedInstaller
                if ($result -match "Protected") {
                     Write-Host "  🔒 Target is Protected (PPL). Use 'ti' mode first!" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "  ⚪ Process not found." -ForegroundColor DarkGray
    }
}

#region ═══════════════════════════════════════════════════════════════════════════
#        🌀 RING -1: HYPERVISOR & FIRMWARE LAYER
#endregion ════════════════════════════════════════════════════════════════════════

# 23. 🕹️ HYP (Hypervisor Status & Control)
function global:hyp {
    Write-Host ""
    Write-Host "  🌀 RING -1: HYPERVISOR LAYER CONTROL" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────" -ForegroundColor DarkGray
    
    # 1. Detect Hypervisor
    $sys = Get-CimInstance Win32_ComputerSystem
    $isHypervisorPresent = $sys.HypervisorPresent
    
    Write-Host "  🖥️  Hypervisor Present  : " -NoNewline -ForegroundColor DarkGray
    if ($isHypervisorPresent) { 
        Write-Host "YES (Virtualized)" -ForegroundColor Cyan 
    } else { 
        Write-Host "NO (Bare Metal)" -ForegroundColor Yellow 
    }

    # 2. VBS / HVCI Status (Security running at Ring -1)
    $sec = Get-CimInstance Win32_DeviceGuard -ErrorAction SilentlyContinue
    $vbsStatus = if ($sec.SecurityServicesRunning -match 1) { "RUNNING" } else { "STOPPED" }
    
    Write-Host "  🛡️  Virtual Security (VBS): " -NoNewline -ForegroundColor DarkGray
    Write-Host $vbsStatus -ForegroundColor $(if($vbsStatus -eq "RUNNING"){"Green"}else{"Red"})

    # 3. Check for Hyper-V features if module exists
    if (Get-Command Get-VM -ErrorAction SilentlyContinue) {
        $vms = Get-VM
        Write-Host "  📦 Managed VMs          : " -NoNewline -ForegroundColor DarkGray
        Write-Host $vms.Count -ForegroundColor White
        
        foreach ($vm in $vms) {
            $stateColor = if ($vm.State -eq 'Running') { "Green" } else { "DarkGray" }
            Write-Host "     ├─ $($vm.Name) " -NoNewline -ForegroundColor White
            Write-Host "[$($vm.State)]" -ForegroundColor $stateColor
        }
    } else {
        Write-Host "  ⚠️  Hyper-V Module not loaded." -ForegroundColor DarkGray
    }
    Write-Host ""
}

# 24. 🧠 UEFI (Firmware / NVRAM Interaction)
function global:uefi {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  ❌ Admin rights required for Firmware access." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "  🧠 FIRMWARE INTERFACE (UEFI/NVRAM)" -ForegroundColor Magenta
    Write-Host "  ──────────────────────────────────" -ForegroundColor DarkGray
    
    # Secure Boot Status
    $sb = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
    Write-Host "  🔒 Secure Boot : " -NoNewline -ForegroundColor DarkGray
    if ($sb) { Write-Host "ENABLED" -ForegroundColor Green } else { Write-Host "DISABLED/LEGACY" -ForegroundColor Red }

    # Boot Entries (Using BCD)
    Write-Host "  🚀 Boot Loader : " -NoNewline -ForegroundColor DarkGray
    try {
        $bcd = bcdedit /enum "{current}" | Select-String "description"
        $desc = $bcd.ToString().Split(" ")[-1]
        Write-Host $desc -ForegroundColor Cyan
    } catch { Write-Host "Unknown" -ForegroundColor DarkGray }

    Write-Host ""
    Write-Host "  ⚠️  WARNING: Modifying NVRAM variables can brick the board." -ForegroundColor Red
    Write-Host ""
}

# 25. ⚡ VM-X (PowerShell Direct - VM Escape/Injection)
function global:vmx {
    param(
        [Parameter(Mandatory)][string]$VMName,
        [Parameter(Mandatory)][string]$Command
    )
    
    Write-Host "  💉 INJECTING CODE INTO VM LAYER: $VMName" -ForegroundColor Cyan
    
    try {
        # Bypass network stack, talk directly via VMBus (Ring -1 Channel)
        Invoke-Command -VMName $VMName -ScriptBlock { 
            param($c) 
            Invoke-Expression $c 
        } -ArgumentList $Command -Credential (Get-Credential) -ErrorAction Stop
        
        Write-Host "  ✅ Injection Successful." -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Injection Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 17. 🛡️ TRUSTED INSTALLER (HIGHER THAN KERNEL/SYSTEM)
function global:ti {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  ❌ Yêu cầu quyền Administrator trước!" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "  🛡️  TRUSTED INSTALLER MODE (The 'Real' God Mode)" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    # Try to find NSudo (common tool for this)
    $nsudoPath = Get-Command "NSudo.exe" -ErrorAction SilentlyContinue
    if (-not $nsudoPath) {
        $nsudoPath = Get-Command "NSudoLG.exe" -ErrorAction SilentlyContinue
    }

    if ($nsudoPath) {
        Write-Host "  🚀 Launching via NSudo..." -ForegroundColor Green
        # Ép buộc nạp profile bằng cách gọi: pwsh -Command ". 'ProfilePath'"
        $profilePath = $PROFILE
        $argList = "-U:T -P:E powershell.exe -NoExit -ExecutionPolicy Bypass -Command . '$profilePath'; Set-Location '$PWD'"
        Start-Process $nsudoPath.Source -ArgumentList $argList -Verb RunAs
        return
    }
    
    # If no tool, explain and offer SYSTEM
    Write-Host "  ⚠️  TrustedInstaller requires external tools (NSudo/AdvancedRun)." -ForegroundColor Yellow
    Write-Host "  💡 SYSTEM (God Mode) is the highest native privilege available." -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "  👉 Launch SYSTEM mode instead? (y/n)"
    if ($choice -eq 'y') {
        god
    }
}

#region ═══════════════════════════════════════════════════════════════════════════
#        🌀 RING -1: HYPERVISOR & FIRMWARE INTERACTION
#endregion ════════════════════════════════════════════════════════════════════════

# 23. 🕹️ HYP (Hypervisor Introspection)
function global:hyp {
    Write-Host ""
    Write-Host "  🌀 RING -1: HYPERVISOR LAYER INTROSPECTION" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
    
    # 1. Detect Execution Mode (Bare Metal vs Virtualized)
    $sys = Get-CimInstance Win32_ComputerSystem
    $proc = Get-CimInstance Win32_Processor | Select-Object -First 1
    
    Write-Host "  🖥️  Execution Context   : " -NoNewline -ForegroundColor DarkGray
    if ($sys.HypervisorPresent) { 
        if ($sys.Model -match "Virtual|VMware|KVM|Hyper-V") {
            Write-Host "GUEST (Virtual Machine)" -ForegroundColor Yellow 
        } else {
            Write-Host "HOST (Hyper-V Active)" -ForegroundColor Cyan 
        }
    } else { 
        Write-Host "BARE METAL (Ring 0 Direct)" -ForegroundColor Green 
    }

    Write-Host "  🧠 Virtualization Flag  : " -NoNewline -ForegroundColor DarkGray
    if ($proc.VirtualizationFirmwareEnabled) { Write-Host "ENABLED (VT-x/AMD-V)" -ForegroundColor Green } else { Write-Host "DISABLED" -ForegroundColor Red }

    # 2. VBS / HVCI Status (Virtualization Based Security)
    # Đây là lớp bảo mật chạy ở Ring -1 để bảo vệ Kernel Ring 0
    try {
        $sec = Get-CimInstance Win32_DeviceGuard -ErrorAction Stop
        $vbsStatus = if ($sec.SecurityServicesRunning -contains 1) { "RUNNING" } else { "STOPPED" }
        $credGuard = if ($sec.SecurityServicesRunning -contains 2) { "ACTIVE" } else { "INACTIVE" }
        
        Write-Host "  🛡️  Hypervisor Security : " -NoNewline -ForegroundColor DarkGray
        Write-Host "VBS: $vbsStatus" -ForegroundColor $(if($vbsStatus -eq "RUNNING"){"Green"}else{"Red"}) -NoNewline
        Write-Host " | " -NoNewline -ForegroundColor DarkGray
        Write-Host "CredGuard: $credGuard" -ForegroundColor $(if($credGuard -eq "ACTIVE"){"Green"}else{"Yellow"})
    } catch {
        Write-Host "  ⚠️  Cannot read Device Guard status." -ForegroundColor DarkGray
    }

    # 3. Hyper-V Management (Host Only)
    if (Get-Command Get-VM -ErrorAction SilentlyContinue) {
        $vms = Get-VM
        Write-Host "  📦 Local Hyper-V VMs    : " -NoNewline -ForegroundColor DarkGray
        Write-Host $vms.Count -ForegroundColor White
        
        if ($vms) {
            Write-Host "  ──────────────────────────────────────────" -ForegroundColor DarkGray
            foreach ($vm in $vms) {
                $stateColor = if ($vm.State -eq 'Running') { "Green" } else { "DarkGray" }
                Write-Host "     ⚡ $($vm.Name)" -NoNewline -ForegroundColor White
                Write-Host " [$($vm.State)]" -ForegroundColor $stateColor -NoNewline
                Write-Host " (CPU: $($vm.ProcessorCount) | RAM: $([math]::Round($vm.MemoryAssigned/1GB, 1))GB)" -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ""
}

# 24. 🧠 UEFI (Firmware / NVRAM Interaction)
function global:uefi {
    if (-not (Assert-Ring -ReqLevel 2 -CmdName "uefi")) { return }

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "  ❌ Admin rights required to access Firmware Layer." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "  🧠 FIRMWARE INTERFACE (UEFI/NVRAM)" -ForegroundColor Magenta
    Write-Host "  ──────────────────────────────────" -ForegroundColor DarkGray
    
    # Secure Boot Status
    try {
        $sb = Confirm-SecureBootUEFI -ErrorAction Stop
        Write-Host "  🔒 Secure Boot : " -NoNewline -ForegroundColor DarkGray
        if ($sb) { Write-Host "ENABLED (Kernel Protected)" -ForegroundColor Green } else { Write-Host "DISABLED (Kernel Vulnerable)" -ForegroundColor Red }
    } catch {
        Write-Host "  🔒 Secure Boot : " -NoNewline -ForegroundColor DarkGray
        Write-Host "LEGACY BIOS / UNKNOWN" -ForegroundColor Yellow
    }

    # Boot Entries (BCD - Boot Configuration Data)
    Write-Host "  🚀 Boot Manager: " -NoNewline -ForegroundColor DarkGray
    try {
        $bcd = cmd /c bcdedit /enum "{current}"
        $desc = ($bcd | Select-String "description").ToString().Split(" ", 2)[1].Trim()
        $path = ($bcd | Select-String "path").ToString().Split(" ", 2)[1].Trim()
        
        Write-Host "$desc " -NoNewline -ForegroundColor Cyan
        Write-Host "($path)" -ForegroundColor DarkGray
        
        if ($bcd -match "hypervisorlaunchtype\s+Auto") {
            Write-Host "     Type        : " -NoNewline -ForegroundColor DarkGray
            Write-Host "Hypervisor Launch Enabled" -ForegroundColor Green
        }
    } catch { Write-Host "Access Denied" -ForegroundColor Red }

    Write-Host ""
}

# 25. ⚡ VMX (PowerShell Direct - VM Injection)
# Kỹ thuật này sử dụng VMBus để xuyên qua Network Stack, đi thẳng từ Host (Ring 0/Ring 3) vào Guest VM
function global:vmx {
    param(
        [Parameter(Mandatory)][string]$Target,
        [Parameter(Mandatory)][string]$Command
    )
    
    if (-not (Get-Command Invoke-Command -ErrorAction SilentlyContinue)) { return }

    Write-Host ""
    Write-Host "  💉 VMBUS INJECTION PROTOCOL (PowerShell Direct)" -ForegroundColor Cyan
    Write-Host "  ───────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  🎯 Target VM : $Target" -ForegroundColor Yellow
    Write-Host "  📜 Payload   : $Command" -ForegroundColor DarkGray
    
    # Check Credentials
    Write-Host "  🔑 Authenticating via VMBus..." -ForegroundColor DarkGray
    $cred = Get-Credential

    try {
        Write-Host "  🚀 Injecting..." -ForegroundColor Green
        
        # Invoke via VMName bypasses network, uses Hypervisor Bus
        $result = Invoke-Command -VMName $Target -Credential $cred -ScriptBlock { 
            param($c)
            # Execute in Guest context
            Invoke-Expression $c
        } -ArgumentList $Command -ErrorAction Stop
        
        Write-Host "  ✅ Output from Guest:" -ForegroundColor Green
        Write-Host "  ─────────────────────" -ForegroundColor DarkGray
        $result
    } catch {
        Write-Host "  ❌ Injection Failed." -ForegroundColor Red
        Write-Host "     Make sure the VM is Running and supports PowerShell Direct." -ForegroundColor Yellow
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
}

# --- END OF PROFILE ---
Show-StartupBanner
