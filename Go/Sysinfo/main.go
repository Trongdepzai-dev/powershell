// main.go
package main

import (
	"fmt"
	"math"
	"os"
	"os/exec"
	"os/user"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
	"github.com/shirou/gopsutil/v3/process"
)

// ══════════════════════════════════════════════════════════════════
//                    ULTRA THEME SYSTEM
// ══════════════════════════════════════════════════════════════════

type Theme struct {
	Name        string
	Primary     string
	Secondary   string
	Accent      string
	Success     string
	Warning     string
	Error       string
	Info        string
	Background  string
	Surface     string
	SurfaceAlt  string
	Text        string
	TextMuted   string
	TextBright  string
	Border      string
	BorderGlow  string
	CPU         string
	RAM         string
	Disk        string
	Network     string
	GPU         string
	Battery     string
	Temperature string
	Gradient1   string
	Gradient2   string
	Gradient3   string
	Shadow      string
	Highlight   string
}

var themes = map[string]Theme{
	"Neon Synthwave": {
		Name: "Neon Synthwave", Primary: "#00FFFF", Secondary: "#FF00FF",
		Accent: "#FFD700", Success: "#00FF88", Warning: "#FFB800",
		Error: "#FF4444", Info: "#3B82F6", Background: "#0A0E14",
		Surface: "#1A1E2E", SurfaceAlt: "#252A3D", Text: "#E2E8F0",
		TextMuted: "#64748B", TextBright: "#FFFFFF", Border: "#2D3748",
		BorderGlow: "#00FFFF", CPU: "#FFFF00", RAM: "#FF00FF",
		Disk: "#00FF88", Network: "#00FFFF", GPU: "#FF6B6B",
		Battery: "#22C55E", Temperature: "#EF4444",
		Gradient1: "#FF00FF", Gradient2: "#00FFFF", Gradient3: "#FFD700",
		Shadow: "#000000", Highlight: "#FFFFFF",
	},
	"Cyber Matrix": {
		Name: "Cyber Matrix", Primary: "#00FF00", Secondary: "#008800",
		Accent: "#00FF00", Success: "#00FF00", Warning: "#CCFF00",
		Error: "#FF0000", Info: "#00AA00", Background: "#000000",
		Surface: "#0A1A0A", SurfaceAlt: "#0F2A0F", Text: "#00FF00",
		TextMuted: "#006600", TextBright: "#88FF88", Border: "#004400",
		BorderGlow: "#00FF00", CPU: "#00FF00", RAM: "#00CC00",
		Disk: "#00AA00", Network: "#00FF00", GPU: "#66FF66",
		Battery: "#00FF00", Temperature: "#FFFF00",
		Gradient1: "#003300", Gradient2: "#00FF00", Gradient3: "#88FF88",
		Shadow: "#001100", Highlight: "#00FF00",
	},
	"Cyberpunk 2077": {
		Name: "Cyberpunk 2077", Primary: "#FF00FF", Secondary: "#00FFFF",
		Accent: "#FFD700", Success: "#00FFFF", Warning: "#FFD700",
		Error: "#FF0040", Info: "#FF00FF", Background: "#0D0221",
		Surface: "#1A0A2E", SurfaceAlt: "#2A1A4E", Text: "#FFFFFF",
		TextMuted: "#8866AA", TextBright: "#FFCCFF", Border: "#6B21A8",
		BorderGlow: "#FF00FF", CPU: "#00FFFF", RAM: "#FF00FF",
		Disk: "#FFD700", Network: "#00FFFF", GPU: "#FF0040",
		Battery: "#00FFFF", Temperature: "#FF0040",
		Gradient1: "#FF00FF", Gradient2: "#8B00FF", Gradient3: "#00FFFF",
		Shadow: "#0D0221", Highlight: "#FF00FF",
	},
	"Ocean Depths": {
		Name: "Ocean Depths", Primary: "#06B6D4", Secondary: "#0EA5E9",
		Accent: "#38BDF8", Success: "#10B981", Warning: "#F59E0B",
		Error: "#EF4444", Info: "#3B82F6", Background: "#0C1222",
		Surface: "#1E293B", SurfaceAlt: "#334155", Text: "#F1F5F9",
		TextMuted: "#64748B", TextBright: "#FFFFFF", Border: "#334155",
		BorderGlow: "#06B6D4", CPU: "#38BDF8", RAM: "#A78BFA",
		Disk: "#10B981", Network: "#06B6D4", GPU: "#F472B6",
		Battery: "#22C55E", Temperature: "#EF4444",
		Gradient1: "#0EA5E9", Gradient2: "#06B6D4", Gradient3: "#38BDF8",
		Shadow: "#0A0F1A", Highlight: "#38BDF8",
	},
	"Blood Moon": {
		Name: "Blood Moon", Primary: "#DC2626", Secondary: "#F97316",
		Accent: "#FCD34D", Success: "#22C55E", Warning: "#F59E0B",
		Error: "#DC2626", Info: "#F97316", Background: "#1A0A0A",
		Surface: "#2A1515", SurfaceAlt: "#3A2020", Text: "#FEE2E2",
		TextMuted: "#A87070", TextBright: "#FFFFFF", Border: "#4A2020",
		BorderGlow: "#DC2626", CPU: "#F97316", RAM: "#DC2626",
		Disk: "#FCD34D", Network: "#F97316", GPU: "#DC2626",
		Battery: "#22C55E", Temperature: "#DC2626",
		Gradient1: "#DC2626", Gradient2: "#F97316", Gradient3: "#FCD34D",
		Shadow: "#0A0505", Highlight: "#DC2626",
	},
	"Aurora Borealis": {
		Name: "Aurora Borealis", Primary: "#22D3EE", Secondary: "#A78BFA",
		Accent: "#34D399", Success: "#34D399", Warning: "#FBBF24",
		Error: "#F87171", Info: "#60A5FA", Background: "#0F172A",
		Surface: "#1E293B", SurfaceAlt: "#334155", Text: "#F8FAFC",
		TextMuted: "#94A3B8", TextBright: "#FFFFFF", Border: "#475569",
		BorderGlow: "#22D3EE", CPU: "#A78BFA", RAM: "#22D3EE",
		Disk: "#34D399", Network: "#60A5FA", GPU: "#F472B6",
		Battery: "#34D399", Temperature: "#F87171",
		Gradient1: "#22D3EE", Gradient2: "#A78BFA", Gradient3: "#34D399",
		Shadow: "#0A0F1A", Highlight: "#22D3EE",
	},
}

var currentTheme = themes["Neon Synthwave"]

// ══════════════════════════════════════════════════════════════════
//                         ANIMATIONS
// ══════════════════════════════════════════════════════════════════

var spinners = map[string][]string{
	"dots":    {"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"},
	"braille": {"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"},
	"circle":  {"◐", "◓", "◑", "◒"},
	"pulse":   {"○", "◔", "◑", "◕", "●", "◕", "◑", "◔"},
	"wave":    {"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃", "▂"},
	"bounce":  {"⠁", "⠂", "⠄", "⡀", "⢀", "⠠", "⠐", "⠈"},
}

var gradients = map[string][]string{
	"rainbow": {"#FF0000", "#FF7F00", "#FFFF00", "#00FF00", "#0000FF", "#4B0082", "#9400D3"},
	"fire":    {"#FF0000", "#FF4500", "#FF8C00", "#FFA500", "#FFD700"},
	"ocean":   {"#000080", "#0000CD", "#4169E1", "#1E90FF", "#00BFFF"},
	"matrix":  {"#003300", "#006600", "#009900", "#00CC00", "#00FF00"},
	"cyber":   {"#FF00FF", "#8B00FF", "#4B0082", "#0000FF", "#00FFFF"},
}

// ══════════════════════════════════════════════════════════════════
//                    ULTRA ANIMATIONS
// ══════════════════════════════════════════════════════════════════

var ultraSpinners = map[string][]string{
	"radar":       {"◜", "◠", "◝", "◞", "◡", "◟"},
	"earth":       {"🌍", "🌎", "🌏"},
	"moon":        {"🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘"},
	"clock":       {"🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚", "🕛"},
	"fire":        {"🔥", "🔥", "💥", "🔥"},
	"hearts":      {"💗", "💓", "💖", "💘", "💝"},
	"neon":        {"◉", "◎", "○", "◎"},
	"dna":         {"🧬", "🔬", "🧬", "🔬"},
	"matrix":      {"█", "▓", "▒", "░", "▒", "▓"},
	"cyber":       {"⟨", "⟩", "⟪", "⟫", "⟨", "⟩"},
	"quantum":     {"◇", "◆", "◈", "◆"},
	"hologram":    {"▢", "▣", "▤", "▥", "▦", "▧", "▨", "▩"},
}

var borderStyles = map[string]struct {
	TopLeft, TopRight, BottomLeft, BottomRight string
	Horizontal, Vertical                        string
	LeftT, RightT, TopT, BottomT, Cross         string
}{
	"rounded": {"╭", "╮", "╰", "╯", "─", "│", "├", "┤", "┬", "┴", "┼"},
	"sharp":   {"┌", "┐", "└", "┘", "─", "│", "├", "┤", "┬", "┴", "┼"},
	"double":  {"╔", "╗", "╚", "╝", "═", "║", "╠", "╣", "╦", "╩", "╬"},
	"thick":   {"┏", "┓", "┗", "┛", "━", "┃", "┣", "┫", "┳", "┻", "╋"},
	"dotted":  {"⡤", "⢤", "⠓", "⠚", "⠤", "⡇", "⠧", "⢸", "⠶", "⠴", "⠿"},
	"neon":    {"◢", "◣", "◥", "◤", "▬", "▐", "◀", "▶", "▲", "▼", "◆"},
}

var asciiArt = map[string]string{
	"cpu": `
   ╔══════════════╗
   ║ ▓▓▓▓▓▓▓▓▓▓▓▓ ║
   ║ ▓ ┌──────┐ ▓ ║
   ║ ▓ │ CPU  │ ▓ ║
   ║ ▓ │ ████ │ ▓ ║
   ║ ▓ └──────┘ ▓ ║
   ║ ▓▓▓▓▓▓▓▓▓▓▓▓ ║
   ╚══════════════╝`,
	"ram": `
   ╔════════════════════╗
   ║ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ║
   ╠════════════════════╣
   ║ █ █ █ █ █ █ █ █ █ ║
   ╚════════════════════╝`,
	"gpu": `
   ╔═══════════════════════╗
   ║ ████████████████████  ║
   ║ █ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ █ ║
   ║ █ ▓ GPU VRAM     ▓ █ ║
   ║ █ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ █ ║
   ║ ████████████████████  ║
   ║  ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ▓▓▓ ║
   ╚═══════════════════════╝`,
	"disk": `
   ╭─────────────────╮
   │ ○ ╭─────────╮   │
   │   │ ▓▓▓▓▓▓▓ │   │
   │   │ ▓ HDD ▓ │   │
   │   │ ▓▓▓▓▓▓▓ │   │
   │   ╰─────────╯   │
   ╰─────────────────╯`,
	"network": `
   ╭────────────────╮
   │    ╱    ╲      │
   │   ╱  📡  ╲     │
   │  ╱        ╲    │
   │ ╱   ════   ╲   │
   │╱            ╲  │
   ╰────────────────╯`,
}

// Sparkline characters
var sparklineChars = []rune{'▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'}

// Block elements for fancy charts
var chartBlocks = struct {
	Full, ThreeQuarter, Half, Quarter, Empty string
	LeftHalf, RightHalf                       string
	TopHalf, BottomHalf                       string
}{
	Full: "█", ThreeQuarter: "▓", Half: "▒", Quarter: "░", Empty: " ",
	LeftHalf: "▌", RightHalf: "▐",
	TopHalf: "▀", BottomHalf: "▄",
}

// Status indicators
var statusIcons = map[string]string{
	"online":   "●",
	"offline":  "○",
	"warning":  "◐",
	"error":    "◉",
	"loading":  "◌",
	"success":  "✓",
	"fail":     "✗",
	"arrow_up": "↑",
	"arrow_dn": "↓",
	"arrow_r":  "→",
	"arrow_l":  "←",
	"star":     "★",
	"heart":    "♥",
	"diamond":  "◆",
	"bolt":     "⚡",
	"fire":     "🔥",
	"ice":      "❄",
	"warn":     "⚠",
	"lock":     "🔒",
	"unlock":   "🔓",
	"shield":   "🛡",
	"gear":     "⚙",
	"chart":    "📊",
	"pulse":    "💓",
}

// ══════════════════════════════════════════════════════════════════
//                         DATA STRUCTURES
// ══════════════════════════════════════════════════════════════════

type SystemInfo struct {
	// Host
	Hostname      string
	Username      string
	OS            string
	Platform      string
	Kernel        string
	Arch          string
	Uptime        time.Duration
	BootTime      time.Time
	Procs         uint64
	UserSessions  int

	// Mainboard & BIOS
	BoardName     string
	BoardVendor   string
	BiosVersion   string
	BiosDate      string
	ProductSerial string
	SystemUUID    string
	ChassisType   string

	// CPU - Extended
	CPUModel      string
	CPUCores      int
	CPUThreads    int
	CPUFreq       float64
	CPUMaxFreq    float64
	CPUUsage      float64
	CPUPerCore    []float64
	CPUL1Cache    uint64
	CPUL2Cache    uint64
	CPUL3Cache    uint64
	CPUFlags      []string

	// Memory - Extended
	MemTotal      uint64
	MemUsed       uint64
	MemFree       uint64
	MemAvailable  uint64
	MemBuffers    uint64
	MemCached     uint64
	MemPercent    float64
	SwapTotal     uint64
	SwapUsed      uint64
	SwapFree      uint64
	SwapPercent   float64

	// Disks - Extended
	Disks         []DiskInfo

	// Network - Extended
	Networks      []NetworkInfo
	PublicIP      string
	LocalIP       string
	DNSServers    []string

	// GPU - Extended
	GPUs          []GPUInfo

	// Battery
	Battery       BatteryInfo
	HasBattery    bool

	// Thermal
	Thermal       ThermalInfo
	HasThermal    bool

	// Load Average
	LoadAvg       LoadAverage

	// I/O Stats
	IOStats       IOStats

	// History for sparklines
	History       HistoryBuffer

	// Services
	Services      []ServiceInfo

	// Security
	Security      SecurityInfo

	// Top Processes
	TopCPU        []ProcessInfo
	TopMem        []ProcessInfo
	TotalProcs    int

	// System Health Score (0-100)
	HealthScore   int
	HealthStatus  string

	// Timestamps
	LastUpdate    time.Time
	CollectTime   time.Duration
}

type DiskInfo struct {
	Path        string
	Device      string
	Fstype      string
	Total       uint64
	Used        uint64
	Free        uint64
	Percent     float64
	Model       string
	Serial      string
	IsRemovable bool
	IsSSD       bool
	ReadBytes   uint64
	WriteBytes  uint64
	ReadCount   uint64
	WriteCount  uint64
	Temperature float64
}

type NetworkInfo struct {
	Name        string
	BytesSent   uint64
	BytesRecv   uint64
	PacketsSent uint64
	PacketsRecv uint64
	Addrs       []string
	MAC         string
	Speed       uint64
	IsUp        bool
	IsWireless  bool
	MTU         int
	ErrorsIn    uint64
	ErrorsOut   uint64
	DropIn      uint64
	DropOut     uint64
}

type GPUInfo struct {
	Index       int
	Name        string
	Vendor      string
	Driver      string
	VRAM        uint64
	VRAMUsed    uint64
	Usage       float64
	Temperature float64
	FanSpeed    float64
	PowerDraw   float64
	ClockCore   uint64
	ClockMem    uint64
}

type ProcessInfo struct {
	PID    int32
	Name   string
	CPU    float64
	Memory float64
	MemMB  float64
}

type HitBox struct {
	X, Y, W, H int
	Type       string
	Index      int
	Action     string
}

type Tab struct {
	ID    string
	Name  string
	Icon  string
	Color string
}

// ══════════════════════════════════════════════════════════════════
//                    EXTENDED DATA STRUCTURES
// ══════════════════════════════════════════════════════════════════

type BatteryInfo struct {
	Percent    float64
	Status     string // "Charging", "Discharging", "Full", "Not Present"
	TimeRemain time.Duration
	PluggedIn  bool
}

type ThermalInfo struct {
	CPUTemp  float64
	GPUTemp  float64
	Sensors  map[string]float64
}

type LoadAverage struct {
	Load1  float64
	Load5  float64
	Load15 float64
}

type IOStats struct {
	ReadBytes  uint64
	WriteBytes uint64
	ReadCount  uint64
	WriteCount uint64
}

type HistoryBuffer struct {
	CPU        []float64
	Memory     []float64
	NetIn      []float64
	NetOut     []float64
	DiskRead   []float64
	DiskWrite  []float64
	MaxLen     int
}

type ServiceInfo struct {
	Name        string
	DisplayName string
	Status      string
	StartType   string
}

type SecurityInfo struct {
	Firewall    string
	Antivirus   string
	LastUpdate  string
	UAC         string
}

type InstalledApp struct {
	Name    string
	Version string
	Size    string
}

// Animation frames for special effects
type ParticleEffect struct {
	X, Y   float64
	VX, VY float64
	Life   int
	Char   rune
	Color  string
}

// ══════════════════════════════════════════════════════════════════
//                         MODEL
// ══════════════════════════════════════════════════════════════════

type Model struct {
	// System data
	sysInfo       SystemInfo
	loading       bool
	loadingStep   int
	loadingMsg    string
	loadingPhase  string

	// UI State
	activeTab     int
	tabs          []Tab
	scrollY       int
	maxScroll     int
	selectedItem  int

	// Dimensions
	width         int
	height        int
	isCompact     bool
	isMobile      bool
	isUltraWide   bool

	// Mouse
	mouseX        int
	mouseY        int
	hoverTab      int
	hoverBtn      string
	hitBoxes      []HitBox
	clickAnim     int

	// Animation
	frame         int
	startTime     time.Time
	glowPhase     float64
	particles     []ParticleEffect
	pulsePhase    int
	waveOffset    int

	// Theme
	themeIndex    int
	themeNames    []string
	borderStyle   string

	// History data for charts
cpuHistory    []float64
memHistory    []float64
netInHistory  []float64
netOutHistory []float64

	// Export
	exported      bool
	exportFade    int
	exportPath    string

	// Notifications
	notifications []Notification
	notifyFade    int

	// View mode
detailMode    bool
chartMode     string // "sparkline", "bar", "area"

	// Search/Filter
	filterText    string
	filterActive  bool
}

type Notification struct {
	Message   string
	Type      string // "info", "success", "warning", "error"
	Timestamp time.Time
	Fade      int
}

type tickMsg time.Time
type sysInfoMsg SystemInfo

// ══════════════════════════════════════════════════════════════════
//                    ULTRA VISUAL HELPERS
// ══════════════════════════════════════════════════════════════════

func makeSparkline(values []float64, width int) string {
	if len(values) == 0 {
		return strings.Repeat("▁", width)
	}

	// Normalize values
	minVal, maxVal := values[0], values[0]
	for _, v := range values {
		if v < minVal {
			minVal = v
		}
		if v > maxVal {
			maxVal = v
		}
	}

	rangeVal := maxVal - minVal
	if rangeVal == 0 {
		rangeVal = 1
	}

	// Sample values if needed
	step := float64(len(values)) / float64(width)
	var result strings.Builder

	for i := 0; i < width; i++ {
		idx := int(float64(i) * step)
		if idx >= len(values) {
			idx = len(values) - 1
		}

		normalized := (values[idx] - minVal) / rangeVal
		charIdx := int(normalized * 7)
		if charIdx > 7 {
			charIdx = 7
		}
		if charIdx < 0 {
			charIdx = 0
		}

		result.WriteRune(sparklineChars[charIdx])
	}

	return result.String()
}

func makeColoredSparkline(values []float64, width int, baseColor string) string {
	spark := makeSparkline(values, width)
	return lipgloss.NewStyle().Foreground(lipgloss.Color(baseColor)).Render(spark)
}

func makeAreaChart(values []float64, width, height int, color string) string {
	if len(values) == 0 || height < 2 {
		return ""
	}

	// Normalize
	maxVal := 0.0
	for _, v := range values {
		if v > maxVal {
			maxVal = v
		}
	}
	if maxVal == 0 {
		maxVal = 1
	}

	// Sample
	step := float64(len(values)) / float64(width)
	sampledValues := make([]float64, width)
	for i := 0; i < width; i++ {
		idx := int(float64(i) * step)
		if idx >= len(values) {
			idx = len(values) - 1
		}
		sampledValues[i] = values[idx]
	}

	// Build chart
	chart := make([][]rune, height)
	for i := range chart {
		chart[i] = make([]rune, width)
		for j := range chart[i] {
			chart[i][j] = ' '
		}
	}

	style := lipgloss.NewStyle().Foreground(lipgloss.Color(color))

	for x, val := range sampledValues {
		fillHeight := int((val / maxVal) * float64(height))
		for y := height - 1; y >= height-fillHeight && y >= 0; y-- {
			if y == height-fillHeight {
				chart[y][x] = '▀'
			} else {
				chart[y][x] = '█'
			}
		}
	}

	var result strings.Builder
	for _, row := range chart {
		result.WriteString(style.Render(string(row)) + "\n")
	}

	return result.String()
}

func makeBarChart(labels []string, values []float64, maxWidth int, colors []string) string {
	if len(values) == 0 {
		return ""
	}

	maxVal := 0.0
	for _, v := range values {
		if v > maxVal {
			maxVal = v
		}
	}
	if maxVal == 0 {
		maxVal = 1
	}

	maxLabelLen := 0
	for _, l := range labels {
		if len(l) > maxLabelLen {
			maxLabelLen = len(l)
		}
	}

	barWidth := maxWidth - maxLabelLen - 15

	var result strings.Builder
	for i, val := range values {
		label := labels[i]
		if len(label) < maxLabelLen {
			label = label + strings.Repeat(" ", maxLabelLen-len(label))
		}

		filled := int((val / maxVal) * float64(barWidth))
		color := colors[i%len(colors)]

		barStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(color))
		bar := barStyle.Render(strings.Repeat("█", filled) + strings.Repeat("░", barWidth-filled))

		result.WriteString(fmt.Sprintf("  %s %s %6.1f%%\n", label, bar, val))
	}

	return result.String()
}

func makeDonutChart(percent float64, size int, color string) string {
	if size < 3 {
		size = 3
	}

	chars := []string{"○", "◔", "◑", "◕", "●"}
	idx := int(percent / 20)
	if idx > 4 {
		idx = 4
	}

	style := lipgloss.NewStyle().Foreground(lipgloss.Color(color)).Bold(true)
	return style.Render(fmt.Sprintf("%s %.0f%%", chars[idx], percent))
}

func makeGaugeWithLabel(label string, percent float64, width int, color string, showLabel bool) string {
	barWidth := width - 20
	if barWidth < 10 {
		barWidth = 10
	}

	filled := int(percent * float64(barWidth) / 100)
	if filled > barWidth {
		filled = barWidth
	}

	// Gradient bar
	var bar strings.Builder
	for i := 0; i < barWidth; i++ {
		if i < filled {
			// Color intensity based on position
			intensity := float64(i) / float64(barWidth)
			if intensity < 0.5 {
				bar.WriteString(lipgloss.NewStyle().
					Foreground(lipgloss.Color(currentTheme.Success)).
					Render("█"))
			} else if intensity < 0.75 {
				bar.WriteString(lipgloss.NewStyle().
					Foreground(lipgloss.Color(currentTheme.Warning)).
					Render("█"))
			} else {
				bar.WriteString(lipgloss.NewStyle().
					Foreground(lipgloss.Color(currentTheme.Error)).
					Render("█"))
			}
		} else {
			bar.WriteString(lipgloss.NewStyle().
				Foreground(lipgloss.Color(currentTheme.Border)).
				Render("░"))
		}
	}

	percentColor := getPercentColor(percent, false)
	percentStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(percentColor)).Bold(true)

	if showLabel {
		return fmt.Sprintf("  %-10s [%s] %s", label, bar.String(), percentStyle.Render(fmt.Sprintf("%5.1f%%", percent)))
	}
	return fmt.Sprintf("  [%s] %s", bar.String(), percentStyle.Render(fmt.Sprintf("%5.1f%%", percent)))
}

func makeHeatMap(data [][]float64, width, height int) string {
	heatChars := []rune{' ', '░', '▒', '▓', '█'}
	heatColors := []string{"#003300", "#006600", "#009900", "#00CC00", "#00FF00"}

	var result strings.Builder
	for y := 0; y < height && y < len(data); y++ {
		for x := 0; x < width && x < len(data[y]); x++ {
			val := data[y][x]
			idx := int(val * 4)
			if idx > 4 {
				idx = 4
			}
			style := lipgloss.NewStyle().Foreground(lipgloss.Color(heatColors[idx]))
			result.WriteString(style.Render(string(heatChars[idx])))
		}
		result.WriteString("\n")
	}

	return result.String()
}

func createGlowBorder(content string, width int, glowColor string, glowPhase float64) string {
	// Animated glow effect
	intensity := (math.Sin(glowPhase) + 1) / 2
	glowStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(glowColor)).
		Width(width).
		Padding(0, 1)

	if intensity > 0.5 {
		glowStyle = glowStyle.Bold(true)
	}

	return glowStyle.Render(content)
}

func animatedTitle(text string, frame int) string {
	colors := []string{currentTheme.Primary, currentTheme.Secondary, currentTheme.Accent}
	offset := frame % len(colors)

	var result strings.Builder
	for i, r := range text {
		colorIdx := (i + offset) % len(colors)
		style := lipgloss.NewStyle().Foreground(lipgloss.Color(colors[colorIdx])).Bold(true)
		result.WriteString(style.Render(string(r)))
	}

	return result.String()
}

func makeStatusIndicator(status string, animated bool, frame int) string {
	var icon, color string
	switch status {
	case "online", "up", "running":
		icon = statusIcons["online"]
		color = currentTheme.Success
	case "offline", "down", "stopped":
		icon = statusIcons["offline"]
		color = currentTheme.Error
	case "warning", "degraded":
		if animated {
			icons := []string{"◐", "◓", "◑", "◒"}
			icon = icons[frame%len(icons)]
		} else {
			icon = statusIcons["warning"]
		}
		color = currentTheme.Warning
	case "loading", "starting":
		if animated {
			icons := []string{"◌", "◎", "●", "◎"}
			icon = icons[frame%len(icons)]
		} else {
			icon = statusIcons["loading"]
		}
		color = currentTheme.Info
	default:
		icon = statusIcons["offline"]
		color = currentTheme.TextMuted
	}

	return lipgloss.NewStyle().Foreground(lipgloss.Color(color)).Render(icon)
}

func calculateHealthScore(info SystemInfo) (int, string) {
	score := 100

	// CPU penalty
	if info.CPUUsage > 90 {
		score -= 30
	} else if info.CPUUsage > 70 {
		score -= 15
	} else if info.CPUUsage > 50 {
		score -= 5
	}

	// Memory penalty
	if info.MemPercent > 90 {
		score -= 25
	} else if info.MemPercent > 80 {
		score -= 15
	} else if info.MemPercent > 70 {
		score -= 5
	}

	// Disk penalty (for each disk over 90%)
	for _, disk := range info.Disks {
		if disk.Percent > 95 {
			score -= 20
		} else if disk.Percent > 90 {
			score -= 10
		} else if disk.Percent > 80 {
			score -= 3
		}
	}

	// Swap usage penalty
	if info.SwapPercent > 50 {
		score -= 10
	}

	// Battery penalty
	if info.HasBattery && info.Battery.Percent < 20 && !info.Battery.PluggedIn {
		score -= 15
	}

	// Ensure bounds
	if score < 0 {
		score = 0
	}
	if score > 100 {
		score = 100
	}

	// Status
	var status string
	switch {
	case score >= 90:
		status = "Excellent"
	case score >= 70:
		status = "Good"
	case score >= 50:
		status = "Fair"
	case score >= 30:
		status = "Poor"
	default:
		status = "Critical"
	}

	return score, status
}

// ══════════════════════════════════════════════════════════════════
//                    EXTENDED DATA COLLECTION
// ══════════════════════════════════════════════════════════════════

func collectBatteryInfo() BatteryInfo {
	info := BatteryInfo{Status: "Not Present"}

	if runtime.GOOS == "windows" {
		cmd := exec.Command("powershell", "-Command",
			"Get-WmiObject Win32_Battery | Select-Object EstimatedChargeRemaining, BatteryStatus | ConvertTo-Csv -NoTypeInformation")
		out, err := cmd.Output()
		if err == nil {
			lines := strings.Split(string(out), "\n")
			if len(lines) >= 2 {
				parts := strings.Split(strings.Trim(lines[1], "\r\n\""), "\",\"")
				if len(parts) >= 2 {
					if p, err := strconv.ParseFloat(strings.Trim(parts[0], "\""), 64); err == nil {
						info.Percent = p
					}
					switch strings.Trim(parts[1], "\"") {
					case "1":
						info.Status = "Discharging"
					case "2":
						info.Status = "Charging"
						info.PluggedIn = true
					case "3":
						info.Status = "Full"
						info.PluggedIn = true
					}
				}
			}
		}
	}

	return info
}

func collectThermalInfo() ThermalInfo {
	info := ThermalInfo{Sensors: make(map[string]float64)}

	if runtime.GOOS == "windows" {
		// Try to get CPU temp via WMI (requires admin)
		cmd := exec.Command("powershell", "-Command",
			"Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace 'root/wmi' 2>$null | Select-Object CurrentTemperature | ConvertTo-Csv -NoTypeInformation")
		out, _ := cmd.Output()
		lines := strings.Split(string(out), "\n")
		if len(lines) >= 2 {
			if temp, err := strconv.ParseFloat(strings.Trim(lines[1], "\r\n\""), 64); err == nil {
				info.CPUTemp = (temp - 2732) / 10 // Convert from decikelvin
			}
		}
	}

	return info
}

func getPublicIP() string {
	// Simple approach - could be enhanced
	cmd := exec.Command("curl", "-s", "ifconfig.me")
	out, err := cmd.Output()
	if err != nil {
		return "N/A"
	}
	return strings.TrimSpace(string(out))
}

func collectSecurityInfo() SecurityInfo {
	info := SecurityInfo{
		Firewall:  "Unknown",
		Antivirus: "Unknown",
		UAC:       "Unknown",
	}

	if runtime.GOOS == "windows" {
		// Firewall status
		cmd := exec.Command("netsh", "advfirewall", "show", "allprofiles", "state")
		out, err := cmd.Output()
		if err == nil {
			if strings.Contains(string(out), "ON") {
				info.Firewall = "Enabled"
			} else {
				info.Firewall = "Disabled"
			}
		}

		// Windows Defender status
		cmd = exec.Command("powershell", "-Command",
			"Get-MpComputerStatus | Select-Object -ExpandProperty AntivirusEnabled")
		out, err = cmd.Output()
		if err == nil {
			if strings.TrimSpace(string(out)) == "True" {
				info.Antivirus = "Windows Defender (Active)"
			}
		}
	}

	return info
}

func collectServices(limit int) []ServiceInfo {
	var services []ServiceInfo

	if runtime.GOOS == "windows" {
		cmd := exec.Command("powershell", "-Command",
			fmt.Sprintf("Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object -First %d Name, DisplayName, Status | ConvertTo-Csv -NoTypeInformation", limit))
		out, err := cmd.Output()
		if err == nil {
			lines := strings.Split(string(out), "\n")
			for i, line := range lines {
				if i == 0 || strings.TrimSpace(line) == "" {
					continue
				}
				parts := strings.Split(line, "\",\"")
				if len(parts) >= 3 {
					services = append(services, ServiceInfo{
						Name:        strings.Trim(parts[0], "\""),
						DisplayName: strings.Trim(parts[1], "\""),
						Status:      strings.Trim(parts[2], "\"\r\n"),
					})
				}
			}
		}
	}

	return services
}

func collectGPUInfo() []GPUInfo {
	var gpus []GPUInfo

	if runtime.GOOS == "windows" {
		cmd := exec.Command("wmic", "path", "win32_VideoController", "get",
			"name,driverversion,adapterram,status", "/format:csv")
		out, err := cmd.Output()
		if err == nil {
			lines := strings.Split(string(out), "\n")
			for _, line := range lines {
				parts := strings.Split(strings.TrimSpace(line), ",")
				if len(parts) >= 5 && parts[1] != "" && parts[1] != "AdapterRAM" {
					gpu := GPUInfo{Name: parts[3], Driver: parts[2]}
					if vram, err := strconv.ParseUint(parts[1], 10, 64); err == nil {
						gpu.VRAM = vram
					}
					gpus = append(gpus, gpu)
				}
			}
		}

		// Try nvidia-smi for NVIDIA GPUs
		cmd = exec.Command("nvidia-smi",
			"--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw,fan.speed",
			"--format=csv,noheader,nounits")
		out, err = cmd.Output()
		if err == nil {
			lines := strings.Split(string(out), "\n")
			for _, line := range lines {
				parts := strings.Split(strings.TrimSpace(line), ", ")
				if len(parts) >= 8 {
					idx, _ := strconv.Atoi(parts[0])
					gpu := GPUInfo{
						Index:  idx,
						Name:   parts[1],
						Vendor: "NVIDIA",
					}
					gpu.Usage, _ = strconv.ParseFloat(parts[2], 64)
					vramUsed, _ := strconv.ParseFloat(parts[3], 64)
					gpu.VRAMUsed = uint64(vramUsed * 1024 * 1024)
					vramTotal, _ := strconv.ParseFloat(parts[4], 64)
					gpu.VRAM = uint64(vramTotal * 1024 * 1024)
					gpu.Temperature, _ = strconv.ParseFloat(parts[5], 64)
					gpu.PowerDraw, _ = strconv.ParseFloat(parts[6], 64)
					gpu.FanSpeed, _ = strconv.ParseFloat(parts[7], 64)

					// Replace or add
					found := false
					for i, g := range gpus {
						if strings.Contains(g.Name, "NVIDIA") || g.Name == gpu.Name {
							gpus[i] = gpu
							found = true
							break
						}
					}
					if !found {
						gpus = append(gpus, gpu)
					}
				}
			}
		}
	}

	return gpus
}

func (m *Model) updateHistory() {
	maxLen := 60 // 60 data points for sparklines

	// Add current values
	m.cpuHistory = append(m.cpuHistory, m.sysInfo.CPUUsage)
	m.memHistory = append(m.memHistory, m.sysInfo.MemPercent)

	// Calculate network delta
	if len(m.sysInfo.Networks) > 0 {
		totalIn := uint64(0)
		totalOut := uint64(0)
		for _, n := range m.sysInfo.Networks {
			totalIn += n.BytesRecv
			totalOut += n.BytesSent
		}
		m.netInHistory = append(m.netInHistory, float64(totalIn))
		m.netOutHistory = append(m.netOutHistory, float64(totalOut))
	}

	// Trim to max length
	if len(m.cpuHistory) > maxLen {
		m.cpuHistory = m.cpuHistory[len(m.cpuHistory)-maxLen:]
	}
	if len(m.memHistory) > maxLen {
		m.memHistory = m.memHistory[len(m.memHistory)-maxLen:]
	}
	if len(m.netInHistory) > maxLen {
		m.netInHistory = m.netInHistory[len(m.netInHistory)-maxLen:]
	}
	if len(m.netOutHistory) > maxLen {
		m.netOutHistory = m.netOutHistory[len(m.netOutHistory)-maxLen:]
	}
}

// ══════════════════════════════════════════════════════════════════
//                         SYSTEM INFO COLLECTION
// ══════════════════════════════════════════════════════════════════

func collectSystemInfo() SystemInfo {
	start := time.Now()
	info := SystemInfo{LastUpdate: time.Now()}

	// Host info
	if h, err := host.Info(); err == nil {
		info.Hostname = h.Hostname
		info.OS = h.OS
		info.Platform = h.Platform + " " + h.PlatformVersion
		info.Kernel = h.KernelVersion
		info.Arch = h.KernelArch
		info.Uptime = time.Duration(h.Uptime) * time.Second
		info.BootTime = time.Unix(int64(h.BootTime), 0)
		info.Procs = h.Procs
	}

	// Username
	if u, err := user.Current(); err == nil {
		info.Username = u.Username
	}

	// Extended Info (Mainboard/BIOS)
	collectExtendedInfo(&info)

	// CPU info - Extended
	if cpuInfo, err := cpu.Info(); err == nil && len(cpuInfo) > 0 {
		info.CPUModel = cpuInfo[0].ModelName
		info.CPUCores = int(cpuInfo[0].Cores)
		info.CPUFreq = cpuInfo[0].Mhz
		info.CPUL2Cache = uint64(cpuInfo[0].CacheSize) * 1024
	}
	info.CPUThreads = runtime.NumCPU()

	// CPU usage
	if usage, err := cpu.Percent(0, false); err == nil && len(usage) > 0 {
		info.CPUUsage = usage[0]
	}
	if perCore, err := cpu.Percent(0, true); err == nil {
		info.CPUPerCore = perCore
	}

	// Memory - Extended
	if m, err := mem.VirtualMemory(); err == nil {
		info.MemTotal = m.Total
		info.MemUsed = m.Used
		info.MemFree = m.Free
		info.MemAvailable = m.Available
		info.MemBuffers = m.Buffers
		info.MemCached = m.Cached
		info.MemPercent = m.UsedPercent
	}
	if s, err := mem.SwapMemory(); err == nil {
		info.SwapTotal = s.Total
		info.SwapUsed = s.Used
		info.SwapFree = s.Free
		info.SwapPercent = s.UsedPercent
	}

	// Disks - Extended
	if partitions, err := disk.Partitions(false); err == nil {
		ioCounters, _ := disk.IOCounters()
		for _, p := range partitions {
			if usage, err := disk.Usage(p.Mountpoint); err == nil {
				diskInfo := DiskInfo{
					Path:    p.Mountpoint,
					Device:  p.Device,
					Fstype:  p.Fstype,
					Total:   usage.Total,
					Used:    usage.Used,
					Free:    usage.Free,
					Percent: usage.UsedPercent,
				}

				// Get I/O stats
				for name, io := range ioCounters {
					if strings.Contains(p.Device, name) || name == p.Device {
						diskInfo.ReadBytes = io.ReadBytes
						diskInfo.WriteBytes = io.WriteBytes
						diskInfo.ReadCount = io.ReadCount
						diskInfo.WriteCount = io.WriteCount
						break
					}
				}

				info.Disks = append(info.Disks, diskInfo)
			}
		}
	}

	// Network - Extended
	if ifaces, err := net.Interfaces(); err == nil {
		ioCounters, _ := net.IOCounters(true)
		ioMap := make(map[string]net.IOCountersStat)
		for _, io := range ioCounters {
			ioMap[io.Name] = io
		}

		for _, iface := range ifaces {
			if len(iface.Flags) == 0 {
				continue
			}

			addrs := []string{}
			for _, a := range iface.Addrs {
				addrs = append(addrs, a.Addr)
			}

			isUp := false
			for _, f := range iface.Flags {
				if f == "up" {
					isUp = true
					break
				}
			}

			netInfo := NetworkInfo{
				Name:  iface.Name,
				MAC:   iface.HardwareAddr,
				Addrs: addrs,
				IsUp:  isUp,
				MTU:   iface.MTU,
			}

			// Check if wireless
			netInfo.IsWireless = strings.Contains(strings.ToLower(iface.Name), "wi") ||
				strings.Contains(strings.ToLower(iface.Name), "wlan") ||
				strings.Contains(strings.ToLower(iface.Name), "wireless")

			if io, ok := ioMap[iface.Name]; ok {
				netInfo.BytesSent = io.BytesSent
				netInfo.BytesRecv = io.BytesRecv
				netInfo.PacketsSent = io.PacketsSent
				netInfo.PacketsRecv = io.PacketsRecv
				netInfo.ErrorsIn = io.Errin
				netInfo.ErrorsOut = io.Errout
				netInfo.DropIn = io.Dropin
				netInfo.DropOut = io.Dropout
			}

			info.Networks = append(info.Networks, netInfo)
		}
	}

	// GPU
	info.GPUs = collectGPUInfo()

	// Battery
	info.Battery = collectBatteryInfo()
	info.HasBattery = info.Battery.Status != "Not Present"

	// Thermal
	info.Thermal = collectThermalInfo()
	info.HasThermal = info.Thermal.CPUTemp > 0

	// Security
	info.Security = collectSecurityInfo()

	// Services (top 10 running)
	info.Services = collectServices(10)

	// Top processes
	info.TopCPU = getTopProcesses("cpu", 8)
	info.TopMem = getTopProcesses("mem", 8)

	// Count total processes
	if procs, err := process.Processes(); err == nil {
		info.TotalProcs = len(procs)
	}

	// Calculate health
	info.HealthScore, info.HealthStatus = calculateHealthScore(info)

	info.CollectTime = time.Since(start)

	return info
}

func collectExtendedInfo(info *SystemInfo) {
	if runtime.GOOS != "windows" {
		return
	}

	// BaseBoard
	cmd := exec.Command("wmic", "baseboard", "get", "product,manufacturer,serialnumber", "/format:csv")
	if out, err := cmd.Output(); err == nil {
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			parts := strings.Split(strings.TrimSpace(line), ",")
			if len(parts) >= 4 && parts[1] != "Manufacturer" {
				info.BoardVendor = parts[1]
				info.BoardName = parts[2]
				info.ProductSerial = parts[3]
				break
			}
		}
	}

	// BIOS
	cmd = exec.Command("wmic", "bios", "get", "smbiosbiosversion", "/format:csv")
	if out, err := cmd.Output(); err == nil {
		lines := strings.Split(string(out), "\n")
		for _, line := range lines {
			parts := strings.Split(strings.TrimSpace(line), ",")
			if len(parts) >= 2 && parts[1] != "SMBIOSBIOSVersion" {
				info.BiosVersion = parts[1]
				break
			}
		}
	}
}

func getTopProcesses(sortBy string, limit int) []ProcessInfo {
	procs, err := process.Processes()
	if err != nil {
		return nil
	}

	var result []ProcessInfo
	for _, p := range procs {
		name, _ := p.Name()
		cpuP, _ := p.CPUPercent()
		memP, _ := p.MemoryPercent()
		memInfo, _ := p.MemoryInfo()

		memMB := float64(0)
		if memInfo != nil {
			memMB = float64(memInfo.RSS) / 1024 / 1024
		}

		result = append(result, ProcessInfo{
			PID:    p.Pid,
			Name:   name,
			CPU:    cpuP,
			Memory: float64(memP),
			MemMB:  memMB,
		})
	}

	if sortBy == "cpu" {
		sort.Slice(result, func(i, j int) bool {
			return result[i].CPU > result[j].CPU
		})
	} else {
		sort.Slice(result, func(i, j int) bool {
			return result[i].Memory > result[j].Memory
		})
	}

	if len(result) > limit {
		result = result[:limit]
	}
	return result
}

func getWindowsGPU() (name, driver string, vram uint64) {
	cmd := exec.Command("wmic", "path", "win32_VideoController", "get", "name,driverversion,adapterram", "/format:csv")
	out, err := cmd.Output()
	if err != nil {
		return "", "", 0
	}

	lines := strings.Split(string(out), "\n")
	for _, line := range lines {
		parts := strings.Split(strings.TrimSpace(line), ",")
		if len(parts) >= 4 && parts[1] != "" && parts[1] != "AdapterRAM" {
			vramStr := parts[1]
			if v, err := strconv.ParseUint(vramStr, 10, 64); err == nil {
				vram = v
			}
			driver = parts[2]
			name = parts[3]
			return
		}
	}
	return "", "", 0
}

// ══════════════════════════════════════════════════════════════════
//                         INITIALIZATION
// ══════════════════════════════════════════════════════════════════

func initialModel() *Model {
	themeNames := []string{"Neon Synthwave", "Cyber Matrix", "Cyberpunk 2077", "Ocean Depths", "Blood Moon", "Aurora Borealis"}

	return &Model{
		loading:    true,
		loadingMsg: "Initializing system scanner...",
		tabs: []Tab{
			{ID: "dashboard", Name: "Dashboard", Icon: "🎛️", Color: "#00FFFF"},
			{ID: "cpu", Name: "CPU", Icon: "⚡", Color: "#FFFF00"},
			{ID: "memory", Name: "Memory", Icon: "🧠", Color: "#FF00FF"},
			{ID: "gpu", Name: "GPU", Icon: "🎮", Color: "#FF6B6B"},
			{ID: "disk", Name: "Storage", Icon: "💾", Color: "#00FF88"},
			{ID: "network", Name: "Network", Icon: "🌐", Color: "#00BFFF"},
			{ID: "process", Name: "Processes", Icon: "📊", Color: "#FFA500"},
			{ID: "security", Name: "Security", Icon: "🛡️", Color: "#22C55E"},
			{ID: "system", Name: "System", Icon: "⚙️", Color: "#A78BFA"},
		},
		hoverTab:    -1,
		startTime:   time.Now(),
		themeNames:  themeNames,
		borderStyle: "rounded",
		chartMode:   "sparkline",
		cpuHistory:  make([]float64, 0, 60),
		memHistory:  make([]float64, 0, 60),
	}
}

func (m *Model) Init() tea.Cmd {
	return tea.Batch(
		tea.EnableMouseAllMotion,
		tickCmd(),
		fetchSysInfo,
	)
}

func tickCmd() tea.Cmd {
	return tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func fetchSysInfo() tea.Msg {
	return sysInfoMsg(collectSystemInfo())
}

// ══════════════════════════════════════════════════════════════════
//                         HELPERS
// ══════════════════════════════════════════════════════════════════

func formatBytes(b uint64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := uint64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.2f %cB", float64(b)/float64(div), "KMGTPE"[exp])
}

func formatDuration(d time.Duration) string {
	days := int(d.Hours() / 24)
	hours := int(d.Hours()) % 24
	mins := int(d.Minutes()) % 60
	secs := int(d.Seconds()) % 60

	if days > 0 {
		return fmt.Sprintf("%dd %dh %dm", days, hours, mins)
	}
	if hours > 0 {
		return fmt.Sprintf("%dh %dm %ds", hours, mins, secs)
	}
	if mins > 0 {
		return fmt.Sprintf("%dm %ds", mins, secs)
	}
	return fmt.Sprintf("%ds", secs)
}

func getPercentColor(percent float64, inverted bool) string {
	if inverted {
		if percent >= 70 {
			return currentTheme.Success
		}
		if percent >= 40 {
			return currentTheme.Warning
		}
		return currentTheme.Error
	}
	if percent >= 90 {
		return currentTheme.Error
	}
	if percent >= 70 {
		return currentTheme.Warning
	}
	return currentTheme.Success
}

func makeProgressBar(percent float64, width int, style string) string {
	if width < 5 {
		width = 5
	}
	filled := int(math.Round(percent * float64(width) / 100))
	if filled > width {
		filled = width
	}
	empty := width - filled

	var bar string
	switch style {
	case "block":
		bar = strings.Repeat("█", filled) + strings.Repeat("░", empty)
	case "gradient":
		bar = strings.Repeat("█", filled) + strings.Repeat("▒", min(1, empty)) + strings.Repeat("░", max(0, empty-1))
	case "dots":
		bar = strings.Repeat("●", filled) + strings.Repeat("○", empty)
	case "line":
		bar = strings.Repeat("━", filled) + strings.Repeat("─", empty)
	case "fancy":
		bar = strings.Repeat("▰", filled) + strings.Repeat("▱", empty)
	default:
		bar = strings.Repeat("█", filled) + strings.Repeat("░", empty)
	}

	color := getPercentColor(percent, false)
	barStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(color))

	return barStyle.Render(bar)
}

func gradientText(text string, colors []string) string {
	if len(colors) == 0 || len(text) == 0 {
		return text
	}

	runes := []rune(text)
	var result strings.Builder

	for i, r := range runes {
		progress := float64(i) / math.Max(1, float64(len(runes)-1))
		colorIdx := int(progress * float64(len(colors)-1))
		if colorIdx >= len(colors) {
			colorIdx = len(colors) - 1
		}
		style := lipgloss.NewStyle().Foreground(lipgloss.Color(colors[colorIdx]))
		result.WriteString(style.Render(string(r)))
	}

	return result.String()
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

// ══════════════════════════════════════════════════════════════════
//                         UPDATE
// ══════════════════════════════════════════════════════════════════

func (m *Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tickMsg:
		m.frame++
		m.glowPhase += 0.1
		m.pulsePhase = (m.pulsePhase + 1) % 100
		m.waveOffset = (m.waveOffset + 1) % 50

		if m.loading {
			m.loadingStep++
		}

		if m.exportFade > 0 {
			m.exportFade--
			if m.exportFade == 0 {
				m.exported = false
			}
		}

		// Update notifications
		for i := range m.notifications {
			if m.notifications[i].Fade > 0 {
				m.notifications[i].Fade--
			}
		}
		// Remove faded notifications
		newNotifs := make([]Notification, 0)
		for _, n := range m.notifications {
			if n.Fade > 0 {
				newNotifs = append(newNotifs, n)
			}
		}
		m.notifications = newNotifs

		// Periodic data refresh (every 30 seconds)
		if m.frame%300 == 0 && !m.loading {
			m.loading = true
			m.loadingStep = 0
			return m, fetchSysInfo
		}

		return m, tickCmd()

	case sysInfoMsg:
		m.sysInfo = SystemInfo(msg)
		m.loading = false
		
		// Update history
		m.updateHistory()

		// Check for alerts
		if m.sysInfo.CPUUsage > 90 {
			m.notifications = append(m.notifications, Notification{
				Message:   "⚠️ High CPU usage detected!",
				Type:      "warning",
				Timestamp: time.Now(),
				Fade:      50,
			})
		}
		if m.sysInfo.MemPercent > 90 {
			m.notifications = append(m.notifications, Notification{
				Message:   "⚠️ High memory usage detected!",
				Type:      "warning",
				Timestamp: time.Now(),
				Fade:      50,
			})
		}

		return m, nil

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.isMobile = m.width < 80
		m.isCompact = m.width < 100
		m.isUltraWide = m.width > 180
		return m, nil

	case tea.KeyMsg:
		return m.handleKey(msg)

	case tea.MouseMsg:
		return m.handleMouse(msg)
	}

	return m, nil
}

func (m *Model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		return m, tea.Quit

	case "left", "h":
		if m.activeTab > 0 {
			m.activeTab--
			m.scrollY = 0
		}

	case "right", "l":
		if m.activeTab < len(m.tabs)-1 {
			m.activeTab++
			m.scrollY = 0
		}

	case "tab":
		m.activeTab = (m.activeTab + 1) % len(m.tabs)
		m.scrollY = 0

	case "shift+tab":
		m.activeTab = (m.activeTab - 1 + len(m.tabs)) % len(m.tabs)
		m.scrollY = 0

	case "up", "k":
		if m.scrollY > 0 {
			m.scrollY -= 2 // Faster scroll
		}

	case "down", "j":
		m.scrollY += 2 // Faster scroll

	case "pgup":
		m.scrollY -= 10
		if m.scrollY < 0 {
			m.scrollY = 0
		}

	case "pgdown":
		m.scrollY += 10

	case "home":
		m.scrollY = 0

	case "end":
		m.scrollY = 9999 // Will be capped in renderContent

	case "r":
		m.loading = true
		m.loadingStep = 0
		return m, fetchSysInfo

	case "t":
		m.themeIndex = (m.themeIndex + 1) % len(m.themeNames)
		currentTheme = themes[m.themeNames[m.themeIndex]]

	case "b": // Border style toggle
		borderNames := []string{"rounded", "sharp", "double", "thick", "neon"}
		currentIdx := 0
		for i, n := range borderNames {
			if n == m.borderStyle {
				currentIdx = i
				break
			}
		}
		m.borderStyle = borderNames[(currentIdx+1)%len(borderNames)]

	case "c": // Chart mode toggle
		modes := []string{"sparkline", "bar", "area"}
		currentIdx := 0
		for i, mode := range modes {
			if mode == m.chartMode {
				currentIdx = i
				break
			}
		}
		m.chartMode = modes[(currentIdx+1)%len(modes)]

	case "d": // Toggle detail mode
		m.detailMode = !m.detailMode

	case "e":
		m.exported = true
		m.exportFade = 30
		exportReport(m.sysInfo)

	case "1", "2", "3", "4", "5", "6", "7", "8", "9":
		idx, _ := strconv.Atoi(msg.String())
		if idx-1 < len(m.tabs) {
			m.activeTab = idx - 1
			m.scrollY = 0
		}

	case "?", "f1": // Help
		// Could add a help overlay

	case "esc":
		if m.filterActive {
			m.filterActive = false
			m.filterText = ""
		}
	}

	return m, nil
}

func (m *Model) handleMouse(msg tea.MouseMsg) (tea.Model, tea.Cmd) {
	m.mouseX = msg.X
	m.mouseY = msg.Y

	oldHoverTab := m.hoverTab
	m.hoverTab = -1
	m.hoverBtn = ""

	// Check hitboxes
	for _, hb := range m.hitBoxes {
		if m.mouseX >= hb.X && m.mouseX < hb.X+hb.W &&
			m.mouseY >= hb.Y && m.mouseY < hb.Y+hb.H {
			switch hb.Type {
			case "tab":
				m.hoverTab = hb.Index
			case "button":
				m.hoverBtn = hb.Action
			}
		}
	}

	switch msg.Type {
	case tea.MouseLeft:
		if m.hoverTab >= 0 {
			m.activeTab = m.hoverTab
			m.scrollY = 0
		}
		if m.hoverBtn == "refresh" {
			m.loading = true
			m.loadingStep = 0
			return m, fetchSysInfo
		}
		if m.hoverBtn == "theme" {
			m.themeIndex = (m.themeIndex + 1) % len(m.themeNames)
			currentTheme = themes[m.themeNames[m.themeIndex]]
		}
		if m.hoverBtn == "export" {
			m.exported = true
			m.exportFade = 30
			exportReport(m.sysInfo)
		}

	case tea.MouseWheelUp:
		if m.scrollY > 0 {
			m.scrollY--
		}

	case tea.MouseWheelDown:
		m.scrollY++
	}

	_ = oldHoverTab
	return m, nil
}

func exportReport(info SystemInfo) {
	// Create report file
	homeDir, _ := os.UserHomeDir()
	filename := fmt.Sprintf("%s/Desktop/SystemReport_%s.txt",
		homeDir, time.Now().Format("20060102_150405"))

	report := fmt.Sprintf(`
================================================================================
                      SYSTEM INFORMATION REPORT
                      Generated: %s
================================================================================

SYSTEM OVERVIEW
---------------
Hostname       : %s
User           : %s
OS             : %s
Platform       : %s
Kernel         : %s
Architecture   : %s
Uptime         : %s
Boot Time      : %s
Processes      : %d

CPU INFORMATION
---------------
Model          : %s
Cores          : %d
Threads        : %d
Frequency      : %.2f MHz
Usage          : %.1f%%

MEMORY
------
Total          : %s
Used           : %s
Free           : %s
Usage          : %.1f%%
Swap Total     : %s
Swap Used      : %s

DISK DRIVES
-----------
%s

NETWORK ADAPTERS
----------------
%s

================================================================================
                              End of Report
================================================================================
`,
		time.Now().Format("2006-01-02 15:04:05"),
		info.Hostname, info.Username, info.OS, info.Platform,
		info.Kernel, info.Arch, formatDuration(info.Uptime),
		info.BootTime.Format("2006-01-02 15:04:05"), info.Procs,
		info.CPUModel, info.CPUCores, info.CPUThreads, info.CPUFreq, info.CPUUsage,
		formatBytes(info.MemTotal), formatBytes(info.MemUsed),
		formatBytes(info.MemFree), info.MemPercent,
		formatBytes(info.SwapTotal), formatBytes(info.SwapUsed),
		formatDisksReport(info.Disks),
		formatNetworkReport(info.Networks),
	)

	os.WriteFile(filename, []byte(report), 0644)
}

func formatDisksReport(disks []DiskInfo) string {
	var sb strings.Builder
	for _, d := range disks {
		sb.WriteString(fmt.Sprintf("Drive %s (%s)\n", d.Path, d.Fstype))
		sb.WriteString(fmt.Sprintf("  Total: %s, Used: %s, Free: %s, Usage: %.1f%%\n\n",
			formatBytes(d.Total), formatBytes(d.Used), formatBytes(d.Free), d.Percent))
	}
	return sb.String()
}

func formatNetworkReport(nets []NetworkInfo) string {
	var sb strings.Builder
	for _, n := range nets {
		status := "Down"
		if n.IsUp {
			status = "Up"
		}
		sb.WriteString(fmt.Sprintf("%s [%s]\n", n.Name, status))
		sb.WriteString(fmt.Sprintf("  MAC: %s\n", n.MAC))
		sb.WriteString(fmt.Sprintf("  Sent: %s, Recv: %s\n\n",
			formatBytes(n.BytesSent), formatBytes(n.BytesRecv)))
	}
	return sb.String()
}

// ══════════════════════════════════════════════════════════════════
//                         VIEW
// ══════════════════════════════════════════════════════════════════

func (m *Model) View() string {
	if m.width < 60 || m.height < 20 {
		return lipgloss.Place(m.width, m.height,
			lipgloss.Center, lipgloss.Center,
			lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Warning)).
				Render("Please resize terminal (60x20 min)"))
	}

	if m.loading {
		return m.renderLoading()
	}

	// Reset hitboxes for the current frame
	m.hitBoxes = make([]HitBox, 0)

	// Render sections and track heights
	headerStr := m.renderHeader()
	headerHeight := lipgloss.Height(headerStr)

	tabsStr := m.renderTabs(headerHeight)
	tabsHeight := lipgloss.Height(tabsStr)

	contentHeight := m.height - headerHeight - tabsHeight - 3 // 3 for footer and padding
	if contentHeight < 10 { contentHeight = 10 }

	contentStr := m.renderContent(headerHeight + tabsHeight, contentHeight)
	
	footerStr := m.renderFooter()

	return lipgloss.JoinVertical(lipgloss.Left,
		headerStr,
		tabsStr,
		contentStr,
		footerStr,
	)
}

func (m *Model) renderLoading() string {
	logo := `
  ╔══════════════════════════════════════════════════════════════════════════╗
  ║                                                                          ║
  ║   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗                  ║
  ║   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║                  ║
  ║   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║                  ║
  ║   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║                  ║
  ║   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║                  ║
  ║   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝                  ║
  ║                                                                          ║
  ║   ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗  █████╗ ██████╗ ██████╗║
  ║   ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗
  ║   ██║  ██║███████║███████╗███████║██████╔╝██║   ██║███████║██████╔╝██║  ██║║
  ║   ██║  ██║██╔══██║╚════██║██╔══██║██╔══██╗██║   ██║██╔══██║██╔══██╗██║  ██║║
  ║   ██████╔╝██║  ██║███████║██║  ██║██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝║
  ║   ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ║
  ║                                                                          ║
  ║                    ═══════════════════════════════                       ║
  ║                         ULTRA SYSTEM MONITOR                              ║
  ║                           Version 4.0 PRO                                 ║
  ║                    ═══════════════════════════════                       ║
  ║                                                                          ║
  ╚══════════════════════════════════════════════════════════════════════════╝
`

	// Animated colors
	gradientNames := []string{"cyber", "fire", "rainbow", "ocean", "matrix"}
	currentGrad := gradients[gradientNames[(m.frame/30)%len(gradientNames)]]
	if len(currentGrad) == 0 {
		currentGrad = []string{"#00FFFF", "#FF00FF", "#FFFFFF"}
	}

	var view strings.Builder

	// Logo with animated gradient
	lines := strings.Split(logo, "\n")
	for i, line := range lines {
		// Shift colors based on line and frame
		colorOffset := (i + m.frame/5) % len(currentGrad)
		shiftedColors := append(currentGrad[colorOffset:], currentGrad[:colorOffset]...)
		view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
			gradientText(line, shiftedColors)) + "\n")
	}

	// Animated spinners row
	spinnerTypes := []string{"braille", "dots", "pulse", "circle"}
	var spinnerRow strings.Builder
	for i, spinType := range spinnerTypes {
		spinnerSlice := spinners[spinType]
		if len(spinnerSlice) == 0 {
			spinnerSlice = []string{"-"}
		}
		spinner := spinnerSlice[m.frame%len(spinnerSlice)]
		color := currentGrad[i%len(currentGrad)]
		style := lipgloss.NewStyle().Foreground(lipgloss.Color(color)).Bold(true)
		spinnerRow.WriteString(style.Render(spinner) + "  ")
	}
	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center, spinnerRow.String()) + "\n\n")

	// Loading message with typing effect
	phases := []struct {
		icon    string
		message string
		color   string
	}{
		{"🔍", "Scanning Hardware Components...", currentTheme.Info},
		{"⚡", "Analyzing CPU Performance...", currentTheme.CPU},
		{"🧠", "Measuring Memory Usage...", currentTheme.RAM},
		{"🎮", "Detecting Graphics Cards...", currentTheme.GPU},
		{"💾", "Mapping Storage Devices...", currentTheme.Disk},
		{"🌐", "Probing Network Interfaces...", currentTheme.Network},
		{"🔒", "Checking Security Status...", currentTheme.Success},
		{"📊", "Gathering Process Data...", currentTheme.Warning},
		{"🔧", "Finalizing System Analysis...", currentTheme.Secondary},
		{"✨", "Preparing Dashboard...", currentTheme.Accent},
	}

	currentPhase := phases[m.loadingStep%len(phases)]
	
	msgStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(currentPhase.color)).
		Bold(true)

	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		fmt.Sprintf("%s %s", currentPhase.icon, msgStyle.Render(currentPhase.message))) + "\n\n")

	// Fancy progress bar
	progress := (m.loadingStep * 10) % 100
	barWidth := 50

	var progressBar strings.Builder
	progressBar.WriteString("  ▐")
	for i := 0; i < barWidth; i++ {
		if float64(i)/float64(barWidth)*100 < float64(progress) {
			// Animated wave effect
			wave := math.Sin(float64(i+m.frame)/3) * 0.5 + 0.5
			if wave > 0.5 {
				progressBar.WriteString(lipgloss.NewStyle().
					Foreground(lipgloss.Color(currentTheme.Primary)).Render("█"))
			} else {
				progressBar.WriteString(lipgloss.NewStyle().
					Foreground(lipgloss.Color(currentTheme.Secondary)).Render("▓"))
			}
		} else {
			progressBar.WriteString(lipgloss.NewStyle().
				Foreground(lipgloss.Color(currentTheme.Border)).Render("░"))
		}
	}
	progressBar.WriteString("▌")

	percentStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(currentTheme.Accent)).
		Bold(true)

	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		progressBar.String()+" "+percentStyle.Render(fmt.Sprintf("%d%%", progress))) + "\n\n")

	// Bottom decoration
	decorLine := strings.Repeat("═", 60)
	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Border)).Render(decorLine)) + "\n")

	// Tips rotating
	tips := []string{
		"💡 TIP: Press [T] to change themes",
		"💡 TIP: Use mouse wheel to scroll",
		"💡 TIP: Press [E] to export report",
		"💡 TIP: Press [R] to refresh data",
		"💡 TIP: Click tabs to navigate",
	}
	tipStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.TextMuted)).Italic(true)
	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		tipStyle.Render(tips[m.frame/50%len(tips)])) + "\n")

	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, view.String())
}

func (m Model) renderHeader() string {
	var header strings.Builder

	if m.width < 90 {
		// Ultra Compact Header
		pulse := ultraSpinners["neon"][m.frame%len(ultraSpinners["neon"])]
		title := fmt.Sprintf("%s SYSTEM MONITOR %s", pulse, pulse)
		header.WriteString("\n" + lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
			animatedTitle(title, m.frame)) + "\n")
	} else {
		// Full Cyber Logo
		logo := `
   ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
   ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
   ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
   ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
   ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
   ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝`

		gradientNames := []string{"cyber", "rainbow", "matrix"}
		currentGrad := gradients[gradientNames[(m.frame/40)%len(gradientNames)]]

		lines := strings.Split(logo, "\n")
		for i, line := range lines {
			if strings.TrimSpace(line) == "" { continue }
			colorOffset := (i + m.frame/8) % len(currentGrad)
			shiftedColors := append(currentGrad[colorOffset:], currentGrad[:colorOffset]...)
			header.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
				gradientText(line, shiftedColors)) + "\n")
		}
	}

	// Dynamic Subtitle
	subtitle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(currentTheme.Accent)).
		Bold(true).
		Render(fmt.Sprintf("─── [ THEME: %s ] ───", currentTheme.Name))

	header.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center, subtitle) + "\n")

	return header.String()
}

func (m *Model) renderTabs(yOffset int) string {
	var tabs []string

	for i, tab := range m.tabs {
		isActive := i == m.activeTab
		isHovered := i == m.hoverTab

		tabWidth := (m.width - 8) / len(m.tabs)
		posX := 4 + (i * tabWidth)

		// Accurate hitbox placement
		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: posX, Y: yOffset, W: tabWidth - 2, H: 1,
			Type: "tab", Index: i,
		})

		var style lipgloss.Style
		if isActive {
			style = lipgloss.NewStyle().
				Background(lipgloss.Color(tab.Color)).
				Foreground(lipgloss.Color("#000000")).
				Bold(true).
				Padding(0, 1).
				Width(tabWidth - 2)
		} else if isHovered {
			style = lipgloss.NewStyle().
				Background(lipgloss.Color(currentTheme.Surface)).
				Foreground(lipgloss.Color(tab.Color)).
				Padding(0, 1).
				Width(tabWidth - 2)
		} else {
			style = lipgloss.NewStyle().
				Foreground(lipgloss.Color(currentTheme.TextMuted)).
				Padding(0, 1).
				Width(tabWidth - 2)
		}

		indicator := "  "
		if isActive {
			indicator = "▶ "
		} else if isHovered {
			indicator = "› "
		}

		content := fmt.Sprintf("%s%s %s", indicator, tab.Icon, tab.Name)
		tabs = append(tabs, style.Render(content))
	}

	row := lipgloss.JoinHorizontal(lipgloss.Top, tabs...)
	return lipgloss.PlaceHorizontal(m.width, lipgloss.Center, row) + "\n"
}

func (m *Model) renderContent(yOffset, height int) string {
	var content string
	switch m.tabs[m.activeTab].ID {
	case "dashboard":
		content = m.renderDashboard(yOffset)
	case "cpu":
		content = m.renderCPU()
	case "memory":
		content = m.renderMemory()
	case "gpu":
		content = m.renderGPU()
	case "disk":
		content = m.renderDisks()
	case "network":
		content = m.renderNetwork()
	case "process":
		content = m.renderProcesses()
	case "security":
		content = m.renderSecurity()
	case "system":
		content = m.renderSystemDetails()
	default:
		content = m.renderDashboard(yOffset)
	}

	// Apply scroll
	lines := strings.Split(content, "\n")
	if m.scrollY >= len(lines) {
		m.scrollY = max(0, len(lines)-1)
	}
	end := min(m.scrollY+height, len(lines))
	visibleLines := lines[m.scrollY:end]

	// Add scroll indicator
	if len(lines) > height {
		scrollPercent := float64(m.scrollY) / float64(len(lines)-height) * 100
		scrollIndicator := lipgloss.NewStyle().
			Foreground(lipgloss.Color(currentTheme.TextMuted)).
			Render(fmt.Sprintf(" ↕ Scroll: %.0f%% (%d/%d lines)", scrollPercent, m.scrollY+1, len(lines)))

		visibleLines = append(visibleLines, scrollIndicator)
	}

	return strings.Join(visibleLines, "\n")
}

func (m Model) renderOverview() string {
	info := m.sysInfo
	var s strings.Builder

	// System box
	s.WriteString(m.renderBox("🖥️ SYSTEM OVERVIEW", currentTheme.Success, func() string {
		var content strings.Builder
		content.WriteString(m.renderInfoLine("Computer", info.Hostname, currentTheme.Accent))
		content.WriteString(m.renderInfoLine("User", info.Username, currentTheme.Primary))
		content.WriteString(m.renderInfoLine("OS", info.OS, currentTheme.Text))
		content.WriteString(m.renderInfoLine("Platform", info.Platform, currentTheme.Text))
		content.WriteString(m.renderInfoLine("Kernel", info.Kernel, currentTheme.TextMuted))
		content.WriteString(m.renderInfoLine("Arch", info.Arch, currentTheme.Info))
		content.WriteString(m.renderInfoLine("Uptime", formatDuration(info.Uptime), currentTheme.Warning))
		content.WriteString(m.renderInfoLine("Processes", fmt.Sprintf("%d", info.Procs), currentTheme.Primary))
		return content.String()
	}))

	// Hardware Info box (New)
	s.WriteString("\n")
	s.WriteString(m.renderBox("🛠️ HARDWARE DETAILS", currentTheme.Info, func() string {
		var content strings.Builder
		if info.BoardName != "" {
			content.WriteString(m.renderInfoLine("Mainboard", info.BoardVendor+" "+info.BoardName, currentTheme.Secondary))
		}
		if info.BiosVersion != "" {
			content.WriteString(m.renderInfoLine("BIOS Ver", info.BiosVersion, currentTheme.TextMuted))
		}
		if info.ProductSerial != "" {
			content.WriteString(m.renderInfoLine("Serial #", info.ProductSerial, currentTheme.TextMuted))
		}
		if len(info.GPUs) > 0 {
			gpu := info.GPUs[0]
			content.WriteString(m.renderInfoLine("GPU", gpu.Name, currentTheme.GPU))
			content.WriteString(m.renderInfoLine("VRAM", formatBytes(gpu.VRAM), currentTheme.Text))
			content.WriteString(m.renderInfoLine("Driver", gpu.Driver, currentTheme.TextMuted))
		}
		return content.String()
	}))

	// Quick stats
	s.WriteString("\n")
	s.WriteString(m.renderBox("📊 QUICK STATS", currentTheme.Warning, func() string {
		var content strings.Builder

		// CPU gauge
		content.WriteString(m.renderGauge("CPU", info.CPUUsage, currentTheme.CPU))
		// RAM gauge
		content.WriteString(m.renderGauge("RAM", info.MemPercent, currentTheme.RAM))
		// Primary disk
		if len(info.Disks) > 0 {
			content.WriteString(m.renderGauge("Disk", info.Disks[0].Percent, currentTheme.Disk))
		}

		return content.String()
	}))

	return s.String()
}

func (m Model) renderCPU() string {
	info := m.sysInfo
	var s strings.Builder

	s.WriteString(m.renderBox("⚙️ CPU INFORMATION", currentTheme.CPU, func() string {
		var content strings.Builder
		content.WriteString(m.renderInfoLine("Model", info.CPUModel, currentTheme.Text))
		content.WriteString(m.renderInfoLine("Cores", fmt.Sprintf("%d physical, %d logical", info.CPUCores, info.CPUThreads), currentTheme.Primary))
		content.WriteString(m.renderInfoLine("Frequency", fmt.Sprintf("%.2f MHz", info.CPUFreq), currentTheme.Warning))
		content.WriteString("\n")
		content.WriteString(m.renderGauge("Usage", info.CPUUsage, currentTheme.CPU))
		return content.String()
	}))

	// Per-core usage
	if len(info.CPUPerCore) > 0 {
		s.WriteString("\n")
		s.WriteString(m.renderBox("📊 PER-CORE USAGE", currentTheme.Info, func() string {
			var content strings.Builder
			for i, usage := range info.CPUPerCore {
				if i >= 8 { // Limit display
					content.WriteString(fmt.Sprintf("  ... and %d more cores\n", len(info.CPUPerCore)-8))
					break
				}
				label := fmt.Sprintf("Core %d", i)
				content.WriteString(m.renderMiniGauge(label, usage))
			}
			return content.String()
		}))
	}

	return s.String()
}

func (m Model) renderMemory() string {
	info := m.sysInfo
	var s strings.Builder

	s.WriteString(m.renderBox("🧠 MEMORY (RAM)", currentTheme.RAM, func() string {
		var content strings.Builder
		content.WriteString(m.renderInfoLine("Total", formatBytes(info.MemTotal), currentTheme.Text))
		content.WriteString(m.renderInfoLine("Used", formatBytes(info.MemUsed), currentTheme.Warning))
		content.WriteString(m.renderInfoLine("Free", formatBytes(info.MemFree), currentTheme.Success))
		content.WriteString("\n")
		content.WriteString(m.renderGauge("Usage", info.MemPercent, currentTheme.RAM))

		// Visual breakdown
		usedBlocks := int(info.MemPercent / 5)
		freeBlocks := 20 - usedBlocks
		breakdown := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Error)).Render(strings.Repeat("▓", usedBlocks))
		breakdown += lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Success)).Render(strings.Repeat("░", freeBlocks))
		content.WriteString(fmt.Sprintf("  Breakdown: %s\n", breakdown))

		return content.String()
	}))

	if info.SwapTotal > 0 {
		s.WriteString("\n")
		s.WriteString(m.renderBox("💫 SWAP", currentTheme.Secondary, func() string {
			var content strings.Builder
			content.WriteString(m.renderInfoLine("Total", formatBytes(info.SwapTotal), currentTheme.Text))
			content.WriteString(m.renderInfoLine("Used", formatBytes(info.SwapUsed), currentTheme.Warning))
			content.WriteString(m.renderGauge("Usage", info.SwapPercent, currentTheme.Secondary))
			return content.String()
		}))
	}

	return s.String()
}

func (m Model) renderDisks() string {
	info := m.sysInfo
	var s strings.Builder

	for i, disk := range info.Disks {
		icon := "💾"
		if i == 0 {
			icon = "🗄️"
		}

		s.WriteString(m.renderBox(fmt.Sprintf("%s DRIVE %s", icon, disk.Path), currentTheme.Disk, func() string {
			var content strings.Builder
			content.WriteString(m.renderInfoLine("Device", disk.Device, currentTheme.TextMuted))
			content.WriteString(m.renderInfoLine("Type", disk.Fstype, currentTheme.Info))
			content.WriteString(m.renderInfoLine("Total", formatBytes(disk.Total), currentTheme.Text))
			content.WriteString(m.renderInfoLine("Used", formatBytes(disk.Used), currentTheme.Warning))
			content.WriteString(m.renderInfoLine("Free", formatBytes(disk.Free), currentTheme.Success))
			content.WriteString("\n")
			content.WriteString(m.renderGauge("Usage", disk.Percent, currentTheme.Disk))
			return content.String()
		}))
		s.WriteString("\n")
	}

	return s.String()
}

func (m Model) renderNetwork() string {
	info := m.sysInfo
	var s strings.Builder

	for _, net := range info.Networks {
		if !net.IsUp {
			continue
		}

		statusColor := currentTheme.Success
		status := "● UP"

		s.WriteString(m.renderBox(fmt.Sprintf("📡 %s", net.Name), currentTheme.Network, func() string {
			var content strings.Builder

			statusStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(statusColor)).Bold(true)
			content.WriteString(fmt.Sprintf("  Status: %s\n", statusStyle.Render(status)))

			content.WriteString(m.renderInfoLine("MAC", net.MAC, currentTheme.Secondary))

			for _, addr := range net.Addrs {
				if strings.Contains(addr, ".") {
					content.WriteString(m.renderInfoLine("IPv4", addr, currentTheme.Success))
				} else if strings.Contains(addr, ":") && !strings.HasPrefix(addr, "fe80") {
					content.WriteString(m.renderInfoLine("IPv6", addr, currentTheme.TextMuted))
				}
			}

			content.WriteString("\n")
			sentStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Success))
			recvStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Primary))
			content.WriteString(fmt.Sprintf("  Traffic: %s ▲ %s  %s ▼ %s\n",
				sentStyle.Render(formatBytes(net.BytesSent)),
				sentStyle.Render(""),
				recvStyle.Render(formatBytes(net.BytesRecv)),
				recvStyle.Render("")))

			return content.String()
		}))
		s.WriteString("\n")
	}

	return s.String()
}

func (m Model) renderProcesses() string {
	info := m.sysInfo
	var s strings.Builder

	// Top CPU
	s.WriteString(m.renderBox("⚡ TOP CPU CONSUMERS", currentTheme.CPU, func() string {
		var content strings.Builder
		for i, p := range info.TopCPU {
			bar := makeProgressBar(p.CPU, 15, "fancy")
			name := p.Name
			if len(name) > 20 {
				name = name[:17] + "..."
			}
			content.WriteString(fmt.Sprintf("  %d. %-20s %s %.1f%%\n", i+1, name, bar, p.CPU))
		}
		return content.String()
	}))

	s.WriteString("\n")

	// Top Memory
	s.WriteString(m.renderBox("🧠 TOP MEMORY CONSUMERS", currentTheme.RAM, func() string {
		var content strings.Builder
		for i, p := range info.TopMem {
			bar := makeProgressBar(p.Memory, 15, "fancy")
			name := p.Name
			if len(name) > 20 {
				name = name[:17] + "..."
			}
			content.WriteString(fmt.Sprintf("  %d. %-20s %s %.1f MB\n", i+1, name, bar, p.MemMB))
		}
		return content.String()
	}))

	return s.String()
}

func (m Model) renderBox(title string, color string, contentFn func() string) string {
	width := m.width - 8
	if width < 40 {
		width = 40
	}

	titleStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(color)).
		Bold(true)

	borderStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(currentTheme.Border))

	// Header
	titleLen := len(title) + 4
	leftPad := (width - titleLen) / 2
	rightPad := width - titleLen - leftPad

	var box strings.Builder
	box.WriteString(borderStyle.Render("  ╭"+strings.Repeat("─", leftPad)) +
		titleStyle.Render(" "+title+" ") +
		borderStyle.Render(strings.Repeat("─", rightPad)+"╮") + "\n")

	// Content
	content := contentFn()
	lines := strings.Split(content, "\n")
	for _, line := range lines {
		if line == "" {
			box.WriteString(borderStyle.Render("  │") +
				strings.Repeat(" ", width-2) +
				borderStyle.Render("│") + "\n")
		} else {
			lineLen := lipgloss.Width(line)
			padding := width - 2 - lineLen
			if padding < 0 {
				padding = 0
			}
			box.WriteString(borderStyle.Render("  │") +
				line + strings.Repeat(" ", padding) +
				borderStyle.Render("│") + "\n")
		}
	}

	// Footer
	box.WriteString(borderStyle.Render("  ╰"+strings.Repeat("─", width-2)+"╯") + "\n")

	return box.String()
}

func (m Model) renderUltraBox(title string, color string, contentFn func() string) string {
	width := m.width - 6
	if width < 30 { width = 30 }

	border, ok := borderStyles[m.borderStyle]
	if !ok { border = borderStyles["rounded"] }

	// Advanced Styles
	titleStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#000000")).
		Background(lipgloss.Color(color)).
		Bold(true).
		Padding(0, 1)

	borderColor := currentTheme.Border
	if (m.frame/5)%2 == 0 { borderColor = currentTheme.BorderGlow }
	borderStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(borderColor))

	// Content processing
	content := contentFn()
	lines := strings.Split(content, "\n")
	
	var box strings.Builder
	
	// Header with dynamic spacing
	titleWidth := lipgloss.Width(title) + 2
	leftPad := 2
	rightPad := width - titleWidth - leftPad - 2
	if rightPad < 0 { rightPad = 0 }

	header := borderStyle.Render(border.TopLeft + strings.Repeat(border.Horizontal, leftPad)) +
		titleStyle.Render(title) +
		borderStyle.Render(strings.Repeat(border.Horizontal, rightPad) + border.TopRight)
	
	box.WriteString("  " + header + "\n")

	// Content body with overflow control
	for _, line := range lines {
		if strings.TrimSpace(line) == "" && len(lines) > 1 { continue }
		
		lineWidth := lipgloss.Width(line)
		
		// Fill or Trim
		var displayLine string
		if lineWidth > width-4 {
			displayLine = line[:max(0, width-7)] + "..."
		} else {
			displayLine = line + strings.Repeat(" ", max(0, width-lineWidth-4))
		}

		box.WriteString("  " + borderStyle.Render(border.Vertical) + " " + displayLine + " " + borderStyle.Render(border.Vertical) + "\n")
	}

	// Footer
	box.WriteString("  " + borderStyle.Render(border.BottomLeft+strings.Repeat(border.Horizontal, width-2)+border.BottomRight) + "\n")

	return box.String()
}

func (m Model) renderInfoLine(label, value, valueColor string) string {
	labelStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.TextMuted))
	valueStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(valueColor))

	return fmt.Sprintf("  %s: %s\n",
		labelStyle.Render(fmt.Sprintf("%-12s", label)),
		valueStyle.Render(value))
}

func (m Model) renderGauge(label string, percent float64, color string) string {
	barWidth := 30
	if m.isCompact {
		barWidth = 20
	}

	bar := makeProgressBar(percent, barWidth, "gradient")
	percentColor := getPercentColor(percent, false)
	percentStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(percentColor)).Bold(true)

	return fmt.Sprintf("  %-10s [%s] %s\n",
		label, bar, percentStyle.Render(fmt.Sprintf("%.1f%%", percent)))
}

func (m Model) renderMiniGauge(label string, percent float64) string {
	bar := makeProgressBar(percent, 15, "fancy")
	color := getPercentColor(percent, false)
	percentStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(color))

	return fmt.Sprintf("  %-8s %s %s\n", label, bar, percentStyle.Render(fmt.Sprintf("%5.1f%%", percent)))
}

func (m *Model) renderFooter() string {
	bgStyle := lipgloss.NewStyle().
		Background(lipgloss.Color(currentTheme.Background)).
		Width(m.width)

	// Decorative line
	lineStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Border))
	decorLine := strings.Repeat("─", m.width-4)

	var footer strings.Builder
	footer.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		lineStyle.Render(decorLine)) + "\n")

	// Accurate Button Y placement (absolute bottom)
	buttonY := m.height - 1

	var btnStr strings.Builder
	posX := 4
	
	// Buttons definition
	buttons := []struct {
		key    string
		icon   string
		label  string
		action string
		color  string
	}{
		{"R", "🔄", "Refresh", "refresh", currentTheme.Success},
		{"T", "🎨", "Theme", "theme", currentTheme.Secondary},
		{"E", "📄", "Export", "export", currentTheme.Info},
		{"B", "🔲", "Border", "border", currentTheme.Warning},
		{"Q", "🚪", "Quit", "quit", currentTheme.Error},
	}

	for _, btn := range buttons {
		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: posX, Y: buttonY, W: len(btn.label) + 6, H: 1,
			Type: "button", Action: btn.action,
		})

		isHovered := m.hoverBtn == btn.action

		var style lipgloss.Style
		if isHovered {
			style = lipgloss.NewStyle().
				Background(lipgloss.Color(btn.color)).
				Foreground(lipgloss.Color("#000000")).
				Bold(true).
				Padding(0, 1)
		} else {
			style = lipgloss.NewStyle().
				Foreground(lipgloss.Color(btn.color)).
				Padding(0, 1)
		}

		keyStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color(currentTheme.Accent)).
			Bold(true)

		btnStr.WriteString(fmt.Sprintf("%s%s%s ",
			keyStyle.Render("["+btn.key+"]"),
			btn.icon,
			style.Render(btn.label)))

		posX += lipgloss.Width(btn.key) + lipgloss.Width(btn.icon) + lipgloss.Width(btn.label) + 6
	}

	// Status area
	spinner := ultraSpinners["hologram"][m.frame%len(ultraSpinners["hologram"])]
	spinnerStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Primary))

	updateTime := m.sysInfo.LastUpdate.Format("15:04:05")
	status := fmt.Sprintf("%s Updated:%s", spinnerStyle.Render(spinner), updateTime)

	left := btnStr.String()
	right := status

	padding := m.width - lipgloss.Width(left) - lipgloss.Width(right) - 4
	if padding < 0 { padding = 0 }

	footer.WriteString(fmt.Sprintf("  %s%s%s  ", left, strings.Repeat(" ", padding), right))
	return bgStyle.Render(footer.String())
}

func (m *Model) renderDashboard(yOffset int) string {
	info := m.sysInfo
	var s strings.Builder

	// 1. Health Status (Auto-centered)
	healthColor := currentTheme.Success
	if info.HealthScore < 70 { healthColor = currentTheme.Warning }
	if info.HealthScore < 50 { healthColor = currentTheme.Error }

	bannerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#000000")).
		Background(lipgloss.Color(healthColor)).
		Bold(true).
		Padding(0, 3).
		MarginBottom(1)

	s.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center, 
		bannerStyle.Render(fmt.Sprintf("SYSTEM HEALTH: %s (%d/100)", info.HealthStatus, info.HealthScore))) + "\n")

	// 2. Adaptive Stats Grid
	cards := []struct {
		icon, label, value string
		percent            float64
		color              string
		spark              []float64
		tabIdx             int
	}{
		{"⚡", "CPU", fmt.Sprintf("%.1f%%", info.CPUUsage), info.CPUUsage, currentTheme.CPU, m.cpuHistory, 1},
		{"🧠", "RAM", fmt.Sprintf("%.1f%%", info.MemPercent), info.MemPercent, currentTheme.RAM, m.memHistory, 2},
		{"💾", "DISK", func() string {
			if len(info.Disks) > 0 { return fmt.Sprintf("%.0f%%", info.Disks[0].Percent) }
			return "N/A"
		}(), func() float64 {
			if len(info.Disks) > 0 { return info.Disks[0].Percent }
			return 0
		}(), currentTheme.Disk, nil, 4},
		{"🌡️", "TEMP", fmt.Sprintf("%.0f°C", info.Thermal.CPUTemp), (info.Thermal.CPUTemp / 100) * 100, currentTheme.Temperature, nil, 0},
	}

	// Grid calculation
	cols := 1
	if m.width > 80 { cols = 2 }
	if m.width > 140 { cols = 4 }
	
	cardWidth := (m.width - (cols+1)*2) / cols
	var gridRows [][]string
	currentRow := make([]string, 0)

	for i, card := range cards {
		// Calculate precise hitbox
		rowIdx := i / cols
		colIdx := i % cols
		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: 2 + colIdx*(cardWidth+2), Y: yOffset + 3 + rowIdx*6, W: cardWidth, H: 5,
			Type: "tab", Index: card.tabIdx,
		})

		cardView := m.renderStatCard(card.icon, card.label, card.value, card.percent, card.color, card.spark, cardWidth)
		currentRow = append(currentRow, cardView)
		
		if len(currentRow) == cols || i == len(cards)-1 {
			gridRows = append(gridRows, currentRow)
			currentRow = make([]string, 0)
		}
	}

	for _, row := range gridRows {
		s.WriteString(lipgloss.JoinHorizontal(lipgloss.Top, row...) + "\n")
	}

	// 3. Information Panels (Adaptive Width)
	s.WriteString("\n")
	sysInfoContent := func() string {
		var content strings.Builder
		rows := []struct{ l, v, c string }{
			{"Hostname", info.Hostname, currentTheme.Accent},
			{"Platform", info.Platform, currentTheme.Text},
			{"Uptime", formatDuration(info.Uptime), currentTheme.Warning},
			{"Processes", fmt.Sprintf("%d total", info.Procs), currentTheme.Primary},
		}
		for _, r := range rows {
			content.WriteString(m.renderInfoLine(r.l, r.v, r.c))
		}
		return content.String()
	}
	s.WriteString(m.renderUltraBox("🖥️ SYSTEM OVERVIEW", currentTheme.Primary, sysInfoContent))

	// 4. History (Only if wide enough)
	if m.width > 60 && len(m.cpuHistory) > 2 {
		s.WriteString("\n")
		s.WriteString(m.renderUltraBox("📈 REAL-TIME PERFORMANCE", currentTheme.Accent, func() string {
			w := m.width - 15
			return fmt.Sprintf("  CPU %s\n  RAM %s", 
				makeColoredSparkline(m.cpuHistory, w, currentTheme.CPU),
				makeColoredSparkline(m.memHistory, w, currentTheme.RAM))
		}))
	}

	return s.String()
}

func (m Model) renderStatCard(icon, label, value string, percent float64, color string, history []float64, width int) string {
	if width < 15 { width = 15 }
	
	borderColor := currentTheme.Border
	if (m.frame/10)%2 == 0 { borderColor = currentTheme.BorderGlow }

	cardStyle := lipgloss.NewStyle().
		Border(lipgloss.ThickBorder()).
		BorderForeground(lipgloss.Color(borderColor)).
		Width(width).
		Padding(0, 1)

	var content strings.Builder

	// Header & Value
	header := lipgloss.NewStyle().Foreground(lipgloss.Color(color)).Bold(true).Render(icon + " " + label)
	valStr := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.TextBright)).Bold(true).Render(value)
	
	content.WriteString(header + "\n" + valStr + "\n")

	// Progress bar (Responsive width)
	barWidth := width - 4
	if barWidth < 5 { barWidth = 5 }
	
	filled := int(math.Round(percent * float64(barWidth) / 100))
	if filled > barWidth { filled = barWidth }
	
	bar := lipgloss.NewStyle().Foreground(lipgloss.Color(color)).Render(strings.Repeat("█", filled))
	bar += lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.SurfaceAlt)).Render(strings.Repeat("░", max(0, barWidth-filled)))
	content.WriteString(bar + "\n")

	// Sparkline (Only if enough history and space)
	if len(history) > 3 && width > 20 {
		content.WriteString(makeColoredSparkline(history, width-4, color))
	} else {
		content.WriteString(strings.Repeat("─", width-4))
	}

	return cardStyle.Render(content.String())
}

func (m Model) renderGPU() string {
	info := m.sysInfo
	var s strings.Builder

	if len(info.GPUs) == 0 {
		s.WriteString(m.renderUltraBox("🎮 GPU INFORMATION", currentTheme.GPU, func() string {
			return "  No GPU information available\n"
		}))
		return s.String()
	}

	for i, gpu := range info.GPUs {
		gpuIcon := "🎮"
		if strings.Contains(strings.ToLower(gpu.Name), "nvidia") {
			gpuIcon = "🟢"
		} else if strings.Contains(strings.ToLower(gpu.Name), "amd") {
			gpuIcon = "🔴"
		} else if strings.Contains(strings.ToLower(gpu.Name), "intel") {
			gpuIcon = "🔵"
		}

		s.WriteString(m.renderUltraBox(fmt.Sprintf("%s GPU %d: %s", gpuIcon, i, gpu.Name), currentTheme.GPU, func() string {
			var content strings.Builder

			// ASCII art for GPU
			art := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.GPU)).Render(asciiArt["gpu"])
			content.WriteString(art + "\n\n")

			content.WriteString(m.renderInfoLine("Vendor", gpu.Vendor, currentTheme.Text))
			content.WriteString(m.renderInfoLine("Driver", gpu.Driver, currentTheme.TextMuted))

			if gpu.VRAM > 0 {
				content.WriteString(m.renderInfoLine("VRAM Total", formatBytes(gpu.VRAM), currentTheme.Text))
				if gpu.VRAMUsed > 0 {
					vramPercent := float64(gpu.VRAMUsed) / float64(gpu.VRAM) * 100
					content.WriteString(m.renderInfoLine("VRAM Used", formatBytes(gpu.VRAMUsed), currentTheme.Warning))
					content.WriteString("\n")
					content.WriteString(m.renderGauge("VRAM", vramPercent, currentTheme.GPU))
				}
			}

			if gpu.Usage > 0 {
				content.WriteString("\n")
				content.WriteString(m.renderGauge("GPU Load", gpu.Usage, currentTheme.GPU))
			}

			if gpu.Temperature > 0 {
				tempColor := currentTheme.Success
				if gpu.Temperature > 80 {
					tempColor = currentTheme.Error
				} else if gpu.Temperature > 60 {
					tempColor = currentTheme.Warning
				}
				content.WriteString(m.renderInfoLine("Temperature",
					fmt.Sprintf("%.0f°C", gpu.Temperature), tempColor))
			}

			if gpu.FanSpeed > 0 {
				content.WriteString(m.renderInfoLine("Fan Speed",
					fmt.Sprintf("%.0f%%", gpu.FanSpeed), currentTheme.Info))
			}

			if gpu.PowerDraw > 0 {
				content.WriteString(m.renderInfoLine("Power Draw",
					fmt.Sprintf("%.1fW", gpu.PowerDraw), currentTheme.Warning))
			}

			if gpu.ClockCore > 0 {
				content.WriteString(m.renderInfoLine("Core Clock",
					fmt.Sprintf("%d MHz", gpu.ClockCore), currentTheme.TextMuted))
			}

			if gpu.ClockMem > 0 {
				content.WriteString(m.renderInfoLine("Memory Clock",
					fmt.Sprintf("%d MHz", gpu.ClockMem), currentTheme.TextMuted))
			}

			return content.String()
		}))

		s.WriteString("\n")
	}

	return s.String()
}

func (m Model) renderSecurity() string {
	info := m.sysInfo
	var s strings.Builder

	s.WriteString(m.renderUltraBox("🛡️ SECURITY STATUS", currentTheme.Success, func() string {
		var content strings.Builder

		// Firewall status
		firewallIcon := statusIcons["lock"]
		firewallColor := currentTheme.Success
		if info.Security.Firewall != "Enabled" {
			firewallIcon = statusIcons["unlock"]
			firewallColor = currentTheme.Error
		}
		content.WriteString(fmt.Sprintf("  %s Firewall: %s\n",
			lipgloss.NewStyle().Foreground(lipgloss.Color(firewallColor)).Render(firewallIcon),
			lipgloss.NewStyle().Foreground(lipgloss.Color(firewallColor)).Bold(true).Render(info.Security.Firewall)))

		// Antivirus status
		avIcon := statusIcons["shield"]
		avColor := currentTheme.Success
		if info.Security.Antivirus == "Unknown" || info.Security.Antivirus == "" {
			avIcon = statusIcons["warn"]
			avColor = currentTheme.Warning
		}
		content.WriteString(fmt.Sprintf("  %s Antivirus: %s\n",
			lipgloss.NewStyle().Foreground(lipgloss.Color(avColor)).Render(avIcon),
			lipgloss.NewStyle().Foreground(lipgloss.Color(avColor)).Bold(true).Render(info.Security.Antivirus)))

		return content.String()
	}))

	// Running Services
	if len(info.Services) > 0 {
		s.WriteString("\n")
		s.WriteString(m.renderUltraBox("⚙️ RUNNING SERVICES", currentTheme.Info, func() string {
			var content strings.Builder

			for _, svc := range info.Services {
				statusIcon := makeStatusIndicator(strings.ToLower(svc.Status), true, m.frame)
				name := svc.DisplayName
				if len(name) > 45 {
					name = name[:42] + "..."
				}
				content.WriteString(fmt.Sprintf("  %s %-45s\n", statusIcon, name))
			}

			return content.String()
		}))
	}

	return s.String()
}

func (m Model) renderSystemDetails() string {
	info := m.sysInfo
	var s strings.Builder

	// Mainboard & BIOS
	s.WriteString(m.renderUltraBox("🔧 MAINBOARD & BIOS", currentTheme.Info, func() string {
		var content strings.Builder

		if info.BoardVendor != "" {
			content.WriteString(m.renderInfoLine("Manufacturer", info.BoardVendor, currentTheme.Text))
		}
		if info.BoardName != "" {
			content.WriteString(m.renderInfoLine("Model", info.BoardName, currentTheme.Primary))
		}
		if info.BiosVersion != "" {
			content.WriteString(m.renderInfoLine("BIOS Version", info.BiosVersion, currentTheme.TextMuted))
		}
		if info.BiosDate != "" {
			content.WriteString(m.renderInfoLine("BIOS Date", info.BiosDate, currentTheme.TextMuted))
		}
		if info.ProductSerial != "" {
			content.WriteString(m.renderInfoLine("Serial Number", info.ProductSerial, currentTheme.TextMuted))
		}
		if info.SystemUUID != "" {
			content.WriteString(m.renderInfoLine("System UUID", info.SystemUUID, currentTheme.TextMuted))
		}

		return content.String()
	}))

	// Boot Information
	s.WriteString("\n")
	s.WriteString(m.renderUltraBox("🚀 BOOT INFORMATION", currentTheme.Warning, func() string {
		var content strings.Builder

		content.WriteString(m.renderInfoLine("Boot Time", info.BootTime.Format("2006-01-02 15:04:05"), currentTheme.Text))
		content.WriteString(m.renderInfoLine("Uptime", formatDuration(info.Uptime), currentTheme.Success))

		// Calculate days since last reboot
		days := int(info.Uptime.Hours() / 24)
		if days > 7 {
			content.WriteString(m.renderInfoLine("Note",
				fmt.Sprintf("System running for %d days - consider rebooting", days),
				currentTheme.Warning))
		}

		return content.String()
	}))

	// Environment
	s.WriteString("\n")
	s.WriteString(m.renderUltraBox("🌍 ENVIRONMENT", currentTheme.Secondary, func() string {
		var content strings.Builder

		content.WriteString(m.renderInfoLine("OS", info.OS, currentTheme.Text))
		content.WriteString(m.renderInfoLine("Platform", info.Platform, currentTheme.TextMuted))
		content.WriteString(m.renderInfoLine("Kernel", info.Kernel, currentTheme.Secondary))
		content.WriteString(m.renderInfoLine("Architecture", info.Arch, currentTheme.Info))

		// Go runtime info
		content.WriteString("\n")
		content.WriteString(m.renderInfoLine("Go Version", runtime.Version(), currentTheme.TextMuted))
		content.WriteString(m.renderInfoLine("Go Arch", runtime.GOARCH, currentTheme.TextMuted))
		content.WriteString(m.renderInfoLine("NumCPU", fmt.Sprintf("%d", runtime.NumCPU()), currentTheme.TextMuted))
		content.WriteString(m.renderInfoLine("NumGoroutine", fmt.Sprintf("%d", runtime.NumGoroutine()), currentTheme.TextMuted))

		return content.String()
	}))

	// Data Collection Stats
	s.WriteString("\n")
	s.WriteString(m.renderUltraBox("📊 MONITORING STATS", currentTheme.Accent, func() string {
		var content strings.Builder

		content.WriteString(m.renderInfoLine("Last Update", info.LastUpdate.Format("15:04:05"), currentTheme.Success))
		content.WriteString(m.renderInfoLine("Collect Time", info.CollectTime.String(), currentTheme.TextMuted))
		content.WriteString(m.renderInfoLine("History Points", fmt.Sprintf("%d", len(m.cpuHistory)), currentTheme.Info))

		return content.String()
	}))

	return s.String()
}

// ══════════════════════════════════════════════════════════════════
//                         MAIN
// ══════════════════════════════════════════════════════════════════

func main() {
	p := tea.NewProgram(
		initialModel(),
		tea.WithAltScreen(),
		tea.WithMouseAllMotion(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
