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
//                         THEME SYSTEM
// ══════════════════════════════════════════════════════════════════

type Theme struct {
	Name       string
	Primary    string
	Secondary  string
	Accent     string
	Success    string
	Warning    string
	Error      string
	Info       string
	Background string
	Surface    string
	Text       string
	TextMuted  string
	Border     string
	CPU        string
	RAM        string
	Disk       string
	Network    string
	GPU        string
}

var themes = map[string]Theme{
	"Neon": {
		Name: "Neon", Primary: "#00FFFF", Secondary: "#FF00FF",
		Accent: "#FFD700", Success: "#00FF88", Warning: "#FFB800",
		Error: "#FF4444", Info: "#3B82F6", Background: "#0A0E14",
		Surface: "#1A1E2E", Text: "#E2E8F0", TextMuted: "#64748B",
		Border: "#2D3748", CPU: "#FFFF00", RAM: "#FF00FF",
		Disk: "#00FF88", Network: "#00FFFF", GPU: "#FF6B6B",
	},
	"Matrix": {
		Name: "Matrix", Primary: "#00FF00", Secondary: "#008800",
		Accent: "#00FF00", Success: "#00FF00", Warning: "#FFFF00",
		Error: "#FF0000", Info: "#008800", Background: "#000000",
		Surface: "#0A1A0A", Text: "#00FF00", TextMuted: "#006600",
		Border: "#004400", CPU: "#00FF00", RAM: "#00FF00",
		Disk: "#00FF00", Network: "#00FF00", GPU: "#00FF00",
	},
	"Cyberpunk": {
		Name: "Cyberpunk", Primary: "#FF00FF", Secondary: "#00FFFF",
		Accent: "#FFD700", Success: "#00FFFF", Warning: "#FFD700",
		Error: "#FF0040", Info: "#FF00FF", Background: "#0D0221",
		Surface: "#1A0A2E", Text: "#FFFFFF", TextMuted: "#8866AA",
		Border: "#6B21A8", CPU: "#00FFFF", RAM: "#FF00FF",
		Disk: "#FFD700", Network: "#00FFFF", GPU: "#FF0040",
	},
	"Ocean": {
		Name: "Ocean", Primary: "#06B6D4", Secondary: "#0EA5E9",
		Accent: "#38BDF8", Success: "#10B981", Warning: "#F59E0B",
		Error: "#EF4444", Info: "#3B82F6", Background: "#0C1222",
		Surface: "#1E293B", Text: "#F1F5F9", TextMuted: "#64748B",
		Border: "#334155", CPU: "#38BDF8", RAM: "#A78BFA",
		Disk: "#10B981", Network: "#06B6D4", GPU: "#F472B6",
	},
}

var currentTheme = themes["Neon"]

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
//                         DATA STRUCTURES
// ══════════════════════════════════════════════════════════════════

type SystemInfo struct {
	// Host
	Hostname    string
	Username    string
	OS          string
	Platform    string
	Kernel      string
	Arch        string
	Uptime      time.Duration
	BootTime    time.Time
	Procs       uint64

	// Mainboard & BIOS (New)
	BoardName     string
	BoardVendor   string
	BiosVersion   string
	ProductSerial string

	// CPU
	CPUModel    string
	CPUCores    int
	CPUThreads  int
	CPUFreq     float64
	CPUUsage    float64
	CPUPerCore  []float64

	// Memory
	MemTotal    uint64
	MemUsed     uint64
	MemFree     uint64
	MemPercent  float64
	SwapTotal   uint64
	SwapUsed    uint64
	SwapPercent float64

	// Disks
	Disks       []DiskInfo

	// Network
	Networks    []NetworkInfo

	// GPU (Windows)
	GPUName     string
	GPUDriver   string
	GPUVRAM     uint64

	// Top Processes
	TopCPU      []ProcessInfo
	TopMem      []ProcessInfo

	// Timestamps
	LastUpdate  time.Time
}

type DiskInfo struct {
	Path        string
	Device      string
	Fstype      string
	Total       uint64
	Used        uint64
	Free        uint64
	Percent     float64
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
//                         MODEL
// ══════════════════════════════════════════════════════════════════

type Model struct {
	// System data
	sysInfo     SystemInfo
	loading     bool
	loadingStep int
	loadingMsg  string

	// UI State
	activeTab   int
	tabs        []Tab
	scrollY     int
	maxScroll   int

	// Dimensions
	width       int
	height      int
	isCompact   bool
	isMobile    bool

	// Mouse
	mouseX      int
	mouseY      int
	hoverTab    int
	hoverBtn    string
	hitBoxes    []HitBox

	// Animation
	frame       int
	startTime   time.Time

	// Theme
	themeIndex  int
	themeNames  []string

	// Export
	exported    bool
	exportFade  int
}

type tickMsg time.Time
type sysInfoMsg SystemInfo

// ══════════════════════════════════════════════════════════════════
//                         SYSTEM INFO COLLECTION
// ══════════════════════════════════════════════════════════════════

func collectSystemInfo() SystemInfo {
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

	// CPU info
	if cpuInfo, err := cpu.Info(); err == nil && len(cpuInfo) > 0 {
		info.CPUModel = cpuInfo[0].ModelName
		info.CPUCores = int(cpuInfo[0].Cores)
		info.CPUFreq = cpuInfo[0].Mhz
	}
	info.CPUThreads = runtime.NumCPU()

	// CPU usage
	if usage, err := cpu.Percent(0, false); err == nil && len(usage) > 0 {
		info.CPUUsage = usage[0]
	}
	if perCore, err := cpu.Percent(0, true); err == nil {
		info.CPUPerCore = perCore
	}

	// Memory
	if m, err := mem.VirtualMemory(); err == nil {
		info.MemTotal = m.Total
		info.MemUsed = m.Used
		info.MemFree = m.Free
		info.MemPercent = m.UsedPercent
	}
	if s, err := mem.SwapMemory(); err == nil {
		info.SwapTotal = s.Total
		info.SwapUsed = s.Used
		info.SwapPercent = s.UsedPercent
	}

	// Disks
	if partitions, err := disk.Partitions(false); err == nil {
		for _, p := range partitions {
			if usage, err := disk.Usage(p.Mountpoint); err == nil {
				info.Disks = append(info.Disks, DiskInfo{
					Path:    p.Mountpoint,
					Device:  p.Device,
					Fstype:  p.Fstype,
					Total:   usage.Total,
					Used:    usage.Used,
					Free:    usage.Free,
					Percent: usage.UsedPercent,
				})
			}
		}
	}

	// Network
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
			}

			if io, ok := ioMap[iface.Name]; ok {
				netInfo.BytesSent = io.BytesSent
				netInfo.BytesRecv = io.BytesRecv
				netInfo.PacketsSent = io.PacketsSent
				netInfo.PacketsRecv = io.PacketsRecv
			}

			info.Networks = append(info.Networks, netInfo)
		}
	}

	// GPU (Windows only)
	if runtime.GOOS == "windows" {
		info.GPUName, info.GPUDriver, info.GPUVRAM = getWindowsGPU()
	}

	// Top processes
	info.TopCPU = getTopProcesses("cpu", 5)
	info.TopMem = getTopProcesses("mem", 5)

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
	themeNames := []string{"Neon", "Matrix", "Cyberpunk", "Ocean"}

	return &Model{
		loading:    true,
		loadingMsg: "Initializing...",
		tabs: []Tab{
			{ID: "overview", Name: "Overview", Icon: "🖥️", Color: "#00FFFF"},
			{ID: "cpu", Name: "CPU", Icon: "⚙️", Color: "#FFFF00"},
			{ID: "memory", Name: "Memory", Icon: "🧠", Color: "#FF00FF"},
			{ID: "disk", Name: "Disks", Icon: "💾", Color: "#00FF88"},
			{ID: "network", Name: "Network", Icon: "📡", Color: "#00BFFF"},
			{ID: "process", Name: "Processes", Icon: "🔥", Color: "#FF6B6B"},
		},
		hoverTab:   -1,
		startTime:  time.Now(),
		themeNames: themeNames,
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
		if m.loading {
			m.loadingStep++
			steps := []string{
				"Scanning CPU...",
				"Analyzing Memory...",
				"Checking Disks...",
				"Probing Network...",
				"Detecting GPU...",
				"Loading Processes...",
				"Finalizing...",
			}
			m.loadingMsg = steps[m.loadingStep%len(steps)]
		}
		if m.exportFade > 0 {
			m.exportFade--
			if m.exportFade == 0 {
				m.exported = false
			}
		}
		return m, tickCmd()

	case sysInfoMsg:
		m.sysInfo = SystemInfo(msg)
		m.loading = false
		return m, nil

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.isMobile = m.width < 80
		m.isCompact = m.width < 100
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
			m.scrollY--
		}

	case "down", "j":
		m.scrollY++

	case "r":
		m.loading = true
		m.loadingStep = 0
		return m, fetchSysInfo

	case "t":
		m.themeIndex = (m.themeIndex + 1) % len(m.themeNames)
		currentTheme = themes[m.themeNames[m.themeIndex]]

	case "e":
		m.exported = true
		m.exportFade = 30
		exportReport(m.sysInfo)

	case "1", "2", "3", "4", "5", "6":
		idx, _ := strconv.Atoi(msg.String())
		if idx-1 < len(m.tabs) {
			m.activeTab = idx - 1
			m.scrollY = 0
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

	m.hitBoxes = make([]HitBox, 0)

	var sections []string
	sections = append(sections, m.renderHeader())
	sections = append(sections, m.renderTabs())
	sections = append(sections, m.renderContent())
	sections = append(sections, m.renderFooter())

	return lipgloss.JoinVertical(lipgloss.Left, sections...)
}

func (m *Model) renderLoading() string {
	logo := `
  ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
  ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
  ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
  ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
  ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
  ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝

  ██╗███╗   ██╗███████╗ ██████╗ 
  ██║████╗  ██║██╔════╝██╔═══██╗
  ██║██╔██╗ ██║█████╗  ██║   ██║
  ██║██║╚██╗██║██╔══╝  ██║   ██║
  ██║██║ ╚████║██║     ╚██████╔╝
  ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝ 
`

	var view strings.Builder

	// Logo with gradient
	colors := gradients["cyber"]
	lines := strings.Split(logo, "\n")
	for _, line := range lines {
		view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
			gradientText(line, colors)) + "\n")
	}

	// Spinner
	spinner := spinners["braille"][m.frame%len(spinners["braille"])]
	spinnerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(currentTheme.Primary)).
		Bold(true)

	loadingLine := fmt.Sprintf("%s %s", spinner, m.loadingMsg)
	view.WriteString("\n")
	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		spinnerStyle.Render(loadingLine)) + "\n")

	// Progress simulation
	progress := (m.loadingStep * 15) % 100
	bar := makeProgressBar(float64(progress), 40, "gradient")
	view.WriteString("\n")
	view.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		fmt.Sprintf("[%s] %d%%", bar, progress)) + "\n")

	return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, view.String())
}

func (m Model) renderHeader() string {
	// Compact logo
	var logo string
	if m.isCompact {
		logo = "⚡ SYSTEM INFO ⚡"
	} else {
		logo = `╔═══════════════════════════════════════════════════════════╗
║  ███████╗██╗   ██╗███████╗  ██╗███╗   ██╗███████╗ ██████╗  ║
║  ██╔════╝╚██╗ ██╔╝██╔════╝  ██║████╗  ██║██╔════╝██╔═══██╗ ║
║  ███████╗ ╚████╔╝ ███████╗  ██║██╔██╗ ██║█████╗  ██║   ██║ ║
║  ╚════██║  ╚██╔╝  ╚════██║  ██║██║╚██╗██║██╔══╝  ██║   ██║ ║
║  ███████║   ██║   ███████║  ██║██║ ╚████║██║     ╚██████╔╝ ║
║  ╚══════╝   ╚═╝   ╚══════╝  ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝  ║
╚═══════════════════════════════════════════════════════════╝`
	}

	// Animate gradient
	gradientNames := []string{"cyber", "fire", "ocean", "rainbow"}
	currentGrad := gradients[gradientNames[(m.frame/50)%len(gradientNames)]]

	var header strings.Builder
	lines := strings.Split(logo, "\n")
	for _, line := range lines {
		header.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
			gradientText(line, currentGrad)) + "\n")
	}

	// Subtitle
	pulse := spinners["pulse"][m.frame%len(spinners["pulse"])]
	subtitle := fmt.Sprintf("%s NEON DASHBOARD v3.1 %s", pulse, pulse)
	subtitleStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(currentTheme.Accent)).
		Bold(true)

	header.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center,
		subtitleStyle.Render(subtitle)) + "\n")

	return header.String()
}

func (m *Model) renderTabs() string {
	var tabs []string
	tabY := 10
	if m.isCompact {
		tabY = 3
	}

	for i, tab := range m.tabs {
		isActive := i == m.activeTab
		isHovered := i == m.hoverTab

		tabWidth := (m.width - 8) / len(m.tabs)
		posX := 4 + (i * tabWidth)

		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: posX, Y: tabY, W: tabWidth - 2, H: 1,
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

func (m *Model) renderContent() string {
	contentHeight := m.height - 18
	if m.isCompact {
		contentHeight = m.height - 10
	}

	var content string
	switch m.tabs[m.activeTab].ID {
	case "overview":
		content = m.renderOverview()
	case "cpu":
		content = m.renderCPU()
	case "memory":
		content = m.renderMemory()
	case "disk":
		content = m.renderDisks()
	case "network":
		content = m.renderNetwork()
	case "process":
		content = m.renderProcesses()
	}

	// Apply scroll
	lines := strings.Split(content, "\n")
	if m.scrollY >= len(lines) {
		m.scrollY = max(0, len(lines)-1)
	}
	end := min(m.scrollY+contentHeight, len(lines))
	visibleLines := lines[m.scrollY:end]

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
		if info.GPUName != "" {
			content.WriteString(m.renderInfoLine("GPU", info.GPUName, currentTheme.GPU))
			content.WriteString(m.renderInfoLine("VRAM", formatBytes(info.GPUVRAM), currentTheme.Text))
			content.WriteString(m.renderInfoLine("Driver", info.GPUDriver, currentTheme.TextMuted))
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

	// Buttons
	buttonY := m.height - 2
	buttons := []struct {
		key    string
		label  string
		action string
		color  string
	}{
		{"R", "Refresh", "refresh", currentTheme.Success},
		{"T", "Theme", "theme", currentTheme.Secondary},
		{"E", "Export", "export", currentTheme.Info},
		{"Q", "Quit", "quit", currentTheme.Error},
	}

	var btnStr strings.Builder
	posX := 4
	for _, btn := range buttons {
		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: posX, Y: buttonY, W: len(btn.label) + 4, H: 1,
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

		btnStr.WriteString(fmt.Sprintf("%s%s ",
			keyStyle.Render("["+btn.key+"]"),
			style.Render(btn.label)))

		posX += len(btn.label) + 6
	}

	// Status
	spinner := spinners["dots"][m.frame%len(spinners["dots"])]
	spinnerStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(currentTheme.Primary))

	updateTime := m.sysInfo.LastUpdate.Format("15:04:05")
	status := fmt.Sprintf("%s Theme: %s | Updated: %s",
		spinnerStyle.Render(spinner),
		currentTheme.Name,
		updateTime)

	if m.exported {
		status = lipgloss.NewStyle().
			Foreground(lipgloss.Color(currentTheme.Success)).
			Bold(true).
			Render("✓ Report exported!")
	}

	left := btnStr.String()
	right := status

	padding := m.width - lipgloss.Width(left) - lipgloss.Width(right) - 4
	if padding < 0 {
		padding = 0
	}

	footer := fmt.Sprintf("\n  %s%s%s  ", left, strings.Repeat(" ", padding), right)
	return bgStyle.Render(footer)
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