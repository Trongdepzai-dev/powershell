# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗                      ║
# ║   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║                      ║
# ║   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║                      ║
# ║   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║                      ║
# ║   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║                      ║
# ║   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝                      ║
# ║                                                                              ║
# ║   ██╗███╗   ██╗███████╗ ██████╗                                              ║
# ║   ██║████╗  ██║██╔════╝██╔═══██╗                                             ║
# ║   ██║██╔██╗ ██║█████╗  ██║   ██║                                             ║
# ║   ██║██║╚██╗██║██╔══╝  ██║   ██║                                             ║
# ║   ██║██║ ╚████║██║     ╚██████╔╝                                             ║
# ║   ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝                                              ║
# ║                                                                              ║
# ║   ULTIMATE SYSTEM INFORMATION DASHBOARD                                      ║
# ║   Version: 3.1 PRO MAX EDITION                                               ║
# ║                                                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

Clear-Host
$Host.UI.RawUI.WindowTitle = "⚡ System Information Dashboard - PRO MAX Edition ⚡"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              CONFIGURATION                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

$Script:Config = @{
    Version        = "3.1.0"
    Author         = "Neon Dashboard"
    StartTime      = Get-Date
    EnableSound    = $true
    EnableParticle = $true
    AnimationSpeed = 1
    RefreshRate    = 5
    ShowDetailed   = $true
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              COLOR THEMES                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

$Script:Themes = @{
    Neon = @{
        Primary     = "Cyan"
        Secondary   = "Magenta"
        Tertiary    = "Yellow"
        Accent      = "White"
        Success     = "Green"
        Error       = "Red"
        Warning     = "DarkYellow"
        Info        = "Blue"
        Dim         = "DarkGray"
        Light       = "White"
        Border      = "DarkCyan"
        Highlight   = "White"
        Glow        = "Cyan"
        CPU         = "Yellow"
        RAM         = "Magenta"
        Disk        = "Green"
        Network     = "Cyan"
        GPU         = "Red"
    }
    Matrix = @{
        Primary     = "Green"
        Secondary   = "DarkGreen"
        Tertiary    = "White"
        Accent      = "Green"
        Success     = "Green"
        Error       = "Red"
        Warning     = "Yellow"
        Info        = "DarkGreen"
        Dim         = "DarkGray"
        Light       = "Green"
        Border      = "DarkGreen"
        Highlight   = "White"
        Glow        = "Green"
        CPU         = "Green"
        RAM         = "Green"
        Disk        = "Green"
        Network     = "Green"
        GPU         = "Green"
    }
    Cyberpunk = @{
        Primary     = "Magenta"
        Secondary   = "Cyan"
        Tertiary    = "Yellow"
        Accent      = "White"
        Success     = "Cyan"
        Error       = "Red"
        Warning     = "Yellow"
        Info        = "Magenta"
        Dim         = "DarkGray"
        Light       = "White"
        Border      = "DarkMagenta"
        Highlight   = "Yellow"
        Glow        = "Magenta"
        CPU         = "Cyan"
        RAM         = "Magenta"
        Disk        = "Yellow"
        Network     = "Cyan"
        GPU         = "Red"
    }
}

$Script:Theme = $Script:Themes.Neon

# System data cache
$Script:SystemData = @{
    OS          = $null
    Computer    = $null
    CPU         = $null
    BIOS        = $null
    GPU         = $null
    Memory      = $null
    Disks       = $null
    Network     = $null
    Processes   = $null
    Services    = $null
    BaseBoard   = $null
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

function Format-FileSize {
    param([double]$Size)
    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    return "$Size Bytes"
}

function Format-Frequency {
    param([double]$MHz)
    if ($MHz -ge 1000) {
        return "{0:N2} GHz" -f ($MHz / 1000)
    }
    return "$MHz MHz"
}

function Format-Uptime {
    param([TimeSpan]$Duration)
    $parts = @()
    if ($Duration.Days -gt 0) { $parts += "$($Duration.Days)d" }
    if ($Duration.Hours -gt 0) { $parts += "$($Duration.Hours)h" }
    if ($Duration.Minutes -gt 0) { $parts += "$($Duration.Minutes)m" }
    if ($Duration.Seconds -gt 0 -or $parts.Count -eq 0) { $parts += "$($Duration.Seconds)s" }
    return $parts -join " "
}

function Get-PercentageColor {
    param(
        [double]$Percent,
        [switch]$Inverted
    )
    if ($Inverted) {
        if ($Percent -ge 70) { return "Green" }
        if ($Percent -ge 40) { return "Yellow" }
        return "Red"
    } else {
        if ($Percent -ge 90) { return "Red" }
        if ($Percent -ge 70) { return "Yellow" }
        return "Green"
    }
}

function Play-Sound {
    param(
        [ValidateSet("Success", "Error", "Warning", "Info", "Start", "Complete", "Scan", "Alert")]
        [string]$Type = "Info"
    )
    if (-not $Script:Config.EnableSound) { return }
    
    try {
        switch ($Type) {
            "Success"  { [Console]::Beep(800, 100); [Console]::Beep(1000, 100); [Console]::Beep(1200, 150) }
            "Error"    { [Console]::Beep(300, 200); [Console]::Beep(200, 300) }
            "Warning"  { [Console]::Beep(600, 150); [Console]::Beep(400, 150) }
            "Info"     { [Console]::Beep(700, 80) }
            "Start"    { @(523, 659, 784, 1047) | ForEach-Object { [Console]::Beep($_, 80) } }
            "Complete" { @(784, 988, 1175, 1568) | ForEach-Object { [Console]::Beep($_, 100) } }
            "Scan"     { [Console]::Beep(500, 50); [Console]::Beep(700, 50); [Console]::Beep(900, 50) }
            "Alert"    { 1..3 | ForEach-Object { [Console]::Beep(1000, 100); Start-Sleep -Milliseconds 50 } }
        }
    } catch {}
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
        [string[]]$Colors = @("Blue", "Cyan", "Green"),
        [switch]$NoNewline
    )
    $segmentSize = [math]::Max(1, [math]::Ceiling($Text.Length / $Colors.Length))
    
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $colorIndex = [math]::Min([math]::Floor($i / $segmentSize), $Colors.Length - 1)
        Write-Host $Text[$i] -NoNewline -ForegroundColor $Colors[$colorIndex]
    }
    if (-not $NoNewline) { Write-Host "" }
}

function Write-Pulse {
    param(
        [string]$Text,
        [string]$Color = $Script:Theme.Primary,
        [int]$Pulses = 2
    )
    $pulseColors = @("DarkGray", "Gray", $Color, "White", $Color, "Gray", "DarkGray")
    
    for ($p = 0; $p -lt $Pulses; $p++) {
        foreach ($c in $pulseColors) {
            Write-Host "`r$Text" -NoNewline -ForegroundColor $c
            Start-Sleep -Milliseconds 40
        }
    }
    Write-Host "`r$Text" -ForegroundColor $Color
}

function Write-Glitch {
    param(
        [string]$Text,
        [string]$Color = $Script:Theme.Primary,
        [int]$Glitches = 3
    )
    $glitchChars = "!@#$%^&*()_+-=[]{}|;':,./<>?█▓▒░"
    
    for ($g = 0; $g -lt $Glitches; $g++) {
        $glitched = ""
        foreach ($char in $Text.ToCharArray()) {
            if ((Get-Random -Maximum 10) -gt 7) {
                $glitched += $glitchChars[(Get-Random -Maximum $glitchChars.Length)]
            } else {
                $glitched += $char
            }
        }
        Write-Host "`r$glitched" -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds 50
    }
    Write-Host "`r$Text" -ForegroundColor $Color
}

function Write-Scan {
    param(
        [string]$Text,
        [string]$Color = $Script:Theme.Primary
    )
    $length = $Text.Length
    
    for ($i = 0; $i -le $length; $i++) {
        $visible = $Text.Substring(0, $i)
        $hidden = "█" * ($length - $i)
        Write-Host "`r$visible$hidden" -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds 15
    }
    Write-Host ""
}

function Write-Matrix {
    param(
        [int]$Width = 50,
        [int]$Lines = 3,
        [int]$Duration = 500
    )
    $chars = "01アイウエオカキクケコサシスセソタチツテト"
    $endTime = (Get-Date).AddMilliseconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $line = "    "
        for ($i = 0; $i -lt $Width; $i++) {
            if ((Get-Random -Maximum 8) -eq 0) {
                $line += $chars[(Get-Random -Maximum $chars.Length)]
            } else {
                $line += " "
            }
        }
        Write-Host $line -ForegroundColor Green
        Start-Sleep -Milliseconds 30
    }
}

function Write-Particles {
    param(
        [int]$Width = 60,
        [int]$Duration = 400
    )
    $particles = @("✦", "✧", "★", "☆", "·", "°", "•", "◦", "○", "●", "◇", "◆")
    $endTime = (Get-Date).AddMilliseconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $line = "    "
        for ($i = 0; $i -lt $Width; $i++) {
            if ((Get-Random -Maximum 15) -eq 0) {
                $line += $particles[(Get-Random -Maximum $particles.Length)]
            } else {
                $line += " "
            }
        }
        $colors = @("Cyan", "Magenta", "Yellow", "White")
        Write-Host "`r$line" -NoNewline -ForegroundColor $colors[(Get-Random -Maximum $colors.Length)]
        Start-Sleep -Milliseconds 40
    }
    Write-Host "`r$(" " * ($Width + 4))"
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           PROGRESS INDICATORS                                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Show-Spinner {
    param(
        [int]$DurationMs = 500,
        [string]$Message = "Loading",
        [string]$CompletedMessage = "Done",
        [ValidateSet("Dots", "Braille", "Circle", "Arrow", "Box", "Bounce", "Clock", "Moon", "Earth", "Scan", "Bar", "Pulse")]
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
        Scan    = @("▱▱▱▱▱", "▰▱▱▱▱", "▰▰▱▱▱", "▰▰▰▱▱", "▰▰▰▰▱", "▰▰▰▰▰", "▱▰▰▰▰", "▱▱▰▰▰", "▱▱▱▰▰", "▱▱▱▱▰")
        Bar     = @("[    ]", "[=   ]", "[==  ]", "[=== ]", "[====]", "[ ===]", "[  ==]", "[   =]")
        Pulse   = @("○", "◔", "◑", "◕", "●", "◕", "◑", "◔")
    }
    
    $frames = $spinners[$Style]
    $endTime = (Get-Date).AddMilliseconds($DurationMs)
    $i = 0
    
    while ((Get-Date) -lt $endTime) {
        $frame = $frames[$i % $frames.Length]
        Write-Host "`r    $frame $Message..." -NoNewline -ForegroundColor $Script:Theme.Primary
        Start-Sleep -Milliseconds 80
        $i++
    }
    Write-Host "`r    ✔ $CompletedMessage              " -ForegroundColor $Script:Theme.Success
}

function Show-ProgressBar {
    param(
        [double]$Percent,
        [int]$Width = 40,
        [string]$Label = "",
        [ValidateSet("Block", "Arrow", "Gradient", "Dots", "Line", "Fancy", "Neon", "Fire")]
        [string]$Style = "Gradient",
        [switch]$NoNewline
    )
    
    $safePercent = [math]::Min(100, [math]::Max(0, $Percent))
    $filled = [math]::Floor($Width * $safePercent / 100)
    $empty = $Width - $filled
    
    switch ($Style) {
        "Block"    { $bar = "█" * $filled + "░" * $empty }
        "Arrow"    { $bar = "=" * [math]::Max(0, $filled - 1) + ">" + "-" * $empty }
        "Gradient" { $bar = "█" * $filled + "▓" * [math]::Min(1, $empty) + "░" * [math]::Max(0, $empty - 1) }
        "Dots"     { $bar = "●" * $filled + "○" * $empty }
        "Line"     { $bar = "━" * $filled + "─" * $empty }
        "Fancy"    { $bar = "▰" * $filled + "▱" * $empty }
        "Neon"     { $bar = "▓" * $filled + "░" * $empty }
        "Fire"     { $bar = "🔥" * [math]::Floor($filled/2) + "▒" * ($Width - [math]::Floor($filled/2)) }
    }
    
    $color = Get-PercentageColor -Percent $safePercent
    
    $labelPart = if ($Label) { "$Label " } else { "" }
    Write-Host "    $labelPart[" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host $bar -NoNewline -ForegroundColor $color
    Write-Host "] " -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host "$([math]::Round($safePercent, 1))%" -NoNewline -ForegroundColor $color
    
    if (-not $NoNewline) { Write-Host "" }
}

function Show-AnimatedProgress {
    param(
        [int]$Steps = 100,
        [int]$Delay = 20,
        [string]$Message = "Loading",
        [string]$Style = "Gradient"
    )
    
    for ($i = 0; $i -le $Steps; $i += 3) {
        Write-Host "`r" -NoNewline
        Show-ProgressBar -Percent $i -Style $Style -Label $Message -NoNewline
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

function Show-MultiBar {
    param(
        [string]$Label,
        [double]$Used,
        [double]$Total,
        [string]$UsedLabel = "Used",
        [string]$FreeLabel = "Free",
        [int]$Width = 30
    )
    
    $percent = if ($Total -gt 0) { ($Used / $Total) * 100 } else { 0 }
    $color = Get-PercentageColor -Percent $percent
    
    $filled = [math]::Floor($Width * $percent / 100)
    $bar = "█" * $filled + "░" * ($Width - $filled)
    
    Write-Host "    $($Label.PadRight(12)) [" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host $bar -NoNewline -ForegroundColor $color
    Write-Host "] " -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host "$([math]::Round($percent, 1))%" -ForegroundColor $color
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                            BOX DRAWING                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Draw-Line {
    param(
        [string]$Char = "─",
        [int]$Length = 65,
        [string]$Color = $Script:Theme.Border
    )
    Write-Host ("  " + ($Char * $Length)) -ForegroundColor $Color
}

function Draw-DoubleLine {
    param([int]$Length = 65)
    Write-Host ("  " + ("═" * $Length)) -ForegroundColor $Script:Theme.Primary
}

function Draw-SectionHeader {
    param(
        [string]$Title,
        [string]$Icon = "◆",
        [string]$Color = $Script:Theme.Primary,
        [int]$Width = 65
    )
    
    $titleLength = $Icon.Length + $Title.Length + 4
    $lineLength = $Width - $titleLength - 2
    
    Write-Host ""
    Write-Host "  ┌─ $Icon " -NoNewline -ForegroundColor $Color
    Write-Host $Title -NoNewline -ForegroundColor $Script:Theme.Light
    Write-Host " $("─" * $lineLength)┐" -ForegroundColor $Color
}

function Draw-SectionFooter {
    param(
        [string]$Color = $Script:Theme.Primary,
        [int]$Width = 65
    )
    Write-Host "  └$("─" * ($Width - 2))┘" -ForegroundColor $Color
}

function Draw-SectionLine {
    param(
        [string]$Color = $Script:Theme.Primary
    )
    Write-Host "  │" -ForegroundColor $Color
}

function Draw-InfoLine {
    param(
        [string]$Label,
        [string]$Value,
        [string]$LabelColor = "DarkGray",
        [string]$ValueColor = "White",
        [string]$BorderColor = $Script:Theme.Primary,
        [string]$Icon = ""
    )
    
    $iconPart = if ($Icon) { "$Icon " } else { "" }
    Write-Host "  │  $iconPart$($Label.PadRight(14)): " -NoNewline -ForegroundColor $LabelColor
    Write-Host $Value -ForegroundColor $ValueColor
}

function Draw-Panel {
    param(
        [string]$Title,
        [string]$Icon = "⚡",
        [string]$Subtitle = "",
        [string]$Color = $Script:Theme.Primary
    )
    
    Write-Host ""
    Write-Host "  ╭───────────────────────────────────────────────────────────────╮" -ForegroundColor $Script:Theme.Border
    Write-Host "  │  " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "$Icon " -NoNewline -ForegroundColor $Script:Theme.Accent
    Write-Host "$($Title.ToUpper().PadRight(58))" -NoNewline -ForegroundColor $Color
    Write-Host " │" -ForegroundColor $Script:Theme.Border
    if ($Subtitle) {
        Write-Host "  │     " -NoNewline -ForegroundColor $Script:Theme.Border
        Write-Host "$($Subtitle.PadRight(55))" -NoNewline -ForegroundColor $Script:Theme.Dim
        Write-Host " │" -ForegroundColor $Script:Theme.Border
    }
    Write-Host "  ╰───────────────────────────────────────────────────────────────╯" -ForegroundColor $Script:Theme.Border
}

function Draw-Box {
    param(
        [string[]]$Lines,
        [string]$Title = "",
        [string]$Color = $Script:Theme.Primary,
        [string]$BorderColor = $Script:Theme.Border,
        [int]$Width = 65,
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
    
    foreach ($line in $Lines) {
        $content = $line.PadRight($innerWidth).Substring(0, [math]::Min($line.Length, $innerWidth)).PadRight($innerWidth)
        Write-Host "  $($b.V)" -NoNewline -ForegroundColor $BorderColor
        Write-Host $content -NoNewline -ForegroundColor $Color
        Write-Host "$($b.V)" -ForegroundColor $BorderColor
    }
    
    Write-Host "  $($b.BL)$($b.H * $innerWidth)$($b.BR)" -ForegroundColor $BorderColor
}

function Draw-StatusBadge {
    param(
        [string]$Text,
        [ValidateSet("Success", "Error", "Warning", "Info", "Primary")]
        [string]$Type = "Primary"
    )
    
    $colors = @{
        Success = "Green"
        Error   = "Red"
        Warning = "Yellow"
        Info    = "Cyan"
        Primary = "Magenta"
    }
    
    $icons = @{
        Success = "✔"
        Error   = "✖"
        Warning = "⚠"
        Info    = "ℹ"
        Primary = "●"
    }
    
    Write-Host " [$($icons[$Type]) $Text] " -NoNewline -ForegroundColor $colors[$Type]
}

function Draw-Gauge {
    param(
        [string]$Label,
        [double]$Value,
        [double]$Max = 100,
        [string]$Unit = "%",
        [int]$Width = 20
    )
    
    $percent = if ($Max -gt 0) { ($Value / $Max) * 100 } else { 0 }
    $color = Get-PercentageColor -Percent $percent
    
    $filled = [math]::Floor($Width * $percent / 100)
    $gauge = "▰" * $filled + "▱" * ($Width - $filled)
    
    Write-Host "  │  " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "$($Label.PadRight(10))" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host " $gauge " -NoNewline -ForegroundColor $color
    Write-Host "$([math]::Round($Value, 1))$Unit" -ForegroundColor $color
}

function Draw-MiniChart {
    param(
        [double[]]$Values,
        [int]$Height = 5,
        [string]$Color = $Script:Theme.Primary
    )
    
    $max = ($Values | Measure-Object -Maximum).Maximum
    if ($max -eq 0) { $max = 1 }
    
    $blocks = @("▁", "▂", "▃", "▄", "▅", "▆", "▇", "█")
    
    Write-Host "    " -NoNewline
    foreach ($value in $Values) {
        $normalized = ($value / $max) * ($blocks.Length - 1)
        $blockIndex = [math]::Min([math]::Floor($normalized), $blocks.Length - 1)
        Write-Host $blocks[$blockIndex] -NoNewline -ForegroundColor $Color
    }
    Write-Host ""
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          DATA COLLECTION                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Get-SystemData {
    param([switch]$Force)
    
    if ($Force -or -not $Script:SystemData.OS) {
        $Script:SystemData.OS = Get-CimInstance Win32_OperatingSystem
    }
    if ($Force -or -not $Script:SystemData.Computer) {
        $Script:SystemData.Computer = Get-CimInstance Win32_ComputerSystem
    }
    if ($Force -or -not $Script:SystemData.CPU) {
        $Script:SystemData.CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
    }
    if ($Force -or -not $Script:SystemData.BIOS) {
        $Script:SystemData.BIOS = Get-CimInstance Win32_BIOS
    }
    if ($Force -or -not $Script:SystemData.GPU) {
        $Script:SystemData.GPU = Get-CimInstance Win32_VideoController | Select-Object -First 1
    }
    if ($Force -or -not $Script:SystemData.BaseBoard) {
        $Script:SystemData.BaseBoard = Get-CimInstance Win32_BaseBoard
    }
    
    return $Script:SystemData
}

function Get-LiveCPULoad {
    return (Get-CimInstance Win32_Processor).LoadPercentage
}

function Get-LiveMemory {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem
    
    $totalBytes = $cs.TotalPhysicalMemory
    $freeBytes = $os.FreePhysicalMemory * 1024
    $usedBytes = $totalBytes - $freeBytes
    
    return @{
        Total   = $totalBytes
        Used    = $usedBytes
        Free    = $freeBytes
        Percent = if ($totalBytes -gt 0) { [math]::Round(($usedBytes / $totalBytes) * 100, 1) } else { 0 }
    }
}

function Get-DriveInfo {
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    $result = @()
    
    foreach ($drive in $drives) {
        $total = $drive.Used + $drive.Free
        $result += @{
            Name    = $drive.Name
            Total   = $total
            Used    = $drive.Used
            Free    = $drive.Free
            Percent = if ($total -gt 0) { [math]::Round(($drive.Used / $total) * 100, 1) } else { 0 }
        }
    }
    
    return $result
}

function Get-NetworkInfo {
    $adapters = Get-NetAdapter | Where-Object Status -eq 'Up'
    $result = @()
    
    foreach ($adapter in $adapters) {
        $stats = Get-NetAdapterStatistics -Name $adapter.Name -ErrorAction SilentlyContinue
        
        $ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction SilentlyContinue
        $ipv4 = if ($ipConfig.IPv4Address) { $ipConfig.IPv4Address.IPAddress } else { "N/A" }
        $ipv6 = if ($ipConfig.IPv6Address) { $ipConfig.IPv6Address.IPAddress } else { "N/A" }
        
        $result += @{
            Name          = $adapter.Name
            Status        = $adapter.Status
            Speed         = $adapter.LinkSpeed
            MAC           = $adapter.MacAddress
            BytesSent     = if ($stats) { $stats.SentBytes } else { 0 }
            BytesReceived = if ($stats) { $stats.ReceivedBytes } else { 0 }
            IPv4          = $ipv4
            IPv6          = $ipv6
        }
    }
    
    return $result
}

function Get-ExternalIP {
    try {
        $ip = Invoke-RestMethod -Uri "http://ipinfo.io/ip" -TimeoutSec 1 -ErrorAction SilentlyContinue
        return $ip.Trim()
    } catch {
        return $null
    }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                          DISPLAY SECTIONS                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Show-Logo {
    $logo = @(
        "",
        "  ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗",
        "  ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║",
        "  ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║",
        "  ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║",
        "  ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║",
        "  ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝",
        "",
        "  ██╗███╗   ██╗███████╗ ██████╗ ██████╗ ███╗   ███╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗",
        "  ██║████╗  ██║██╔════╝██╔═══██╗██╔══██╗████╗ ████║██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║",
        "  ██║██╔██╗ ██║█████╗  ██║   ██║██████╔╝██╔████╔██║███████║   ██║   ██║██║   ██║██╔██╗ ██║",
        "  ██║██║╚██╗██║██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║",
        "  ██║██║ ╚████║██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║",
        "  ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝",
        ""
    )
    
    $colors = @("Magenta", "Magenta", "Cyan", "Cyan", "Blue", "Blue", "Blue", 
                "DarkCyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan", "Cyan")
    
    for ($i = 0; $i -lt $logo.Length; $i++) {
        $color = if ($i -lt $colors.Length) { $colors[$i] } else { "Cyan" }
        Write-Typewriter -Text $logo[$i] -Color $color -Speed 1
    }
}

function Show-Header {
    Clear-Host
    Write-Host ""
    
    Show-Logo
    
    Write-Host ""
    Write-Rainbow -Text "                    ⚡ ULTIMATE SYSTEM DASHBOARD ⚡" -Speed 2
    Write-Host ""
    Write-Host "                    ═══════ NEON EDITION v$($Script:Config.Version) ═══════" -ForegroundColor $Script:Theme.Dim
    Write-Host ""
    Draw-DoubleLine
}

function Show-LoadingScreen {
    Clear-Host
    
    $height = Get-TerminalHeight
    $topPadding = [math]::Floor($height / 4)
    
    for ($i = 0; $i -lt $topPadding; $i++) {
        Write-Host ""
    }
    
    $loadingArt = @(
        "    ███████╗ ██████╗ █████╗ ███╗   ██╗███╗   ██╗██╗███╗   ██╗ ██████╗ ",
        "    ██╔════╝██╔════╝██╔══██╗████╗  ██║████╗  ██║██║████╗  ██║██╔════╝ ",
        "    ███████╗██║     ███████║██╔██╗ ██║██╔██╗ ██║██║██╔██╗ ██║██║  ███╗",
        "    ╚════██║██║     ██╔══██║██║╚██╗██║██║╚██╗██║██║██║╚██╗██║██║   ██║",
        "    ███████║╚██████╗██║  ██║██║ ╚████║██║ ╚████║██║██║ ╚████║╚██████╔╝",
        "    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝ ╚═════╝ "
    )
    
    foreach ($line in $loadingArt) {
        Write-Typewriter -Text $line -Color $Script:Theme.Primary -Speed 1
    }
    
    Write-Host ""
    Write-Host ""
    
    # Scanning animation
    $components = @(
        @{ Name = "CPU"; Icon = "⚙️" },
        @{ Name = "Memory"; Icon = "🧠" },
        @{ Name = "Storage"; Icon = "💾" },
        @{ Name = "Network"; Icon = "📡" },
        @{ Name = "GPU"; Icon = "🎮" },
        @{ Name = "System"; Icon = "🖥️" }
    )
    
    foreach ($comp in $components) {
        Write-Host "        $($comp.Icon) Scanning $($comp.Name)..." -NoNewline -ForegroundColor $Script:Theme.Dim
        Show-Spinner -DurationMs 200 -Message "" -CompletedMessage "Found" -Style "Braille"
    }
    
    Write-Host ""
    Write-Host ""
    
    # Progress bar
    Show-AnimatedProgress -Steps 100 -Delay 15 -Message "Initializing" -Style "Neon"
    
    Write-Host ""
    Write-Pulse -Text "        ✔ System scan complete!" -Color $Script:Theme.Success
    
    Start-Sleep -Milliseconds 500
}

function Show-SystemOverview {
    $data = Get-SystemData
    $cs = $data.Computer
    $bios = $data.BIOS
    $board = $data.BaseBoard
    
    Draw-SectionHeader -Title "System Overview" -Icon "🖥️" -Color "Green"
    Draw-SectionLine -Color "Green"
    
    Draw-InfoLine -Label "💻 Computer" -Value $cs.Name -ValueColor "Yellow" -BorderColor "Green"
    Draw-InfoLine -Label "👤 User" -Value "$env:USERDOMAIN\$env:USERNAME" -ValueColor "Cyan" -BorderColor "Green"
    Draw-InfoLine -Label "🏢 Manufacturer" -Value "$($cs.Manufacturer)" -ValueColor "White" -BorderColor "Green"
    Draw-InfoLine -Label "📱 Model" -Value "$($cs.Model)" -ValueColor "White" -BorderColor "Green"
    
    if ($board) {
        Draw-InfoLine -Label "🔌 Mainboard" -Value "$($board.Product)" -ValueColor "White" -BorderColor "Green"
    }
    
    Draw-InfoLine -Label "🔢 Serial" -Value $bios.SerialNumber -ValueColor "Magenta" -BorderColor "Green"
    Draw-InfoLine -Label "🧬 BIOS Ver" -Value "$($bios.SMBIOSBIOSVersion) ($($bios.ReleaseDate.ToString('yyyy-MM-dd')))" -ValueColor "DarkGray" -BorderColor "Green"
    
    Draw-InfoLine -Label "🎯 Domain" -Value $(if ($cs.PartOfDomain) { $cs.Domain } else { "WORKGROUP" }) -ValueColor "White" -BorderColor "Green"
    Draw-InfoLine -Label "🔧 System Type" -Value $cs.SystemType -ValueColor "Cyan" -BorderColor "Green"
    
    Draw-SectionFooter -Color "Green"
}

function Show-OperatingSystem {
    $data = Get-SystemData
    $os = $data.OS
    
    $uptime = (Get-Date) - $os.LastBootUpTime
    
    Draw-SectionHeader -Title "Operating System" -Icon "🪟" -Color "Blue"
    Draw-SectionLine -Color "Blue"
    
    Draw-InfoLine -Label "OS Name" -Value $os.Caption -ValueColor "White" -BorderColor "Blue"
    Draw-InfoLine -Label "Version" -Value "$($os.Version) (Build $($os.BuildNumber))" -ValueColor "Cyan" -BorderColor "Blue"
    Draw-InfoLine -Label "Architecture" -Value $os.OSArchitecture -ValueColor "Yellow" -BorderColor "Blue"
    Draw-InfoLine -Label "Install Date" -Value $os.InstallDate.ToString("yyyy-MM-dd HH:mm:ss") -ValueColor "Green" -BorderColor "Blue"
    Draw-InfoLine -Label "Last Boot" -Value $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss") -ValueColor "Green" -BorderColor "Blue"
    
    # Uptime with color coding
    $uptimeColor = if ($uptime.Days -gt 30) { "Red" } elseif ($uptime.Days -gt 7) { "Yellow" } else { "Green" }
    Write-Host "  │  Uptime        : " -NoNewline -ForegroundColor "DarkGray"
    Write-Host (Format-Uptime $uptime) -ForegroundColor $uptimeColor
    
    # System directory
    Draw-InfoLine -Label "System Dir" -Value $os.SystemDirectory -ValueColor "DarkGray" -BorderColor "Blue"
    
    Draw-SectionFooter -Color "Blue"
}

function Show-CPUInfo {
    $data = Get-SystemData
    $cpu = $data.CPU
    $cpuLoad = Get-LiveCPULoad
    
    Draw-SectionHeader -Title "CPU Information" -Icon "⚙️" -Color "Yellow"
    Draw-SectionLine -Color "Yellow"
    
    Draw-InfoLine -Label "Name" -Value $cpu.Name.Trim() -ValueColor "White" -BorderColor "Yellow"
    Draw-InfoLine -Label "Cores" -Value "$($cpu.NumberOfCores) cores, $($cpu.NumberOfLogicalProcessors) threads" -ValueColor "Cyan" -BorderColor "Yellow"
    Draw-InfoLine -Label "Max Speed" -Value (Format-Frequency $cpu.MaxClockSpeed) -ValueColor "Yellow" -BorderColor "Yellow"
    Draw-InfoLine -Label "Current" -Value (Format-Frequency $cpu.CurrentClockSpeed) -ValueColor "Green" -BorderColor "Yellow"
    
    # Cache info
    if ($cpu.L2CacheSize -gt 0) {
        Draw-InfoLine -Label "L2 Cache" -Value (Format-FileSize ($cpu.L2CacheSize * 1KB)) -ValueColor "Magenta" -BorderColor "Yellow"
    }
    if ($cpu.L3CacheSize -gt 0) {
        Draw-InfoLine -Label "L3 Cache" -Value (Format-FileSize ($cpu.L3CacheSize * 1KB)) -ValueColor "Magenta" -BorderColor "Yellow"
    }
    
    # CPU Load with gauge
    Write-Host "  │" -ForegroundColor "Yellow"
    Draw-Gauge -Label "CPU Load" -Value $cpuLoad -Max 100 -Unit "%"
    
    # Mini chart simulation
    Write-Host "  │" -ForegroundColor "Yellow"
    $samples = @(30, 45, 55, 40, 65, 80, 70, 55, 45, 60, 75, $cpuLoad)
    Write-Host "  │  History     : " -NoNewline -ForegroundColor "DarkGray"
    Draw-MiniChart -Values $samples -Color $Script:Theme.CPU
    
    Draw-SectionFooter -Color "Yellow"
}

function Show-MemoryInfo {
    $mem = Get-LiveMemory
    
    Draw-SectionHeader -Title "Memory (RAM)" -Icon "🧠" -Color "Magenta"
    Draw-SectionLine -Color "Magenta"
    
    Draw-InfoLine -Label "Total" -Value (Format-FileSize $mem.Total) -ValueColor "White" -BorderColor "Magenta"
    Draw-InfoLine -Label "Used" -Value (Format-FileSize $mem.Used) -ValueColor "Yellow" -BorderColor "Magenta"
    Draw-InfoLine -Label "Free" -Value (Format-FileSize $mem.Free) -ValueColor "Green" -BorderColor "Magenta"
    
    # Memory bar
    Write-Host "  │" -ForegroundColor "Magenta"
    Write-Host "  │  Usage        : " -NoNewline -ForegroundColor "DarkGray"
    
    $barWidth = 40
    $filled = [math]::Floor($mem.Percent * $barWidth / 100)
    $bar = "█" * $filled + "░" * ($barWidth - $filled)
    $memColor = Get-PercentageColor -Percent $mem.Percent
    
    Write-Host "[" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host $bar -NoNewline -ForegroundColor $memColor
    Write-Host "] " -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host "$($mem.Percent)%" -ForegroundColor $memColor
    
    # Memory breakdown visualization
    Write-Host "  │" -ForegroundColor "Magenta"
    Write-Host "  │  Breakdown    : " -NoNewline -ForegroundColor "DarkGray"
    
    $usedBlocks = [math]::Floor(($mem.Used / $mem.Total) * 20)
    $freeBlocks = 20 - $usedBlocks
    
    Write-Host ("▓" * $usedBlocks) -NoNewline -ForegroundColor "Red"
    Write-Host ("░" * $freeBlocks) -NoNewline -ForegroundColor "Green"
    Write-Host " Used/Free" -ForegroundColor $Script:Theme.Dim
    
    Draw-SectionFooter -Color "Magenta"
}

function Show-GPUInfo {
    $data = Get-SystemData
    $gpu = $data.GPU
    
    if (-not $gpu) { return }
    
    Draw-SectionHeader -Title "GPU Information" -Icon "🎮" -Color "DarkCyan"
    Draw-SectionLine -Color "DarkCyan"
    
    Draw-InfoLine -Label "Name" -Value $gpu.Name -ValueColor "White" -BorderColor "DarkCyan"
    Draw-InfoLine -Label "Driver" -Value $gpu.DriverVersion -ValueColor "Cyan" -BorderColor "DarkCyan"
    Draw-InfoLine -Label "Resolution" -Value "$($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)" -ValueColor "Yellow" -BorderColor "DarkCyan"
    Draw-InfoLine -Label "Refresh Rate" -Value "$($gpu.CurrentRefreshRate) Hz" -ValueColor "Green" -BorderColor "DarkCyan"
    
    if ($gpu.AdapterRAM -gt 0) {
        Draw-InfoLine -Label "VRAM" -Value (Format-FileSize $gpu.AdapterRAM) -ValueColor "Magenta" -BorderColor "DarkCyan"
    }
    
    # Video mode
    Draw-InfoLine -Label "Video Mode" -Value $gpu.VideoModeDescription -ValueColor "DarkGray" -BorderColor "DarkCyan"
    
    Draw-SectionFooter -Color "DarkCyan"
}

function Show-DiskInfo {
    $drives = Get-DriveInfo
    
    Draw-SectionHeader -Title "Disk Drives" -Icon "💾" -Color "DarkGreen"
    
    foreach ($drive in $drives) {
        Write-Host "  │" -ForegroundColor "DarkGreen"
        Write-Host "  │  🗄️  Drive $($drive.Name):" -ForegroundColor "White"
        
        Write-Host "  │     Total  : " -NoNewline -ForegroundColor "DarkGray"
        Write-Host (Format-FileSize $drive.Total) -ForegroundColor "Cyan"
        
        Write-Host "  │     Used   : " -NoNewline -ForegroundColor "DarkGray"
        Write-Host (Format-FileSize $drive.Used) -ForegroundColor "Yellow"
        
        Write-Host "  │     Free   : " -NoNewline -ForegroundColor "DarkGray"
        Write-Host (Format-FileSize $drive.Free) -ForegroundColor "Green"
        
        # Progress bar
        Write-Host "  │     Usage  : " -NoNewline -ForegroundColor "DarkGray"
        
        $barWidth = 30
        $filled = [math]::Floor($drive.Percent * $barWidth / 100)
        $bar = "█" * $filled + "░" * ($barWidth - $filled)
        $driveColor = Get-PercentageColor -Percent $drive.Percent
        
        Write-Host "[" -NoNewline -ForegroundColor $Script:Theme.Dim
        Write-Host $bar -NoNewline -ForegroundColor $driveColor
        Write-Host "] " -NoNewline -ForegroundColor $Script:Theme.Dim
        Write-Host "$($drive.Percent)%" -ForegroundColor $driveColor
        
        # Visual breakdown
        Write-Host "  │     Visual : " -NoNewline -ForegroundColor "DarkGray"
        $usedBlocks = [math]::Floor($drive.Percent / 5)
        $freeBlocks = 20 - $usedBlocks
        Write-Host ("■" * $usedBlocks) -NoNewline -ForegroundColor $driveColor
        Write-Host ("□" * $freeBlocks) -ForegroundColor "DarkGray"
    }
    
    Draw-SectionFooter -Color "DarkGreen"
}

function Show-NetworkInfo {
    $networks = Get-NetworkInfo
    
    Draw-SectionHeader -Title "Network Adapters" -Icon "📡" -Color "Cyan"
    
    if ($networks.Count -eq 0) {
        Write-Host "  │" -ForegroundColor "Cyan"
        Write-Host "  │  ⚠ No active network adapters found" -ForegroundColor "Yellow"
    } else {
        foreach ($net in $networks) {
            Write-Host "  │" -ForegroundColor "Cyan"
            Write-Host "  │  🌐 $($net.Name)" -ForegroundColor "White"
            
            Write-Host "  │     Status  : " -NoNewline -ForegroundColor "DarkGray"
            Draw-StatusBadge -Text $net.Status -Type "Success"
            Write-Host ""
            
            Draw-InfoLine -Label "IPv4" -Value $net.IPv4 -ValueColor "Green" -BorderColor "Cyan"
            Draw-InfoLine -Label "IPv6" -Value $net.IPv6 -ValueColor "DarkGray" -BorderColor "Cyan"
            
            Write-Host "  │     Speed   : " -NoNewline -ForegroundColor "DarkGray"
            Write-Host $net.Speed -ForegroundColor "Yellow"
            
            Write-Host "  │     MAC     : " -NoNewline -ForegroundColor "DarkGray"
            Write-Host $net.MAC -ForegroundColor "Magenta"
            
            if ($net.BytesSent -gt 0 -or $net.BytesReceived -gt 0) {
                Write-Host "  │     Traffic : " -NoNewline -ForegroundColor "DarkGray"
                Write-Host "▲ $(Format-FileSize $net.BytesSent)  " -NoNewline -ForegroundColor "Green"
                Write-Host "▼ $(Format-FileSize $net.BytesReceived)" -ForegroundColor "Cyan"
            }
        }
    }
    
    # Check public IP
    $pubIp = Get-ExternalIP
    if ($pubIp) {
         Draw-SectionLine -Color "Cyan"
         Draw-InfoLine -Label "🌍 Public IP" -Value $pubIp -ValueColor "Green" -BorderColor "Cyan"
    }
    
    Draw-SectionFooter -Color "Cyan"
}

function Show-PowerShellInfo {
    Draw-SectionHeader -Title "PowerShell Environment" -Icon "💎" -Color "DarkMagenta"
    Draw-SectionLine -Color "DarkMagenta"
    
    Draw-InfoLine -Label "Version" -Value "PowerShell $($PSVersionTable.PSVersion)" -ValueColor "Cyan" -BorderColor "DarkMagenta"
    Draw-InfoLine -Label "Edition" -Value $PSVersionTable.PSEdition -ValueColor "Yellow" -BorderColor "DarkMagenta"
    
    # Profile status
    $profileStatus = if (Test-Path $PROFILE) { "✔ Loaded" } else { "✖ Not found" }
    $profileColor = if (Test-Path $PROFILE) { "Green" } else { "Red" }
    Write-Host "  │  Profile       : " -NoNewline -ForegroundColor "DarkGray"
    Write-Host $profileStatus -ForegroundColor $profileColor
    
    Draw-InfoLine -Label "Execution" -Value (Get-ExecutionPolicy) -ValueColor "Magenta" -BorderColor "DarkMagenta"
    Draw-InfoLine -Label "Culture" -Value (Get-Culture).Name -ValueColor "White" -BorderColor "DarkMagenta"
    Draw-InfoLine -Label "Host" -Value $Host.Name -ValueColor "Cyan" -BorderColor "DarkMagenta"
    
    Draw-SectionFooter -Color "DarkMagenta"
}

function Show-QuickStats {
    Draw-SectionHeader -Title "Quick Stats" -Icon "📊" -Color "DarkYellow"
    Draw-SectionLine -Color "DarkYellow"
    
    # Process count
    $processCount = (Get-Process).Count
    Draw-InfoLine -Label "🔄 Processes" -Value $processCount -ValueColor "Cyan" -BorderColor "DarkYellow"
    
    # Services
    $services = Get-Service
    $runningServices = ($services | Where-Object Status -eq 'Running').Count
    $totalServices = $services.Count
    Draw-InfoLine -Label "⚙️ Services" -Value "$runningServices running / $totalServices total" -ValueColor "Green" -BorderColor "DarkYellow"
    
    # Network adapters
    $adapters = (Get-NetAdapter | Where-Object Status -eq 'Up').Count
    Draw-InfoLine -Label "📡 Net Adapters" -Value "$adapters active" -ValueColor "Yellow" -BorderColor "DarkYellow"
    
    # Installed programs count
    try {
        $programCount = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue).Count
        Draw-InfoLine -Label "📦 Programs" -Value "$programCount installed" -ValueColor "Magenta" -BorderColor "DarkYellow"
    } catch {}
    
    # Current time
    Draw-InfoLine -Label "🕒 System Time" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -ValueColor "Magenta" -BorderColor "DarkYellow"
    
    # Timezone
    Draw-InfoLine -Label "🌍 Timezone" -Value (Get-TimeZone).DisplayName -ValueColor "White" -BorderColor "DarkYellow"
    
    Draw-SectionFooter -Color "DarkYellow"
}

function Show-PerformanceSummary {
    $cpu = Get-LiveCPULoad
    $mem = Get-LiveMemory
    $drives = Get-DriveInfo
    
    Draw-Panel -Title "Performance Summary" -Icon "📈" -Color $Script:Theme.Primary
    
    Write-Host ""
    
    # CPU Gauge
    Write-Host "    CPU Usage    " -NoNewline -ForegroundColor $Script:Theme.Dim
    $cpuBar = "█" * [math]::Floor($cpu / 5) + "░" * (20 - [math]::Floor($cpu / 5))
    $cpuColor = Get-PercentageColor -Percent $cpu
    Write-Host "[$cpuBar] " -NoNewline -ForegroundColor $cpuColor
    Write-Host "$cpu%" -ForegroundColor $cpuColor
    
    # RAM Gauge
    Write-Host "    RAM Usage    " -NoNewline -ForegroundColor $Script:Theme.Dim
    $ramBar = "█" * [math]::Floor($mem.Percent / 5) + "░" * (20 - [math]::Floor($mem.Percent / 5))
    $ramColor = Get-PercentageColor -Percent $mem.Percent
    Write-Host "[$ramBar] " -NoNewline -ForegroundColor $ramColor
    Write-Host "$($mem.Percent)%" -ForegroundColor $ramColor
    
    # Primary Disk Gauge
    if ($drives.Count -gt 0) {
        $primaryDisk = $drives[0]
        Write-Host "    Disk ($($primaryDisk.Name):)    " -NoNewline -ForegroundColor $Script:Theme.Dim
        $diskBar = "█" * [math]::Floor($primaryDisk.Percent / 5) + "░" * (20 - [math]::Floor($primaryDisk.Percent / 5))
        $diskColor = Get-PercentageColor -Percent $primaryDisk.Percent
        Write-Host "[$diskBar] " -NoNewline -ForegroundColor $diskColor
        Write-Host "$($primaryDisk.Percent)%" -ForegroundColor $diskColor
    }
    
    Write-Host ""
}

function Show-TopProcesses {
    Draw-SectionHeader -Title "Top Resource Consumers" -Icon "🔥" -Color "Red"
    Draw-SectionLine -Color "Red"
    
    $topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
    $topRAM = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
    
    Write-Host "  │  " -NoNewline -ForegroundColor "Red"
    Write-Host "⚡ Top 5 CPU Consumers" -ForegroundColor "Yellow"
    
    foreach ($p in $topCPU) {
        $cpuSec = [math]::Round($p.CPU, 2)
        Draw-InfoLine -Label $p.ProcessName -Value "${cpuSec}s CPU" -ValueColor "White" -BorderColor "Red"
    }
    
    Draw-SectionLine -Color "Red"
    Write-Host "  │  " -NoNewline -ForegroundColor "Red"
    Write-Host "🧠 Top 5 RAM Consumers" -ForegroundColor "Yellow"
    
    foreach ($p in $topRAM) {
        $ramMB = [math]::Round($p.WorkingSet64 / 1MB, 2)
        Draw-InfoLine -Label $p.ProcessName -Value "${ramMB} MB" -ValueColor "White" -BorderColor "Red"
    }
    
    Draw-SectionFooter -Color "Red"
}

function Show-Footer {
    Write-Host ""
    Draw-DoubleLine
    Write-Host ""
    
    $duration = (Get-Date) - $Script:Config.StartTime
    
    Write-Host "    ┌────────────────────────────────────────────────────────────┐" -ForegroundColor $Script:Theme.Border
    Write-Host "    │  " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "📊 Report generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host "            │" -ForegroundColor $Script:Theme.Border
    Write-Host "    │  " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "⏱️  Generation time: $(Format-Uptime $duration)" -NoNewline -ForegroundColor $Script:Theme.Dim
    Write-Host "                            │" -ForegroundColor $Script:Theme.Border
    Write-Host "    │  " -NoNewline -ForegroundColor $Script:Theme.Border
    Write-Host "🔧 Neon Dashboard v$($Script:Config.Version)" -NoNewline -ForegroundColor $Script:Theme.Primary
    Write-Host "                               │" -ForegroundColor $Script:Theme.Border
    Write-Host "    └────────────────────────────────────────────────────────────┘" -ForegroundColor $Script:Theme.Border
    
    Write-Host ""
    Write-Rainbow -Text "              ★ System Information Dashboard Complete ★" -Speed 2
    Write-Host ""
    
    # Options
    Write-Host "    ┌─ Options ──────────────────────────────────────────────────┐" -ForegroundColor $Script:Theme.Dim
    Write-Host "    │  [R] Refresh    [E] Export    [T] Theme    [Q] Quit        │" -ForegroundColor $Script:Theme.Dim
    Write-Host "    └────────────────────────────────────────────────────────────┘" -ForegroundColor $Script:Theme.Dim
    Write-Host ""
}

function Export-Report {
    $reportPath = Join-Path $env:USERPROFILE "Desktop\SystemReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $data = Get-SystemData -Force
    $mem = Get-LiveMemory
    $drives = Get-DriveInfo
    
    $report = @"
================================================================================
                         SYSTEM INFORMATION REPORT
                         Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

SYSTEM OVERVIEW
---------------
Computer Name  : $($data.Computer.Name)
User           : $env:USERDOMAIN\$env:USERNAME
Manufacturer   : $($data.Computer.Manufacturer)
Model          : $($data.Computer.Model)
Serial Number  : $($data.BIOS.SerialNumber)

OPERATING SYSTEM
----------------
OS Name        : $($data.OS.Caption)
Version        : $($data.OS.Version) (Build $($data.OS.BuildNumber))
Architecture   : $($data.OS.OSArchitecture)
Install Date   : $($data.OS.InstallDate)
Last Boot      : $($data.OS.LastBootUpTime)

CPU INFORMATION
---------------
Processor      : $($data.CPU.Name.Trim())
Cores          : $($data.CPU.NumberOfCores) cores, $($data.CPU.NumberOfLogicalProcessors) threads
Max Speed      : $($data.CPU.MaxClockSpeed) MHz
Current Load   : $(Get-LiveCPULoad)%

MEMORY
------
Total RAM      : $(Format-FileSize $mem.Total)
Used           : $(Format-FileSize $mem.Used)
Free           : $(Format-FileSize $mem.Free)
Usage          : $($mem.Percent)%

GPU INFORMATION
---------------
GPU Name       : $($data.GPU.Name)
Driver Version : $($data.GPU.DriverVersion)
Resolution     : $($data.GPU.CurrentHorizontalResolution) x $($data.GPU.CurrentVerticalResolution)
VRAM           : $(Format-FileSize $data.GPU.AdapterRAM)

DISK DRIVES
-----------
$($drives | ForEach-Object { "Drive $($_.Name): - Total: $(Format-FileSize $_.Total), Used: $(Format-FileSize $_.Used), Free: $(Format-FileSize $_.Free), Usage: $($_.Percent)%" } | Out-String)

POWERSHELL
----------
Version        : $($PSVersionTable.PSVersion)
Edition        : $($PSVersionTable.PSEdition)
Execution Policy: $(Get-ExecutionPolicy)

================================================================================
                              End of Report
================================================================================
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host ""
    Write-Host "    ✔ Report exported to: $reportPath" -ForegroundColor "Green"
    Write-Host ""
    
    Play-Sound -Type Success
}

function Switch-Theme {
    $themeNames = @("Neon", "Matrix", "Cyberpunk")
    $currentIndex = [array]::IndexOf($themeNames, $Script:CurrentThemeName)
    $nextIndex = ($currentIndex + 1) % $themeNames.Length
    $Script:CurrentThemeName = $themeNames[$nextIndex]
    $Script:Theme = $Script:Themes[$Script:CurrentThemeName]
    
    Write-Host ""
    Write-Host "    🎨 Theme changed to: $Script:CurrentThemeName" -ForegroundColor $Script:Theme.Primary
    Write-Host ""
    
    Play-Sound -Type Info
}

# Initialize theme name
$Script:CurrentThemeName = "Neon"

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MAIN EXECUTION                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

function Start-Dashboard {
    try {
        # Loading screen
        Show-LoadingScreen
        
        Play-Sound -Type Start
        
        do {
            # Display header
            Show-Header
            
            # Collect data
            $null = Get-SystemData -Force
            
            # Display all sections
            Show-SystemOverview
            Show-OperatingSystem
            Show-CPUInfo
            Show-MemoryInfo
            Show-GPUInfo
            Show-DiskInfo
            Show-NetworkInfo
            Show-TopProcesses
            Show-PowerShellInfo
            Show-QuickStats
            Show-PerformanceSummary
            Show-Footer
            
            # Wait for user input
            Write-Host "    Press a key: " -NoNewline -ForegroundColor $Script:Theme.Dim
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            switch ($key.Character) {
                'r' { 
                    Write-Host "Refreshing..." -ForegroundColor $Script:Theme.Primary
                    Play-Sound -Type Scan
                    continue 
                }
                'R' { 
                    Write-Host "Refreshing..." -ForegroundColor $Script:Theme.Primary
                    Play-Sound -Type Scan
                    continue 
                }
                'e' { Export-Report }
                'E' { Export-Report }
                't' { Switch-Theme }
                'T' { Switch-Theme }
                'q' { 
                    Write-Host ""
                    Write-Host "    👋 Goodbye!" -ForegroundColor $Script:Theme.Primary
                    Play-Sound -Type Complete
                    return 
                }
                'Q' { 
                    Write-Host ""
                    Write-Host "    👋 Goodbye!" -ForegroundColor $Script:Theme.Primary
                    Play-Sound -Type Complete
                    return 
                }
            }
            
        } while ($true)
        
    } catch {
        Write-Host ""
        Write-Host "    ✖ Error: $_" -ForegroundColor "Red"
        Write-Host ""
    }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              RUN DASHBOARD                                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

Start-Dashboard
