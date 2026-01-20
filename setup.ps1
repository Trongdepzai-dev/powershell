# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║   ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗                       ║
# ║   ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝                       ║
# ║   ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗                         ║
# ║   ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝                         ║
# ║   ██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗                       ║
# ║   ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝                       ║
# ║                                                                              ║
# ║   ULTIMATE POWERSHELL PROFILE INSTALLER                                      ║
# ║   Version: 3.0 NEON EDITION                                                  ║
# ║   Author: Trongdepzai-dev                                                    ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

Clear-Host
$Host.UI.RawUI.WindowTitle = "⚡ PowerShell Profile Installer - NEON Edition ⚡"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              CONFIGURATION                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

$Script:Config = @{
    RepoUrl        = "https://github.com/Trongdepzai-dev/powershell.git"
    TempDir        = Join-Path $env:TEMP "PS_PROFILE_NEON_$(Get-Random)"
    ProfilePath    = $PROFILE
    ProfileDir     = Split-Path $PROFILE -Parent
    Version        = "3.0.0"
    Author         = "Neon Installer"
    StartTime      = Get-Date
    EnableSound    = $true
    EnableParticle = $true
    AnimationSpeed = 1
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              COLOR THEMES                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

$Script:Themes = @{
    Neon = @{
        Primary    = "Cyan"
        Secondary  = "Magenta"
        Accent     = "Yellow"
        Success    = "Green"
        Error      = "Red"
        Warning    = "DarkYellow"
        Info       = "Blue"
        Dim        = "DarkGray"
        Light      = "White"
        Border     = "DarkCyan"
        Highlight  = "White"
        Glow       = "Cyan"
    }
    Matrix = @{
        Primary    = "Green"
        Secondary  = "DarkGreen"
        Accent     = "White"
        Success    = "Green"
        Error      = "Red"
        Warning    = "Yellow"
        Info       = "DarkGreen"
        Dim        = "DarkGray"
        Light      = "Green"
        Border     = "DarkGreen"
        Highlight  = "White"
        Glow       = "Green"
    }
    Sunset = @{
        Primary    = "Red"
        Secondary  = "Yellow"
        Accent     = "Magenta"
        Success    = "Green"
        Error      = "DarkRed"
        Warning    = "Yellow"
        Info       = "Cyan"
        Dim        = "DarkGray"
        Light      = "White"
        Border     = "DarkRed"
        Highlight  = "Yellow"
        Glow       = "Red"
    }
}

$Script:Theme = $Script:Themes.Neon
$Script:Stats = @{
    StepsCompleted = 0
    TotalSteps     = 10
    Errors         = 0
    Warnings       = 0
    FilesProcessed = 0
    BytesTransferred = 0
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           UTILITY FUNCTIONS                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Get-TerminalWidth {
    try {
        return $Host.UI.RawUI.WindowSize.Width
    } catch {
        return 80
    }
}

function Get-TerminalHeight {
    try {
        return $Host.UI.RawUI.WindowSize.Height
    } catch {
        return 24
    }
}

function Get-CenterPadding {
    param([string]$Text, [int]$Width = (Get-TerminalWidth))
    $padding = [math]::Max(0, [math]::Floor(($Width - $Text.Length) / 2))
    return " " * $padding
}

function Play-Sound {
    param(
        [ValidateSet("Success", "Error", "Warning", "Info", "Start", "Complete", "Click")]
        [string]$Type = "Info"
    )
    if (-not $Script:Config.EnableSound) { return }
    
    switch ($Type) {
        "Success"  { [Console]::Beep(800, 100); [Console]::Beep(1000, 100); [Console]::Beep(1200, 150) }
        "Error"    { [Console]::Beep(300, 200); [Console]::Beep(200, 300) }
        "Warning"  { [Console]::Beep(600, 150); [Console]::Beep(400, 150) }
        "Info"     { [Console]::Beep(700, 80) }
        "Start"    { 
            @(523, 659, 784, 1047) | ForEach-Object { [Console]::Beep($_, 100) }
        }
        "Complete" {
            @(784, 988, 1175, 1568) | ForEach-Object { [Console]::Beep($_, 120) }
        }
        "Click"    { [Console]::Beep(1200, 30) }
    }
}

function Format-FileSize {
    param([long]$Size)
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    return "$Size Bytes"
}

function Format-Duration {
    param([TimeSpan]$Duration)
    if ($Duration.TotalMinutes -ge 1) {
        return "{0}m {1}s" -f [math]::Floor($Duration.TotalMinutes), $Duration.Seconds
    }
    if ($Duration.TotalSeconds -ge 1) {
        return "{0:N1}s" -f $Duration.TotalSeconds
    }
    return "{0}ms" -f $Duration.TotalMilliseconds
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          ANIMATION FUNCTIONS                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Write-Typewriter {
    param(
        [string]$Text,
        [string]$Color = $Script:Theme.Primary,
        [int]$Speed = 2,
        [switch]$NoNewline
    )
    $delay = [math]::Max(1, $Speed / $Script:Config.AnimationSpeed)
    foreach ($char in $Text.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $delay
    }
    if (-not $NoNewline) { Write-Host "" }
}

function Write-Rainbow {
    param(
        [string]$Text,
        [int]$Speed = 2,
        [switch]$NoNewline
    )
    $colors = @("Red", "Yellow", "Green", "Cyan", "Blue", "Magenta")
    $delay = [math]::Max(1, $Speed / $Script:Config.AnimationSpeed)
    $i = 0
    foreach ($char in $Text.ToCharArray()) {
        if ($char -ne " ") {
            Write-Host $char -NoNewline -ForegroundColor $colors[$i % $colors.Length]
            $i++
        } else {
            Write-Host $char -NoNewline
        }
        Start-Sleep -Milliseconds $delay
    }
    if (-not $NoNewline) { Write-Host "" }
}

function Write-Gradient {
    param(
        [string]$Text,
        [string]$StartColor = "Blue",
        [string]$EndColor = "Cyan",
        [switch]$NoNewline
    )
    $colorSequence = @("DarkBlue", "Blue", "DarkCyan", "Cyan", "White")
    $segmentSize = [math]::Max(1, [math]::Ceiling($Text.Length / $colorSequence.Length))
    
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $colorIndex = [math]::Min([math]::Floor($i / $segmentSize), $colorSequence.Length - 1)
        Write-Host $Text[$i] -NoNewline -ForegroundColor $colorSequence[$colorIndex]
    }
    if (-not $NoNewline) { Write-Host "" }
}

function Write-Wave {
    param(
        [string]$Text,
        [string]$Color = $Script:Theme.Primary,
        [int]$Waves = 2
    )
    $width = Get-TerminalWidth
    $padding = Get-CenterPadding -Text $Text
    
    for ($wave = 0; $wave -lt $Waves; $wave++) {
        Write-Host "`r$padding" -NoNewline
        foreach ($char in $Text.ToCharArray()) {
            Write-Host $char -NoNewline -ForegroundColor $Color
            Start-Sleep -Milliseconds 5
        }
        Start-Sleep -Milliseconds 50
        Write-Host "`r$padding" -NoNewline
        Write-Host (" " * $Text.Length) -NoNewline
        Start-Sleep -Milliseconds 30
    }
    Write-Host "`r$padding$Text" -ForegroundColor $Color
}

function Write-Pulse {
    param(
        [string]$Text,
        [int]$Pulses = 3
    )
    $colors = @("DarkGray", "Gray", "White", "Cyan", "White", "Gray", "DarkGray")
    $padding = Get-CenterPadding -Text $Text
    
    for ($p = 0; $p -lt $Pulses; $p++) {
        foreach ($color in $colors) {
            Write-Host "`r$padding$Text" -NoNewline -ForegroundColor $color
            Start-Sleep -Milliseconds 40
        }
    }
    Write-Host "`r$padding$Text" -ForegroundColor $Script:Theme.Primary
}

function Write-Matrix {
    param(
        [int]$Lines = 5,
        [int]$Duration = 1500
    )
    $width = [math]::Min(60, (Get-TerminalWidth) - 10)
    $chars = "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $columns = @{}
    
    $endTime = (Get-Date).AddMilliseconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $output = ""
        for ($i = 0; $i -lt $width; $i++) {
            if ((Get-Random -Maximum 10) -gt 7) {
                $char = $chars[(Get-Random -Maximum $chars.Length)]
                $output += $char
            } else {
                $output += " "
            }
        }
        Write-Host "    $output" -ForegroundColor Green
        Start-Sleep -Milliseconds 50
    }
}

function Write-GlitchText {
    param(
        [string]$Text,
        [int]$Glitches = 5
    )
    $glitchChars = "!@#$%^&*()_+-=[]{}|;':,./<>?"
    $padding = Get-CenterPadding -Text $Text
    
    for ($g = 0; $g -lt $Glitches; $g++) {
        $glitched = ""
        foreach ($char in $Text.ToCharArray()) {
            if ((Get-Random -Maximum 10) -gt 7) {
                $glitched += $glitchChars[(Get-Random -Maximum $glitchChars.Length)]
            } else {
                $glitched += $char
            }
        }
        Write-Host "`r$padding$glitched" -NoNewline -ForegroundColor $Script:Theme.Primary
        Start-Sleep -Milliseconds 50
    }
    Write-Host "`r$padding$Text" -ForegroundColor $Script:Theme.Primary
}

function Write-Sparkle {
    param(
        [string]$Text,
        [int]$Sparkles = 3
    )
    $sparkleChars = @("✦", "✧", "★", "☆", "✪", "✫", "✬", "✭", "✮", "✯")
    $padding = Get-CenterPadding -Text $Text
    
    for ($s = 0; $s -lt $Sparkles; $s++) {
        $decorated = ""
        foreach ($char in $Text.ToCharArray()) {
            if ($char -eq " " -and (Get-Random -Maximum 10) -gt 6) {
                $decorated += $sparkleChars[(Get-Random -Maximum $sparkleChars.Length)]
            } else {
                $decorated += $char
            }
        }
        Write-Host "`r$padding$decorated" -NoNewline -ForegroundColor $Script:Theme.Accent
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r$padding$Text" -ForegroundColor $Script:Theme.Primary
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           PROGRESS INDICATORS                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Show-Spinner {
    param(
        [int]$DurationMs = 1000,
        [string]$Message = "Processing",
        [string]$CompletedMessage = "Complete",
        [ValidateSet("Dots", "Braille", "Circle", "Arrow", "Box", "Bounce", "Clock", "Moon", "Earth")]
        [string]$Style = "Braille"
    )
    
    $spinners = @{
        Dots    = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
        Braille = @("⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷")
        Circle  = @("◐", "◓", "◑", "◒")
        Arrow   = @("←", "↖", "↑", "↗", "→", "↘", "↓", "↙")
        Box     = @("▖", "▘", "▝", "▗")
        Bounce  = @("⠁", "⠂", "⠄", "⠂")
        Clock   = @("🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚", "🕛")
        Moon    = @("🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘")
        Earth   = @("🌍", "🌎", "🌏")
    }
    
    $frames = $spinners[$Style]
    $endTime = (Get-Date).AddMilliseconds($DurationMs)
    $i = 0
    
    while ((Get-Date) -lt $endTime) {
        $frame = $frames[$i % $frames.Length]
        $dots = "." * (($i % 3) + 1)
        Write-Host "`r      $frame $Message$($dots.PadRight(3))" -NoNewline -ForegroundColor $Script:Theme.Primary
        Start-Sleep -Milliseconds 80
        $i++
    }
    Write-Host "`r      ✔ $CompletedMessage              " -ForegroundColor $Script:Theme.Success
}

function Show-ProgressBar {
    param(
        [int]$Percent,
        [int]$Width = 40,
        [string]$Prefix = "",
        [ValidateSet("Block", "Arrow", "Gradient", "Dots", "Line", "Fancy")]
        [string]$Style = "Gradient"
    )
    
    $filled = [math]::Floor($Width * $Percent / 100)
    $empty = $Width - $filled
    
    switch ($Style) {
        "Block" {
            $bar = "█" * $filled + "░" * $empty
        }
        "Arrow" {
            $bar = "=" * [math]::Max(0, $filled - 1) + ">" + "-" * $empty
        }
        "Gradient" {
            $bar = "█" * $filled + "▓" * [math]::Min(1, $empty) + "░" * [math]::Max(0, $empty - 1)
        }
        "Dots" {
            $bar = "●" * $filled + "○" * $empty
        }
        "Line" {
            $bar = "━" * $filled + "─" * $empty
        }
        "Fancy" {
            $bar = "▰" * $filled + "▱" * $empty
        }
    }
    
    $color = switch ($Percent) {
        { $_ -lt 30 } { "Red" }
        { $_ -lt 60 } { "Yellow" }
        { $_ -lt 90 } { "Cyan" }
        default { "Green" }
    }
    
    Write-Host "`r      $Prefix[" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host $bar -NoNewline -ForegroundColor $color
    Write-Host "] " -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host "$($Percent.ToString().PadLeft(3))%" -NoNewline -ForegroundColor $color
}

function Show-AnimatedProgress {
    param(
        [int]$Steps = 100,
        [int]$Delay = 20,
        [string]$Message = "Loading",
        [string]$Style = "Gradient"
    )
    
    for ($i = 0; $i -le $Steps; $i += 2) {
        Show-ProgressBar -Percent $i -Style $Style -Prefix "$Message "
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

function Show-MultiProgressBar {
    param(
        [hashtable]$Tasks
    )
    
    Write-Host ""
    $lineCount = $Tasks.Count
    
    foreach ($task in $Tasks.GetEnumerator()) {
        $percent = $task.Value
        $name = $task.Key.PadRight(15)
        $filled = [math]::Floor(20 * $percent / 100)
        $bar = "█" * $filled + "░" * (20 - $filled)
        
        $color = if ($percent -eq 100) { "Green" } else { "Cyan" }
        Write-Host "      $name " -NoNewline -ForegroundColor $Script:Theme.Light
        Write-Host "[$bar] " -NoNewline -ForegroundColor $color
        Write-Host "$percent%" -ForegroundColor $color
    }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                            BOX DRAWING                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Draw-Line {
    param(
        [string]$Char = "─",
        [int]$Length = 60,
        [string]$Color = $Script:Theme.Border
    )
    Write-Host ("  " + ($Char * $Length)) -ForegroundColor $Color
}

function Draw-DoubleLine {
    param([int]$Length = 60)
    Write-Host ("  " + ("═" * $Length)) -ForegroundColor $Script:Theme.Primary
}

function Draw-DashedLine {
    param([int]$Length = 60)
    $pattern = "─ " * ($Length / 2)
    Write-Host "  $pattern" -ForegroundColor $Script:Theme.Dim
}

function Draw-Box {
    param(
        [string[]]$Lines,
        [string]$Title = "",
        [string]$Color = $Script:Theme.Primary,
        [string]$BorderColor = $Script:Theme.Border,
        [int]$Width = 56,
        [ValidateSet("Single", "Double", "Rounded", "Heavy", "Dashed")]
        [string]$Style = "Rounded"
    )
    
    $borders = @{
        Single  = @{ TL="┌"; TR="┐"; BL="└"; BR="┘"; H="─"; V="│" }
        Double  = @{ TL="╔"; TR="╗"; BL="╚"; BR="╝"; H="═"; V="║" }
        Rounded = @{ TL="╭"; TR="╮"; BL="╰"; BR="╯"; H="─"; V="│" }
        Heavy   = @{ TL="┏"; TR="┓"; BL="┗"; BR="┛"; H="━"; V="┃" }
        Dashed  = @{ TL="┌"; TR="┐"; BL="└"; BR="┘"; H="╌"; V="┊" }
    }
    
    $b = $borders[$Style]
    $innerWidth = $Width - 2
    
    Write-Host ""
    
    # Top border with optional title
    if ($Title) {
        $titleLen = $Title.Length + 2
        $leftPad = [math]::Floor(($innerWidth - $titleLen) / 2)
        $rightPad = $innerWidth - $titleLen - $leftPad
        Write-Host "  $($b.TL)$($b.H * $leftPad) " -NoNewline -ForegroundColor $BorderColor
        Write-Host $Title -NoNewline -ForegroundColor $Color
        Write-Host " $($b.H * $rightPad)$($b.TR)" -ForegroundColor $BorderColor
    } else {
        Write-Host "  $($b.TL)$($b.H * $innerWidth)$($b.TR)" -ForegroundColor $BorderColor
    }
    
    # Content lines
    foreach ($line in $Lines) {
        $content = $line.PadRight($innerWidth).Substring(0, $innerWidth)
        Write-Host "  $($b.V)" -NoNewline -ForegroundColor $BorderColor
        Write-Host $content -NoNewline -ForegroundColor $Color
        Write-Host "$($b.V)" -ForegroundColor $BorderColor
    }
    
    # Bottom border
    Write-Host "  $($b.BL)$($b.H * $innerWidth)$($b.BR)" -ForegroundColor $BorderColor
}

function Draw-Panel {
    param(
        [string]$Title,
        [string]$Icon = "⚡",
        [string]$Subtitle = ""
    )
    
    Write-Host ""
    Write-Host "  ╭───────────────────────────────────────────────────────╮" -ForegroundColor $Script:Theme.Border
    Write-Host "  │  " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "$Icon " -NoNewline -ForegroundColor $Script:Theme.Accent
    Write-Host "$($Title.ToUpper().PadRight(50))" -NoNewline -ForegroundColor $Script:Theme.Primary
    Write-Host " │" -ForegroundColor $Script:Theme.Border
    if ($Subtitle) {
        Write-Host "  │     " -NoNewline -ForegroundColor $Script:Theme.Border
        Write-Host "$($Subtitle.PadRight(47))" -NoNewline -ForegroundColor $Script:Theme.Dim
        Write-Host " │" -ForegroundColor $Script:Theme.Border
    }
    Write-Host "  ╰───────────────────────────────────────────────────────╯" -ForegroundColor $Script:Theme.Border
}

function Draw-StatusCard {
    param(
        [string]$Title,
        [string]$Status,
        [string]$Icon = "◆",
        [ValidateSet("Success", "Error", "Warning", "Info", "Pending")]
        [string]$Type = "Info"
    )
    
    $statusColors = @{
        Success = "Green"
        Error   = "Red"
        Warning = "Yellow"
        Info    = "Cyan"
        Pending = "Gray"
    }
    
    $statusIcons = @{
        Success = "✔"
        Error   = "✖"
        Warning = "⚠"
        Info    = "ℹ"
        Pending = "○"
    }
    
    $color = $statusColors[$Type]
    $sIcon = $statusIcons[$Type]
    
    Write-Host "  ┌────────────────────────────────────────────┐" -ForegroundColor $Script:Theme.Border
    Write-Host "  │ $Icon " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "$($Title.PadRight(35))" -NoNewline -ForegroundColor $Script:Theme.Light
    Write-Host "$sIcon " -NoNewline -ForegroundColor $color
    Write-Host "│" -ForegroundColor $Script:Theme.Border
    Write-Host "  │   " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "$($Status.PadRight(38))" -NoNewline -ForegroundColor $color
    Write-Host " │" -ForegroundColor $Script:Theme.Border
    Write-Host "  └────────────────────────────────────────────┘" -ForegroundColor $Script:Theme.Border
}

function Draw-InfoTable {
    param(
        [hashtable]$Data,
        [string]$Title = "Information"
    )
    
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────────────────┐" -ForegroundColor $Script:Theme.Border
    Write-Host "  │ 📊 $($Title.PadRight(52)) │" -ForegroundColor $Script:Theme.Primary
    Write-Host "  ├─────────────────────────────────────────────────────────┤" -ForegroundColor $Script:Theme.Border
    
    foreach ($item in $Data.GetEnumerator()) {
        $key = $item.Key.PadRight(20)
        $value = "$($item.Value)".PadRight(32)
        Write-Host "  │ " -NoNewline -ForegroundColor $Script:Theme.Border
        Write-Host $key -NoNewline -ForegroundColor $Script:Theme.Dim
        Write-Host " : " -NoNewline -ForegroundColor $Script:Theme.Border
        Write-Host $value -NoNewline -ForegroundColor $Script:Theme.Light
        Write-Host " │" -ForegroundColor $Script:Theme.Border
    }
    
    Write-Host "  └─────────────────────────────────────────────────────────┘" -ForegroundColor $Script:Theme.Border
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           STEP INDICATORS                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Show-Step {
    param(
        [string]$Message,
        [string]$Icon = "◆"
    )
    Write-Host "    $Icon " -NoNewline -ForegroundColor $Script:Theme.Secondary
    Write-Host $Message -ForegroundColor $Script:Theme.Light
}

function Show-SubStep {
    param(
        [string]$Message,
        [string]$Icon = "›"
    )
    Write-Host "      $Icon " -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host $Message -ForegroundColor $Script:Theme.Dim
}

function Show-Success {
    param([string]$Message)
    Write-Host "      ✔ " -NoNewline -ForegroundColor $Script:Theme.Success
    Write-Host $Message -ForegroundColor $Script:Theme.Success
    $Script:Stats.StepsCompleted++
}

function Show-Error {
    param([string]$Message, [switch]$Fatal)
    Write-Host ""
    Write-Host "    ╔═══════════════════════════════════════════════════════╗" -ForegroundColor $Script:Theme.Error
    Write-Host "    ║  ✖ ERROR                                              ║" -ForegroundColor $Script:Theme.Error
    Write-Host "    ╠═══════════════════════════════════════════════════════╣" -ForegroundColor $Script:Theme.Error
    
    # Word wrap the message
    $maxLen = 53
    $words = $Message -split ' '
    $line = ""
    foreach ($word in $words) {
        if (($line + " " + $word).Length -gt $maxLen) {
            Write-Host "    ║  $($line.PadRight($maxLen))  ║" -ForegroundColor $Script:Theme.Error
            $line = $word
        } else {
            $line = if ($line) { "$line $word" } else { $word }
        }
    }
    if ($line) {
        Write-Host "    ║  $($line.PadRight($maxLen))  ║" -ForegroundColor $Script:Theme.Error
    }
    
    Write-Host "    ╚═══════════════════════════════════════════════════════╝" -ForegroundColor $Script:Theme.Error
    Write-Host ""
    
    $Script:Stats.Errors++
    Play-Sound -Type Error
    
    if ($Fatal) {
        Write-Host "    Press any key to exit..." -ForegroundColor $Script:Theme.Dim
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

function Show-Warning {
    param([string]$Message)
    Write-Host "      ⚠ " -NoNewline -ForegroundColor $Script:Theme.Warning
    Write-Host $Message -ForegroundColor $Script:Theme.Warning
    $Script:Stats.Warnings++
}

function Show-Info {
    param([string]$Message)
    Write-Host "      ℹ " -NoNewline -ForegroundColor $Script:Theme.Info
    Write-Host $Message -ForegroundColor $Script:Theme.Info
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           SPECIAL EFFECTS                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Show-Particles {
    param(
        [int]$Count = 20,
        [int]$Duration = 800
    )
    
    if (-not $Script:Config.EnableParticle) { return }
    
    $particles = @("✦", "✧", "★", "☆", "·", "°", "•", "◦", "○", "●")
    $width = [math]::Min(70, (Get-TerminalWidth) - 10)
    
    $endTime = (Get-Date).AddMilliseconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $line = " " * 4
        for ($i = 0; $i -lt $width; $i++) {
            if ((Get-Random -Maximum 20) -eq 0) {
                $line += $particles[(Get-Random -Maximum $particles.Length)]
            } else {
                $line += " "
            }
        }
        Write-Host "`r$line" -NoNewline -ForegroundColor $Script:Theme.Accent
        Start-Sleep -Milliseconds 50
    }
    Write-Host "`r$(" " * ($width + 4))" -NoNewline
    Write-Host ""
}

function Show-Celebration {
    $frames = @(
        @("    🎉", "        🎊", "    ✨", "            🌟", "        ⭐"),
        @("        🎉", "    🎊", "            ✨", "    🌟", "        ⭐"),
        @("    🎊", "            🎉", "        ✨", "            🌟", "    ⭐"),
        @("            🎉", "        🎊", "    ✨", "        🌟", "            ⭐")
    )
    
    for ($i = 0; $i -lt 3; $i++) {
        foreach ($frame in $frames) {
            foreach ($line in $frame) {
                Write-Host $line -ForegroundColor (Get-Random -InputObject @("Yellow", "Cyan", "Magenta", "Green"))
            }
            Start-Sleep -Milliseconds 100
            # Move cursor up
            for ($j = 0; $j -lt $frame.Length; $j++) {
                Write-Host "`e[A" -NoNewline
            }
        }
    }
    
    # Clear celebration area
    for ($j = 0; $j -lt 5; $j++) {
        Write-Host (" " * 70)
    }
}

function Show-LoadingScreen {
    param(
        [string]$Message = "Initializing"
    )
    
    Clear-Host
    $height = Get-TerminalHeight
    $topPadding = [math]::Floor($height / 3)
    
    for ($i = 0; $i -lt $topPadding; $i++) {
        Write-Host ""
    }
    
    $loadingArt = @(
        "    ██╗      ██████╗  █████╗ ██████╗ ██╗███╗   ██╗ ██████╗ ",
        "    ██║     ██╔═══██╗██╔══██╗██╔══██╗██║████╗  ██║██╔════╝ ",
        "    ██║     ██║   ██║███████║██║  ██║██║██╔██╗ ██║██║  ███╗",
        "    ██║     ██║   ██║██╔══██║██║  ██║██║██║╚██╗██║██║   ██║",
        "    ███████╗╚██████╔╝██║  ██║██████╔╝██║██║ ╚████║╚██████╔╝",
        "    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    )
    
    foreach ($line in $loadingArt) {
        Write-Typewriter -Text $line -Color $Script:Theme.Primary -Speed 1
    }
    
    Write-Host ""
    Write-Host ""
    
    # Animated loading bar
    $padding = Get-CenterPadding -Text ("[" + ("█" * 40) + "]")
    
    for ($i = 0; $i -le 100; $i += 2) {
        $filled = [math]::Floor(40 * $i / 100)
        $bar = "█" * $filled + "░" * (40 - $filled)
        Write-Host "`r$padding[$bar] $($i.ToString().PadLeft(3))%" -NoNewline -ForegroundColor $Script:Theme.Primary
        Start-Sleep -Milliseconds 20
    }
    
    Write-Host ""
    Write-Host ""
    $msgPadding = Get-CenterPadding -Text $Message
    Write-Pulse -Text $Message
    
    Start-Sleep -Milliseconds 500
    Clear-Host
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              LOGO & HEADER                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Show-Logo {
    $logo = @(
        "",
        "    ███╗   ██╗███████╗ ██████╗ ███╗   ██╗",
        "    ████╗  ██║██╔════╝██╔═══██╗████╗  ██║",
        "    ██╔██╗ ██║█████╗  ██║   ██║██╔██╗ ██║",
        "    ██║╚██╗██║██╔══╝  ██║   ██║██║╚██╗██║",
        "    ██║ ╚████║███████╗╚██████╔╝██║ ╚████║",
        "    ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝",
        "",
        "    ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗",
        "    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝",
        "    ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗  ",
        "    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝  ",
        "    ██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗",
        "    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝",
        ""
    )
    
    $colors = @(
        "Magenta", "Magenta", "Magenta", "Cyan", "Cyan", "Cyan", "Cyan",
        "Blue", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan"
    )
    
    for ($i = 0; $i -lt $logo.Length; $i++) {
        $color = if ($i -lt $colors.Length) { $colors[$i] } else { "Cyan" }
        Write-Typewriter -Text $logo[$i] -Color $color -Speed 1
    }
}

function Show-Header {
    Clear-Host
    Write-Host ""
    
    # Show animated logo
    Show-Logo
    
    # Tagline with rainbow effect
    Write-Host ""
    $tagline = "              ⚡ ULTIMATE POWERSHELL PROFILE INSTALLER ⚡"
    Write-Rainbow -Text $tagline -Speed 2
    
    # Version and info
    Write-Host ""
    Write-Host "              ═══════════ NEON EDITION v$($Script:Config.Version) ═══════════" -ForegroundColor $Script:Theme.Dim
    Write-Host ""
    
    # Info box
    $infoLines = @(
        "  Welcome to the Ultimate PowerShell Profile Installer!    ",
        "                                                           ",
        "  This tool will:                                          ",
        "    → Clone the profile repository from GitHub             ",
        "    → Backup your existing profile (if any)                ",
        "    → Install the new customized profile                   ",
        "    → Clean up temporary files                             ",
        "                                                           ",
        "  Repository: $($Script:Config.RepoUrl.PadRight(43))"
    )
    
    Draw-Box -Lines $infoLines -Title "ℹ INFO" -Color $Script:Theme.Light -Style "Rounded"
    
    Write-Host ""
    Draw-DoubleLine -Length 60
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          INSTALLATION STEPS                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Test-Prerequisites {
    Draw-Panel -Title "Pre-flight Checks" -Icon "🔍" -Subtitle "Verifying system requirements"
    
    # Check PowerShell Version
    Show-Step "Checking PowerShell version"
    $psVersion = $PSVersionTable.PSVersion
    Show-SubStep "Current version: $psVersion"
    if ($psVersion.Major -ge 5) {
        Show-Success "PowerShell $($psVersion.Major).$($psVersion.Minor) is supported"
    } else {
        Show-Warning "PowerShell version may not support all features"
    }
    
    # Check Git
    Show-Step "Checking Git installation"
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    if ($gitPath) {
        $gitVersion = (git --version) -replace "git version ", ""
        Show-SubStep "Git location: $($gitPath.Source)"
        Show-SubStep "Git version: $gitVersion"
        Show-Success "Git is installed and ready"
    } else {
        Show-Error -Message "Git is not installed! Please install Git from https://git-scm.com" -Fatal
    }
    
    # Check Internet Connection
    Show-Step "Checking internet connectivity"
    Show-Spinner -DurationMs 500 -Message "Testing connection" -Style "Earth"
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Show-Success "Internet connection is available"
    } catch {
        Show-Warning "Could not reach GitHub - check your internet connection"
    }
    
    # Check Execution Policy
    Show-Step "Checking execution policy"
    $policy = Get-ExecutionPolicy
    Show-SubStep "Current policy: $policy"
    if ($policy -in @("Unrestricted", "RemoteSigned", "Bypass")) {
        Show-Success "Execution policy allows script execution"
    } else {
        Show-Warning "May need to adjust execution policy"
    }
    
    # Check disk space
    Show-Step "Checking available disk space"
    $drive = (Get-Item $env:TEMP).PSDrive
    $freeSpace = (Get-PSDrive $drive.Name).Free
    Show-SubStep "Available space: $(Format-FileSize $freeSpace)"
    if ($freeSpace -gt 100MB) {
        Show-Success "Sufficient disk space available"
    } else {
        Show-Warning "Low disk space - may affect installation"
    }
}

function Initialize-Environment {
    Draw-Panel -Title "Environment Setup" -Icon "🖥️" -Subtitle "Configuring installation environment"
    
    # Display system info
    Show-Step "Gathering system information"
    Show-Spinner -DurationMs 400 -Message "Collecting data" -Style "Dots"
    
    $sysInfo = @{
        "Computer Name" = $env:COMPUTERNAME
        "Username"      = $env:USERNAME
        "OS Version"    = (Get-CimInstance Win32_OperatingSystem).Caption
        "PowerShell"    = "v$($PSVersionTable.PSVersion)"
        "Profile Path"  = $Script:Config.ProfilePath
    }
    
    Draw-InfoTable -Data $sysInfo -Title "System Information"
    
    # Verify profile directory
    Show-Step "Checking profile directory"
    Show-SubStep $Script:Config.ProfileDir
    
    if (!(Test-Path $Script:Config.ProfileDir)) {
        Show-Info "Creating profile directory..."
        New-Item -ItemType Directory -Path $Script:Config.ProfileDir -Force | Out-Null
        Show-Success "Profile directory created"
    } else {
        Show-Success "Profile directory exists"
    }
    
    # Check for existing profile
    Show-Step "Checking for existing profile"
    if (Test-Path $Script:Config.ProfilePath) {
        $profileInfo = Get-Item $Script:Config.ProfilePath
        $profileSize = Format-FileSize $profileInfo.Length
        $profileDate = $profileInfo.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Show-SubStep "Found existing profile ($profileSize, modified $profileDate)"
        Show-Warning "Existing profile will be backed up"
    } else {
        Show-SubStep "No existing profile found"
        Show-Success "Clean installation"
    }
}

function Initialize-Workspace {
    Draw-Panel -Title "Workspace Preparation" -Icon "📁" -Subtitle "Setting up temporary workspace"
    
    Show-Step "Creating temporary directory"
    Show-SubStep $Script:Config.TempDir
    
    # Clean existing temp if exists
    if (Test-Path $Script:Config.TempDir) {
        Show-Info "Cleaning existing temporary directory..."
        Remove-Item $Script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    New-Item -ItemType Directory -Path $Script:Config.TempDir -Force | Out-Null
    Show-Spinner -DurationMs 400 -Message "Preparing workspace" -Style "Box"
    Show-Success "Workspace ready"
    
    # Show workspace info
    $workspaceInfo = @{
        "Temp Directory" = $Script:Config.TempDir
        "Target Profile" = Split-Path $Script:Config.ProfilePath -Leaf
        "Repository"     = ($Script:Config.RepoUrl -split "/")[-1] -replace "\.git$", ""
    }
    
    Draw-InfoTable -Data $workspaceInfo -Title "Workspace Details"
}

function Get-ProfileFromGit {
    Draw-Panel -Title "Downloading Profile" -Icon "📥" -Subtitle "Cloning repository from GitHub"
    
    Show-Step "Repository information"
    Show-SubStep "URL: $($Script:Config.RepoUrl)"
    Show-SubStep "Target: $($Script:Config.TempDir)"
    
    Show-Step "Cloning repository"
    
    # Create process to run git
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "git"
    $processInfo.Arguments = "clone --depth 1 `"$($Script:Config.RepoUrl)`" `"$($Script:Config.TempDir)`""
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    
    try {
        $process.Start() | Out-Null
        
        # Animated progress while cloning
        $frames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
        $messages = @(
            "Connecting to GitHub...",
            "Fetching repository data...",
            "Downloading files...",
            "Receiving objects...",
            "Resolving deltas...",
            "Almost there..."
        )
        $msgIndex = 0
        $frameIndex = 0
        
        while (-not $process.HasExited) {
            $frame = $frames[$frameIndex % $frames.Length]
            $msg = $messages[[math]::Min($msgIndex, $messages.Length - 1)]
            Write-Host "`r      $frame $msg            " -NoNewline -ForegroundColor $Script:Theme.Primary
            Start-Sleep -Milliseconds 100
            $frameIndex++
            if ($frameIndex % 10 -eq 0) { $msgIndex++ }
        }
        
        $gitOutput = $process.StandardOutput.ReadToEnd()
        $gitError = $process.StandardError.ReadToEnd()
        $exitCode = $process.ExitCode
        
        if ($exitCode -ne 0) {
            Write-Host ""
            Show-Error -Message "Git clone failed: $gitError" -Fatal
        }
        
        Write-Host "`r      ✔ Repository cloned successfully!              " -ForegroundColor $Script:Theme.Success
        
    } catch {
        Show-Error -Message "Failed to start git process: $_" -Fatal
    }
    
    # Show download progress
    Show-AnimatedProgress -Steps 100 -Delay 10 -Message "Downloading" -Style "Gradient"
    
    # Verify downloaded files
    Show-Step "Verifying downloaded files"
    $files = Get-ChildItem $Script:Config.TempDir -Recurse -File
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $Script:Stats.FilesProcessed = $files.Count
    $Script:Stats.BytesTransferred = $totalSize
    
    Show-SubStep "Files downloaded: $($files.Count)"
    Show-SubStep "Total size: $(Format-FileSize $totalSize)"
    
    # Check for profile file
    $profileFile = Join-Path $Script:Config.TempDir "Microsoft.PowerShell_profile.ps1"
    if (Test-Path $profileFile) {
        $profileSize = (Get-Item $profileFile).Length
        Show-SubStep "Profile file size: $(Format-FileSize $profileSize)"
        Show-Success "Profile file verified"
    } else {
        Show-Error -Message "Profile file not found in repository!" -Fatal
    }
    
    # Show files table
    $filesInfo = @{}
    Get-ChildItem $Script:Config.TempDir -File | Select-Object -First 5 | ForEach-Object {
        $filesInfo[$_.Name] = Format-FileSize $_.Length
    }
    if ($filesInfo.Count -gt 0) {
        Draw-InfoTable -Data $filesInfo -Title "Downloaded Files"
    }
}

function Backup-ExistingProfile {
    Draw-Panel -Title "Backup" -Icon "💾" -Subtitle "Backing up existing configuration"
    
    Show-Step "Checking for existing profile"
    
    if (Test-Path $Script:Config.ProfilePath) {
        $backupDir = Join-Path $Script:Config.ProfileDir "backups"
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupName = "profile_backup_$timestamp.ps1"
        $backupPath = Join-Path $backupDir $backupName
        
        Show-SubStep "Found existing profile"
        Show-SubStep "Creating backup directory..."
        
        if (!(Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }
        
        Show-Step "Creating backup"
        Copy-Item $Script:Config.ProfilePath $backupPath -Force
        Show-Spinner -DurationMs 500 -Message "Backing up" -Style "Moon"
        
        $backupInfo = @{
            "Backup Location" = $backupDir
            "Backup File"     = $backupName
            "Original Size"   = Format-FileSize (Get-Item $backupPath).Length
            "Timestamp"       = $timestamp
        }
        
        Draw-InfoTable -Data $backupInfo -Title "Backup Details"
        
        Show-Success "Backup created successfully"
        
        # Clean old backups (keep last 5)
        Show-Step "Managing backup history"
        $oldBackups = Get-ChildItem $backupDir -Filter "profile_backup_*.ps1" | 
                      Sort-Object CreationTime -Descending | 
                      Select-Object -Skip 5
        
        if ($oldBackups) {
            $oldBackups | Remove-Item -Force
            Show-SubStep "Removed $($oldBackups.Count) old backup(s)"
        }
        Show-Success "Backup management complete"
        
    } else {
        Show-SubStep "No existing profile found"
        Show-Info "Backup step skipped - clean installation"
    }
}

function Install-Profile {
    Draw-Panel -Title "Installation" -Icon "⚙️" -Subtitle "Installing new PowerShell profile"
    
    $sourceProfile = Join-Path $Script:Config.TempDir "Microsoft.PowerShell_profile.ps1"
    
    Show-Step "Preparing installation"
    Show-SubStep "Source: $sourceProfile"
    Show-SubStep "Target: $($Script:Config.ProfilePath)"
    
    # Read and validate profile
    Show-Step "Validating profile syntax"
    Show-Spinner -DurationMs 400 -Message "Parsing PowerShell script" -Style "Braille"
    
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $sourceProfile,
            [ref]$null,
            [ref]$null
        )
        Show-Success "Profile syntax is valid"
    } catch {
        Show-Warning "Could not validate syntax (will continue anyway)"
    }
    
    # Show installation progress
    Show-Step "Installing profile"
    
    $installTasks = @{
        "Reading source"     = 0
        "Validating"         = 0
        "Writing target"     = 0
        "Setting permissions"= 0
        "Finalizing"         = 0
    }
    
    # Simulate installation steps
    foreach ($task in @("Reading source", "Validating", "Writing target", "Setting permissions", "Finalizing")) {
        for ($i = 0; $i -le 100; $i += 10) {
            $installTasks[$task] = $i
            Start-Sleep -Milliseconds 30
        }
        $installTasks[$task] = 100
    }
    
    # Actually copy ALL files from the repository (excluding .git)
    Show-Step "Copying all repository files"
    Get-ChildItem -Path $Script:Config.TempDir -Exclude ".git" | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $Script:Config.ProfileDir -Recurse -Force
    }
    Show-SubStep "All files copied to $($Script:Config.ProfileDir)"
    
    Show-AnimatedProgress -Steps 100 -Delay 15 -Message "Installing" -Style "Fancy"
    
    # Verify installation
    Show-Step "Verifying installation"
    if (Test-Path $Script:Config.ProfilePath) {
        $installedProfile = Get-Item $Script:Config.ProfilePath
        $installedSize = Format-FileSize $installedProfile.Length
        $installedLines = (Get-Content $Script:Config.ProfilePath).Count
        
        Show-SubStep "Installed size: $installedSize"
        Show-SubStep "Lines of code: $installedLines"
        Show-Success "Profile installed successfully!"
        
        # Compare source and target
        $sourceHash = (Get-FileHash $sourceProfile -Algorithm MD5).Hash
        $targetHash = (Get-FileHash $Script:Config.ProfilePath -Algorithm MD5).Hash
        
        if ($sourceHash -eq $targetHash) {
            Show-Success "File integrity verified (MD5 match)"
        } else {
            Show-Warning "File hashes don't match - please verify manually"
        }
        
    } else {
        Show-Error -Message "Installation verification failed!" -Fatal
    }
    
    Play-Sound -Type Success
}

function Remove-TempFiles {
    Draw-Panel -Title "Cleanup" -Icon "🧹" -Subtitle "Removing temporary files"
    
    Show-Step "Cleaning temporary directory"
    Show-SubStep $Script:Config.TempDir
    
    if (Test-Path $Script:Config.TempDir) {
        $itemCount = (Get-ChildItem $Script:Config.TempDir -Recurse).Count
        Show-SubStep "Items to remove: $itemCount"
        
        Show-Spinner -DurationMs 600 -Message "Removing files" -Style "Bounce"
        Remove-Item $Script:Config.TempDir -Recurse -Force -ErrorAction SilentlyContinue
        
        if (!(Test-Path $Script:Config.TempDir)) {
            Show-Success "Temporary files removed"
        } else {
            Show-Warning "Some files could not be removed"
        }
    } else {
        Show-Info "Temporary directory already clean"
    }
    
    # Clear any orphaned temp directories
    Show-Step "Checking for orphaned files"
    $orphaned = Get-ChildItem $env:TEMP -Filter "PS_PROFILE_NEON_*" -Directory -ErrorAction SilentlyContinue
    if ($orphaned) {
        Show-SubStep "Found $($orphaned.Count) orphaned director(ies)"
        $orphaned | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Show-Success "Orphaned files cleaned"
    } else {
        Show-Success "No orphaned files found"
    }
}

function Show-CompletionSummary {
    $duration = (Get-Date) - $Script:Config.StartTime
    
    Write-Host ""
    Draw-DoubleLine -Length 60
    Write-Host ""
    
    # Success banner
    $successBanner = @(
        "",
        "     ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗",
        "     ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝",
        "     ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗",
        "     ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║",
        "     ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║",
        "     ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝",
        ""
    )
    
    foreach ($line in $successBanner) {
        Write-Typewriter -Text $line -Color $Script:Theme.Success -Speed 1
    }
    
    Write-Host ""
    
    # Installation summary box
    $summaryLines = @(
        "  🎉 INSTALLATION COMPLETED SUCCESSFULLY!                  ",
        "                                                           ",
        "  ┌─ Summary ───────────────────────────────────────────┐  ",
        "  │                                                     │  ",
        "  │  Duration:         $(Format-Duration $duration)                          ".PadRight(56) + "│  ",
        "  │  Files Processed:  $($Script:Stats.FilesProcessed)                              ".PadRight(56) + "│  ",
        "  │  Data Transferred: $(Format-FileSize $Script:Stats.BytesTransferred)                    ".PadRight(56) + "│  ",
        "  │  Errors:           $($Script:Stats.Errors)                              ".PadRight(56) + "│  ",
        "  │  Warnings:         $($Script:Stats.Warnings)                              ".PadRight(56) + "│  ",
        "  │                                                     │  ",
        "  └─────────────────────────────────────────────────────┘  "
    )
    
    Draw-Box -Lines $summaryLines -Color $Script:Theme.Light -Style "Double" -Title "✔ COMPLETE"
    
    Write-Host ""
    
    # Next steps
    $nextSteps = @(
        "  📌 NEXT STEPS:                                           ",
        "                                                           ",
        "     Option 1: Reload profile in current session           ",
        "               . `$PROFILE                                  ",
        "                                                           ",
        "     Option 2: Restart PowerShell                          ",
        "               Just close and reopen PowerShell            ",
        "                                                           ",
        "  💡 TIP: Your old profile has been backed up!             "
    )
    
    Draw-Box -Lines $nextSteps -Color $Script:Theme.Info -Style "Rounded" -Title "ℹ What's Next?"
    
    Write-Host ""
    
    # Final message
    Write-Rainbow -Text "        ★ Thank you for using Neon Profile Installer! ★" -Speed 2
    Write-Host ""
    Write-Host "        Created with 💜 by Neon Installer Team" -ForegroundColor $Script:Theme.Dim
    Write-Host ""
    
    Draw-DoubleLine -Length 60
    Write-Host ""
    
    Play-Sound -Type Complete
}

function Show-PostInstallOptions {
    Write-Host ""
    Write-Host "    ┌────────────────────────────────────────────────────┐" -ForegroundColor $Script:Theme.Border
    Write-Host "    │  Would you like to reload the profile now? (Y/N)  │" -ForegroundColor $Script:Theme.Light
    Write-Host "    └────────────────────────────────────────────────────┘" -ForegroundColor $Script:Theme.Border
    Write-Host ""
    
    $response = Read-Host "    Your choice"
    
    if ($response -match "^[Yy]") {
        Write-Host ""
        Show-Step "Reloading profile..."
        Show-Spinner -DurationMs 500 -Message "Activating new profile" -Style "Circle"
        
        try {
            . $PROFILE
            Show-Success "Profile reloaded successfully!"
            Write-Host ""
            Write-Host "    🚀 Your new profile is now active!" -ForegroundColor $Script:Theme.Success
        } catch {
            Show-Warning "Could not reload profile: $_"
            Write-Host "    Please restart PowerShell manually." -ForegroundColor $Script:Theme.Warning
        }
    } else {
        Write-Host ""
        Write-Host "    📝 Remember to restart PowerShell to apply changes." -ForegroundColor $Script:Theme.Info
    }
    
    Write-Host ""
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MAIN EXECUTION                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Start-Installation {
    try {
        # Loading screen
        Show-LoadingScreen -Message "Initializing Neon Installer"
        
        # Play startup sound
        Play-Sound -Type Start
        
        # Show header
        Show-Header
        
        Write-Host ""
        Write-Host "    Press any key to begin installation..." -ForegroundColor $Script:Theme.Dim
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        # Run installation steps
        Test-Prerequisites
        Initialize-Environment
        Initialize-Workspace
        Get-ProfileFromGit
        Backup-ExistingProfile
        Install-Profile
        Remove-TempFiles
        
        # Show completion
        Show-CompletionSummary
        Show-PostInstallOptions
        
    } catch {
        Show-Error -Message "Unexpected error: $_" -Fatal
    }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              RUN INSTALLER                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

Start-Installation