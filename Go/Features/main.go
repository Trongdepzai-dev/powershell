// main.go
package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/atotto/clipboard"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ══════════════════════════════════════════════════════════════════
//                         THEME SYSTEM
// ══════════════════════════════════════════════════════════════════

var (
	// Color palette
	colors = struct {
		bg        string
		bgDark    string
		bgLight   string
		surface   string
		surfaceHL string
		border    string
		borderHL  string
		text      string
		textDim   string
		textMuted string
		primary   string
		secondary string
		accent    string
		success   string
		warning   string
		error     string
	}{
		bg:        "#0C0C14",
		bgDark:    "#08080C",
		bgLight:   "#12121C",
		surface:   "#16161E",
		surfaceHL: "#1E1E2E",
		border:    "#2A2A3C",
		borderHL:  "#3A3A5C",
		text:      "#E4E4E7",
		textDim:   "#A1A1AA",
		textMuted: "#52525B",
		primary:   "#22D3EE",
		secondary: "#A855F7",
		accent:    "#F472B6",
		success:   "#34D399",
		warning:   "#FBBF24",
		error:     "#F87171",
	}

	// Gradients
	gradients = map[string][]string{
		"cyber":   {"#06B6D4", "#8B5CF6", "#EC4899"},
		"fire":    {"#F97316", "#EF4444", "#DC2626"},
		"matrix":  {"#10B981", "#059669", "#047857"},
		"sunset":  {"#F472B6", "#FB923C", "#FACC15"},
		"ocean":   {"#0EA5E9", "#3B82F6", "#6366F1"},
		"neon":    {"#22D3EE", "#A855F7", "#EC4899"},
		"emerald": {"#34D399", "#10B981", "#059669"},
		"royal":   {"#8B5CF6", "#7C3AED", "#6D28D9"},
	}

	// Animations
	spinners    = []string{"⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷"}
	dots        = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
	pulse       = []string{"○", "◔", "◑", "◕", "●", "◕", "◑", "◔"}
	progressBar = []string{"▱", "▰"}

	// ══════════════════════════════════════════════════════════════════
	//                    ENHANCED ANIMATION PATTERNS
	// ══════════════════════════════════════════════════════════════════

	// Wave animations
	waveChars = []string{"▁", "▂", "▃", "▄", "▅", "▆", "▇", "█", "▇", "▆", "▅", "▄", "▃", "▂"}

	// Sparkle effects
	sparkles = []string{"✦", "✧", "⋆", "✧", "✦", "★", "✦", "✧"}

	// Border glow
	glowFrames = []string{"░", "▒", "▓", "█", "▓", "▒", "░"}

	// Loading bars
	loadBars = []string{"▰▱▱▱▱", "▰▰▱▱▱", "▰▰▰▱▱", "▰▰▰▰▱", "▰▰▰▰▰", "▰▰▰▰▱", "▰▰▰▱▱", "▰▰▱▱▱"}

	// Radar sweep
	radar = []string{"◜", "◝", "◞", "◟"}

	// DNA helix
	dna = []string{"⠋⠙", "⠹⠸", "⠼⠴", "⠦⠧", "⠇⠏"}

	// Command icons mapping
	cmdIcons = map[string]string{
		// Navigation
		"des": "🖥️", "dl": "📥", "docs": "📄", "cdd": "📂", "bm": "🔖",
		"j": "⚡", "..": "⬆️", "...": "⏫", "-": "↩️", "home": "🏠", "root": "💾",
		// Files
		"mkfile": "📝", "touch": "👆", "nano": "✏️", "fastcopy": "⚡",
		"extract": "📦", "compress": "🗜️", "trash": "🗑️", "open": "📂", "tree2": "🌳",
		// System
		"sysinfo": "💻", "top": "📊", "ports": "🔌", "killport": "💀",
		"myip": "🌐", "speedtest": "🚀", "battery": "🔋", "cleantemp": "🧹", "up": "📡",
		// Dev
		"install": "📦", "calc": "🔢", "json": "📋", "passgen": "🔐",
		"timer": "⏱️", "todo": "✅", "short": "🔗", "cheat": "📖", "web": "🔍",
		// Admin
		"sudo": "👑", "god": "⚡", "ti": "🛡️", "drop": "👤",
		"def": "🛡️", "avkill": "💀", "nuke": "☢️", "ghost": "👻", "powerup": "⚡",
		// Windows
		"star": "📌", "unstar": "📍", "wm": "🪟", "hyp": "💿",
		"uefi": "⚙️", "vmx": "🖥️", "cmd": "⌨️",
		// Search
		"ff": "🔎", "ftext": "📝", "dup": "👯", "recent": "🕐",
		"sizesort": "📏", "count": "🔢", "hh": "📜",
		// Git
		"gs": "📊", "ga": "➕", "gc": "💾", "gp": "⬆️", "gl": "⬇️",
		"glog": "📜", "gd": "📝", "gb": "🌿", "gco": "🔀", "gst": "📦",
	}

	// Decorative corners
	corners = struct {
		topLeft, topRight, bottomLeft, bottomRight string
		heavy, double, rounded                      [4]string
	}{
		topLeft: "╭", topRight: "╮", bottomLeft: "╰", bottomRight: "╯",
		heavy:   [4]string{"┏", "┓", "┗", "┛"},
		double:  [4]string{"╔", "╗", "╚", "╝"},
		rounded: [4]string{"╭", "╮", "╰", "╯"},
	}
)

// Enhanced gradient collection
var enhancedGradients = map[string][]string{
	"aurora":    {"#00D4FF", "#7B2FFF", "#FF2E63", "#FFE600"},
	"plasma":    {"#FF6B6B", "#4ECDC4", "#45B7D1", "#96E6A1"},
	"synthwave": {"#FF00FF", "#00FFFF", "#FF6EC7", "#00FF87"},
	"volcano":   {"#FF4500", "#FF6347", "#DC143C", "#8B0000"},
	"rainbow":   {"#FF0000", "#FF7F00", "#FFFF00", "#00FF00", "#0000FF", "#8B00FF"},
	"gold":      {"#FFD700", "#FFA500", "#FF8C00", "#DAA520"},
	"cosmic":    {"#9B59B6", "#3498DB", "#1ABC9C", "#F39C12", "#E74C3C"},
	"ice":       {"#E0FFFF", "#87CEEB", "#00CED1", "#4169E1"},
	"blood":     {"#8B0000", "#DC143C", "#FF0000", "#FF4500"},
	"toxic":     {"#00FF00", "#32CD32", "#7FFF00", "#ADFF2F"},
}

// ══════════════════════════════════════════════════════════════════
//                         DATA MODELS
// ══════════════════════════════════════════════════════════════════

type Command struct {
	Cmd     string
	Desc    string
	Hot     string
	Tags    []string
	Example string
	Usage   string
	Since   string
	Danger  bool
}

type Category struct {
	ID       string
	Name     string
	Icon     string
	Gradient string
	Commands []Command
}

type HitBox struct {
	X, Y, W, H int
	ID         string
	Type       string
	Index      int
	Data       interface{}
}

type Layout struct {
	HeaderH    int
	TabsH      int
	SearchH    int
	ContentH   int
	StatusH    int
	ListW      int
	DetailW    int
	Padding    int
	TabW       int
	TabsPerRow int
}

type Model struct {
	// Data
	categories []Category
	filtered   []Command

	// State
	catIndex    int
	itemIndex   int
	scrollY     int
	searchMode  bool
	searchInput textinput.Model
	showHelp    bool
	copied      bool
	copyTimer   int

	// Toast notification
	toast      string
	toastType  string // "success", "error", "info", "warning"
	toastTimer int

	// Statistics
	totalCmds  int
	usageStats map[string]int

	// Dimensions
	width  int
	height int
	layout Layout

	// Mouse
	mouseX      int
	mouseY      int
	hoverCat    int
	hoverItem   int
	hoverBtn    string
	hitBoxes    []HitBox
	lastClick   time.Time
	doubleClick bool

	// Visual effects
	pulsePhase  float64
	glowIntense int
	particlePos []int

	// Detail view
	detailScroll int
	detailTab    int // 0: info, 1: examples, 2: related

	// Time
	startTime time.Time

	// Animation
	frame int
}

type TickMsg time.Time

// ══════════════════════════════════════════════════════════════════
//                         INIT DATA
// ══════════════════════════════════════════════════════════════════

func initData() []Category {
	return []Category{
		{
			ID: "nav", Name: "Navigation", Icon: "🚀", Gradient: "neon",
			Commands: []Command{
				{
					Cmd: "des", Desc: "Navigate to Desktop folder",
					Tags: []string{"desktop", "folder"},
					Example: "des",
					Usage: "Quickly jump to your Desktop directory",
					Since: "v1.0",
				},
				{
					Cmd: "dl", Desc: "Navigate to Downloads folder",
					Tags: []string{"download", "folder"},
					Example: "dl && ls",
					Usage: "Access Downloads and list contents",
					Since: "v1.0",
				},
				{
					Cmd: "docs", Desc: "Navigate to Documents folder",
					Tags: []string{"documents", "folder"},
					Example: "docs",
					Usage: "Jump to Documents directory",
					Since: "v1.0",
				},
				{
					Cmd: "cdd", Desc: "Smart CD with history & fuzzy matching",
					Tags: []string{"cd", "smart", "fuzzy"},
					Example: "cdd proj",
					Usage: "cdd <partial-name> - Uses fuzzy matching",
					Since: "v1.2",
				},
				{
					Cmd: "bm", Desc: "Interactive Bookmark Manager",
					Hot: "Ctrl+B", Tags: []string{"bookmark", "save"},
					Example: "bm add work ~/Projects",
					Usage: "bm [add|del|list] <name> [path]",
					Since: "v1.1",
				},
				{
					Cmd: "j", Desc: "Jump to saved bookmark",
					Tags: []string{"jump", "bookmark"},
					Example: "j work",
					Usage: "j <bookmark-name>",
					Since: "v1.1",
				},
				{
					Cmd: "..", Desc: "Go up one directory level",
					Tags: []string{"parent", "up"},
					Example: "..",
					Usage: "Navigate to parent directory",
					Since: "v1.0",
				},
				{
					Cmd: "...", Desc: "Go up two directory levels",
					Tags: []string{"parent", "up"},
					Example: "...",
					Usage: "Navigate up 2 levels",
					Since: "v1.0",
				},
				{
					Cmd: "-", Desc: "Return to previous directory",
					Tags: []string{"back", "previous", "history"},
					Example: "-",
					Usage: "Toggle between current and last dir",
					Since: "v1.0",
				},
				{
					Cmd: "home", Desc: "Navigate to home directory",
					Tags: []string{"home", "user"},
					Example: "home",
					Usage: "Go to $HOME (~)",
					Since: "v1.0",
				},
				{
					Cmd: "root", Desc: "Navigate to drive root",
					Tags: []string{"root", "drive"},
					Example: "root",
					Usage: "Go to C:\\ or /",
					Since: "v1.0",
				},
			},
		},
		{
			ID: "files", Name: "Files", Icon: "📁", Gradient: "matrix",
			Commands: []Command{
				{
					Cmd: "mkfile", Desc: "Create file with recursive directory creation",
					Tags: []string{"create", "file", "mkdir"},
					Example: "mkfile path/to/file.txt",
					Usage: "mkfile <path> - Creates parent dirs if needed",
					Since: "v1.0",
				},
				{
					Cmd: "touch", Desc: "Create empty file or update timestamp",
					Tags: []string{"create", "touch", "timestamp"},
					Example: "touch newfile.txt",
					Usage: "touch <filename>",
					Since: "v1.0",
				},
				{
					Cmd: "nano", Desc: "Open file in smart editor",
					Tags: []string{"edit", "editor", "vim"},
					Example: "nano config.json",
					Usage: "nano <file> - Auto-detects best editor",
					Since: "v1.0",
				},
				{
					Cmd: "fastcopy", Desc: "Multi-threaded file copy",
					Tags: []string{"copy", "fast", "parallel"},
					Example: "fastcopy src/ dest/",
					Usage: "fastcopy <source> <dest> [-t threads]",
					Since: "v1.3",
				},
				{
					Cmd: "extract", Desc: "Extract any archive format",
					Tags: []string{"unzip", "extract", "archive", "7z", "tar"},
					Example: "extract archive.zip",
					Usage: "extract <file> [dest] - Supports zip/7z/tar/gz",
					Since: "v1.0",
				},
				{
					Cmd: "compress", Desc: "Compress files to ZIP",
					Tags: []string{"zip", "compress", "archive"},
					Example: "compress folder/ output.zip",
					Usage: "compress <path> [output.zip]",
					Since: "v1.0",
				},
				{
					Cmd: "trash", Desc: "Move files to Recycle Bin",
					Tags: []string{"delete", "recycle", "safe"},
					Example: "trash oldfile.txt",
					Usage: "trash <files...> - Safe delete",
					Since: "v1.0",
				},
				{
					Cmd: "open", Desc: "Open file or folder in Explorer",
					Tags: []string{"explorer", "open", "gui"},
					Example: "open .",
					Usage: "open [path] - Opens in default app",
					Since: "v1.0",
				},
				{
					Cmd: "tree2", Desc: "Enhanced directory tree view",
					Tags: []string{"tree", "list", "visual"},
					Example: "tree2 -d 3",
					Usage: "tree2 [path] [-d depth] [-a all]",
					Since: "v1.1",
				},
			},
		},
		{
			ID: "system", Name: "System", Icon: "💻", Gradient: "ocean",
			Commands: []Command{
				{
					Cmd: "sysinfo", Desc: "Display complete system information",
					Tags: []string{"info", "system", "hardware"},
					Example: "sysinfo",
					Usage: "Shows CPU, RAM, Disk, OS details",
					Since: "v1.0",
				},
				{
					Cmd: "top", Desc: "Interactive process manager",
					Tags: []string{"process", "monitor", "htop"},
					Example: "top",
					Usage: "Real-time process monitoring",
					Since: "v1.0",
				},
				{
					Cmd: "ports", Desc: "List all listening network ports",
					Tags: []string{"network", "ports", "netstat"},
					Example: "ports",
					Usage: "Shows all open ports with PIDs",
					Since: "v1.0",
				},
				{
					Cmd: "killport", Desc: "Kill process using specific port",
					Tags: []string{"kill", "port", "network"},
					Example: "killport 3000",
					Usage: "killport <port-number>",
					Since: "v1.1",
					Danger: true,
				},
				{
					Cmd: "myip", Desc: "Show public and local IP addresses",
					Tags: []string{"ip", "network", "wan", "lan"},
					Example: "myip",
					Usage: "Displays all network interfaces",
					Since: "v1.0",
				},
				{
					Cmd: "speedtest", Desc: "Test internet connection speed",
					Tags: []string{"speed", "network", "bandwidth"},
					Example: "speedtest",
					Usage: "Measures download/upload speed",
					Since: "v1.0",
				},
				{
					Cmd: "battery", Desc: "Display battery status and health",
					Tags: []string{"battery", "power", "laptop"},
					Example: "battery",
					Usage: "Shows charge level, health, cycles",
					Since: "v1.0",
				},
				{
					Cmd: "cleantemp", Desc: "Clean temporary files and cache",
					Tags: []string{"clean", "temp", "cache"},
					Example: "cleantemp",
					Usage: "Removes temp files safely",
					Since: "v1.0",
				},
				{
					Cmd: "up", Desc: "Check if a website is online",
					Tags: []string{"ping", "check", "status"},
					Example: "up google.com",
					Usage: "up <domain> - HTTP health check",
					Since: "v1.0",
				},
			},
		},
		{
			ID: "dev", Name: "Dev Tools", Icon: "🛠️", Gradient: "sunset",
			Commands: []Command{
				{
					Cmd: "install", Desc: "Install packages via Winget",
					Tags: []string{"install", "package", "winget"},
					Example: "install vscode",
					Usage: "install <package-name>",
					Since: "v1.0",
				},
				{
					Cmd: "calc", Desc: "Quick mathematical calculator",
					Tags: []string{"math", "calculate", "expression"},
					Example: "calc 2+2*3",
					Usage: "calc <expression>",
					Since: "v1.0",
				},
				{
					Cmd: "json", Desc: "Pretty print and validate JSON",
					Tags: []string{"json", "format", "validate"},
					Example: "json file.json",
					Usage: "json <file> or echo '{...}' | json",
					Since: "v1.0",
				},
				{
					Cmd: "passgen", Desc: "Generate secure random passwords",
					Tags: []string{"password", "security", "random"},
					Example: "passgen 16",
					Usage: "passgen [length] [-s symbols]",
					Since: "v1.0",
				},
				{
					Cmd: "timer", Desc: "Countdown timer with notification",
					Tags: []string{"timer", "countdown", "alarm"},
					Example: "timer 5m",
					Usage: "timer <duration> - e.g., 1h30m, 45s",
					Since: "v1.1",
				},
				{
					Cmd: "todo", Desc: "Simple task manager",
					Tags: []string{"todo", "tasks", "list"},
					Example: "todo add 'Fix bug'",
					Usage: "todo [add|done|list|clear] <task>",
					Since: "v1.2",
				},
				{
					Cmd: "short", Desc: "Shorten URLs using is.gd",
					Tags: []string{"url", "shorten", "link"},
					Example: "short https://example.com",
					Usage: "short <url>",
					Since: "v1.0",
				},
				{
					Cmd: "cheat", Desc: "Display command cheat sheets",
					Tags: []string{"help", "cheat", "reference"},
					Example: "cheat git",
					Usage: "cheat <topic>",
					Since: "v1.0",
				},
				{
					Cmd: "web", Desc: "Quick web search from terminal",
					Tags: []string{"search", "web", "google"},
					Example: "web golang tutorial",
					Usage: "web <query>",
					Since: "v1.0",
				},
			},
		},
		{
			ID: "admin", Name: "Admin", Icon: "🔐", Gradient: "fire",
			Commands: []Command{
				{
					Cmd: "sudo", Desc: "Run command with admin privileges",
					Tags: []string{"admin", "elevate", "uac"},
					Example: "sudo netstat -ab",
					Usage: "sudo <command>",
					Since: "v1.0",
					Danger: true,
				},
				{
					Cmd: "god", Desc: "Enter SYSTEM level God Mode",
					Tags: []string{"system", "god", "nt authority"},
					Example: "god",
					Usage: "Elevates to NT AUTHORITY\\SYSTEM",
					Since: "v1.0",
					Danger: true,
				},
				{
					Cmd: "ti", Desc: "Get TrustedInstaller privileges",
					Tags: []string{"trusted", "installer", "highest"},
					Example: "ti",
					Usage: "Ultimate Windows privileges",
					Since: "v1.0",
					Danger: true,
				},
				{
					Cmd: "drop", Desc: "Drop to normal user privileges",
					Tags: []string{"drop", "user", "deescalate"},
					Example: "drop",
					Usage: "Returns to normal user context",
					Since: "v1.0",
				},
				{
					Cmd: "def", Desc: "Toggle Windows Defender on/off",
					Tags: []string{"defender", "antivirus", "toggle"},
					Example: "def off",
					Usage: "def [on|off]",
					Since: "v1.1",
					Danger: true,
				},
				{
					Cmd: "avkill", Desc: "Terminate antivirus processes",
					Tags: []string{"av", "kill", "security"},
					Example: "avkill",
					Usage: "Forces AV shutdown",
					Since: "v1.2",
					Danger: true,
				},
				{
					Cmd: "nuke", Desc: "Force terminate any process",
					Tags: []string{"kill", "force", "process"},
					Example: "nuke notepad",
					Usage: "nuke <process-name|pid>",
					Since: "v1.0",
					Danger: true,
				},
				{
					Cmd: "ghost", Desc: "Clear all system logs and traces",
					Tags: []string{"logs", "clean", "forensics"},
					Example: "ghost",
					Usage: "Clears event logs, temp, history",
					Since: "v1.2",
					Danger: true,
				},
				{
					Cmd: "powerup", Desc: "Enable all token privileges",
					Tags: []string{"privilege", "token", "seDebug"},
					Example: "powerup",
					Usage: "Enables SeDebugPrivilege, etc.",
					Since: "v1.0",
					Danger: true,
				},
			},
		},
		{
			ID: "windows", Name: "Windows", Icon: "🪟", Gradient: "cyber",
			Commands: []Command{
				{
					Cmd: "star", Desc: "Pin window to prevent closing",
					Tags: []string{"pin", "lock", "topmost"},
					Example: "star notepad",
					Usage: "star <window-title>",
					Since: "v1.1",
				},
				{
					Cmd: "unstar", Desc: "Unpin window",
					Tags: []string{"unpin", "unlock"},
					Example: "unstar notepad",
					Usage: "unstar <window-title>",
					Since: "v1.1",
				},
				{
					Cmd: "wm", Desc: "Window manager for tiling",
					Tags: []string{"tile", "window", "layout"},
					Example: "wm tile",
					Usage: "wm [tile|cascade|stack]",
					Since: "v1.2",
				},
				{
					Cmd: "hyp", Desc: "Check Hypervisor status",
					Tags: []string{"hypervisor", "vm", "virtualization"},
					Example: "hyp",
					Usage: "Checks Hyper-V, VMware, VBox",
					Since: "v1.0",
				},
				{
					Cmd: "uefi", Desc: "Display UEFI/BIOS information",
					Tags: []string{"uefi", "bios", "firmware"},
					Example: "uefi",
					Usage: "Shows firmware details",
					Since: "v1.0",
				},
				{
					Cmd: "vmx", Desc: "Inject commands into VM",
					Tags: []string{"vm", "inject", "guest"},
					Example: "vmx run 'dir'",
					Usage: "vmx [run|file] <cmd|path>",
					Since: "v1.3",
					Danger: true,
				},
				{
					Cmd: "cmd", Desc: "Command palette launcher",
					Hot: "Ctrl+P", Tags: []string{"palette", "launcher", "quick"},
					Example: "cmd",
					Usage: "Opens fuzzy command finder",
					Since: "v1.0",
				},
			},
		},
		{
			ID: "search", Name: "Search", Icon: "🔍", Gradient: "royal",
			Commands: []Command{
				{
					Cmd: "ff", Desc: "Find files by name with fuzzy match",
					Tags: []string{"find", "fuzzy", "files"},
					Example: "ff *.go",
					Usage: "ff <pattern> [-d dir]",
					Since: "v1.0",
				},
				{
					Cmd: "ftext", Desc: "Search for text inside files",
					Tags: []string{"grep", "content", "search"},
					Example: "ftext 'TODO' *.go",
					Usage: "ftext <text> [files]",
					Since: "v1.0",
				},
				{
					Cmd: "dup", Desc: "Find duplicate files",
					Tags: []string{"duplicate", "find", "hash"},
					Example: "dup ~/Downloads",
					Usage: "dup [path] - Uses SHA256",
					Since: "v1.1",
				},
				{
					Cmd: "recent", Desc: "List recently modified files",
					Tags: []string{"recent", "modified", "new"},
					Example: "recent -n 20",
					Usage: "recent [-n count] [path]",
					Since: "v1.0",
				},
				{
					Cmd: "sizesort", Desc: "Analyze folder sizes",
					Tags: []string{"size", "analyze", "disk"},
					Example: "sizesort",
					Usage: "sizesort [path] - Shows largest items",
					Since: "v1.0",
				},
				{
					Cmd: "count", Desc: "Count files, folders, and lines",
					Tags: []string{"count", "stats", "lines"},
					Example: "count *.go",
					Usage: "count [pattern] - File statistics",
					Since: "v1.0",
				},
				{
					Cmd: "hh", Desc: "Search command history",
					Tags: []string{"history", "search", "past"},
					Example: "hh git",
					Usage: "hh [query] - Fuzzy history search",
					Since: "v1.0",
				},
			},
		},
		{
			ID: "git", Name: "Git", Icon: "", Gradient: "emerald",
			Commands: []Command{
				{
					Cmd: "gs", Desc: "Show git status with enhanced view",
					Tags: []string{"status", "changes"},
					Example: "gs",
					Usage: "Enhanced git status",
					Since: "v1.0",
				},
				{
					Cmd: "ga", Desc: "Stage files for commit",
					Tags: []string{"add", "stage"},
					Example: "ga .",
					Usage: "ga [files] - git add",
					Since: "v1.0",
				},
				{
					Cmd: "gc", Desc: "Commit staged changes",
					Tags: []string{"commit", "save"},
					Example: "gc 'feat: new feature'",
					Usage: "gc '<message>'",
					Since: "v1.0",
				},
				{
					Cmd: "gp", Desc: "Push commits to remote",
					Tags: []string{"push", "remote", "upload"},
					Example: "gp",
					Usage: "gp [remote] [branch]",
					Since: "v1.0",
				},
				{
					Cmd: "gl", Desc: "Pull changes from remote",
					Tags: []string{"pull", "remote", "download"},
					Example: "gl",
					Usage: "gl [remote] [branch]",
					Since: "v1.0",
				},
				{
					Cmd: "glog", Desc: "Show pretty git log graph",
					Tags: []string{"log", "history", "graph"},
					Example: "glog -n 10",
					Usage: "glog [-n count]",
					Since: "v1.0",
				},
				{
					Cmd: "gd", Desc: "Show file differences",
					Tags: []string{"diff", "changes", "compare"},
					Example: "gd HEAD~1",
					Usage: "gd [ref]",
					Since: "v1.0",
				},
				{
					Cmd: "gb", Desc: "List and manage branches",
					Tags: []string{"branch", "list"},
					Example: "gb -a",
					Usage: "gb [-a all] [-d delete]",
					Since: "v1.0",
				},
				{
					Cmd: "gco", Desc: "Switch branches",
					Tags: []string{"checkout", "switch", "branch"},
					Example: "gco main",
					Usage: "gco <branch> [-b new]",
					Since: "v1.0",
				},
				{
					Cmd: "gst", Desc: "Stash current changes",
					Tags: []string{"stash", "save", "temporary"},
					Example: "gst",
					Usage: "gst [pop|list|drop]",
					Since: "v1.0",
				},
			},
		},
	}
}

// ══════════════════════════════════════════════════════════════════
//                         INITIALIZATION
// ══════════════════════════════════════════════════════════════════

func newModel() Model {
	ti := textinput.New()
	ti.Placeholder = "✨ Type to search commands..."
	ti.CharLimit = 64
	ti.Width = 40
	ti.PromptStyle = lipgloss.NewStyle().Foreground(lipgloss.Color(colors.primary))
	ti.TextStyle = lipgloss.NewStyle().Foreground(lipgloss.Color(colors.text))
	ti.PlaceholderStyle = lipgloss.NewStyle().Foreground(lipgloss.Color(colors.textMuted))
	ti.Cursor.Style = lipgloss.NewStyle().Foreground(lipgloss.Color(colors.accent))

	m := Model{
		categories:  initData(),
		searchInput: ti,
		hoverCat:    -1,
		hoverItem:   -1,
		hitBoxes:    make([]HitBox, 0, 64),
		usageStats:  make(map[string]int),
		startTime:   time.Now(),
	}

	// Calculate total commands
	for _, cat := range m.categories {
		m.totalCmds += len(cat.Commands)
	}

	m.updateFiltered()
	return m
}

func (m Model) Init() tea.Cmd {
	return tea.Batch(
		textinput.Blink,
		tea.EnableMouseAllMotion,
		m.tickCmd(),
	)
}

func (m Model) tickCmd() tea.Cmd {
	return tea.Tick(time.Millisecond*80, func(t time.Time) tea.Msg {
		return TickMsg(t)
	})
}

// ══════════════════════════════════════════════════════════════════
//                         LAYOUT CALCULATION
// ══════════════════════════════════════════════════════════════════

func (m *Model) calculateLayout() {
	// Responsive breakpoints
	isSmall := m.width < 100
	isMedium := m.width >= 100 && m.width < 140

	m.layout.Padding = 2
	if isSmall {
		m.layout.Padding = 1
	}

	// Calculate tabs per row based on width
	if isSmall {
		m.layout.TabsPerRow = 4
		m.layout.TabW = (m.width - 4) / 4
	} else if isMedium {
		m.layout.TabsPerRow = 6
		m.layout.TabW = (m.width - 6) / 6
	} else {
		m.layout.TabsPerRow = 8
		m.layout.TabW = (m.width - 8) / 8
	}

	// Calculate rows needed for tabs
	tabRows := (len(m.categories) + m.layout.TabsPerRow - 1) / m.layout.TabsPerRow

	// Fixed heights
	m.layout.HeaderH = 8
	m.layout.TabsH = tabRows + 1
	m.layout.SearchH = 5
	m.layout.StatusH = 2

	// Content height
	m.layout.ContentH = m.height - m.layout.HeaderH - m.layout.TabsH - m.layout.SearchH - m.layout.StatusH - 2

	// List and detail widths
	contentW := m.width - (m.layout.Padding * 2) - 2
	if isSmall {
		m.layout.ListW = contentW
		m.layout.DetailW = 0
	} else {
		m.layout.ListW = contentW * 45 / 100
		m.layout.DetailW = contentW - m.layout.ListW - 2
	}
}

func (m *Model) recalcHitBoxes() {
	m.hitBoxes = m.hitBoxes[:0]

	// Tabs
	pad := m.layout.Padding
	tabW := m.layout.TabW
	perRow := m.layout.TabsPerRow

	for i := range m.categories {
		col := i % perRow
		row := i / perRow
		x := pad + col*(tabW-1)
		y := m.layout.HeaderH + row + 1

		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: x, Y: y, W: tabW - 1, H: 1,
			Type: "cat", Index: i,
		})
	}

	// Search
	y := m.layout.HeaderH + m.layout.TabsH + 1
	m.hitBoxes = append(m.hitBoxes, HitBox{
		X: m.layout.Padding, Y: y,
		W: m.width - m.layout.Padding*2, H: 1,
		Type: "search", ID: "search",
	})

	// List
	listStartY := m.layout.HeaderH + m.layout.TabsH + m.layout.SearchH + 1
	visible := m.layout.ContentH - 3

	for i := 0; i < visible; i++ {
		idx := i + m.scrollY
		if idx < len(m.filtered) {
			m.hitBoxes = append(m.hitBoxes, HitBox{
				X: m.layout.Padding, Y: listStartY + i,
				W: m.layout.ListW - 1, H: 1,
				Type: "item", Index: idx,
			})
		}
	}

	// Detail (Button)
	if m.layout.DetailW > 0 && m.itemIndex < len(m.filtered) {
		item := m.filtered[m.itemIndex]
		linesCount := 0
		linesCount += 1 // Empty
		linesCount += 1 // COMMAND label
		linesCount += 1 // Command
		linesCount += 1 // Empty
		linesCount += 1 // DESCRIPTION label

		desc := item.Desc
		maxDescW := m.layout.DetailW - 6
		if len(desc) > maxDescW {
			linesCount += 2
		} else {
			linesCount += 1
		}
		linesCount += 1 // Empty

		if item.Hot != "" {
			linesCount += 3 // LABEL + HOTKEY + Empty
		}

		if len(item.Tags) > 0 {
			linesCount += 3 // LABEL + TAGS + Empty
		}

		linesCount += 1 // Empty before button

		buttonY := m.layout.HeaderH + m.layout.TabsH + m.layout.SearchH + 1 + linesCount
		m.hitBoxes = append(m.hitBoxes, HitBox{
			X: m.layout.Padding + m.layout.ListW + 4, Y: buttonY,
			W: 24, H: 1,
			Type: "btn", ID: "copy",
		})
	}

	// Help Button (Status)
	m.hitBoxes = append(m.hitBoxes, HitBox{
		X: m.width - 10, Y: m.height - 2,
		W: 8, H: 1,
		Type: "btn", ID: "help",
	})
}

func (m *Model) updateFiltered() {
	cat := m.categories[m.catIndex]
	query := strings.ToLower(strings.TrimSpace(m.searchInput.Value()))

	if query == "" {
		m.filtered = cat.Commands
		return
	}

	seen := make(map[string]bool)
	m.filtered = nil

	for _, cmd := range cat.Commands {
		if seen[cmd.Cmd] {
			continue
		}
		if strings.Contains(strings.ToLower(cmd.Cmd), query) ||
			strings.Contains(strings.ToLower(cmd.Desc), query) {
			m.filtered = append(m.filtered, cmd)
			seen[cmd.Cmd] = true
			continue
		}
		for _, tag := range cmd.Tags {
			if strings.Contains(strings.ToLower(tag), query) {
				m.filtered = append(m.filtered, cmd)
				seen[cmd.Cmd] = true
				break
			}
		}
	}
}

// ══════════════════════════════════════════════════════════════════
//                         STYLE HELPERS
// ══════════════════════════════════════════════════════════════════

func getGradient(name string) []string {
	if g, ok := gradients[name]; ok {
		return g
	}
	return gradients["cyber"]
}

func lerpColor(colors []string, t float64) string {
	if len(colors) == 0 {
		return "#FFFFFF"
	}
	if t <= 0 || len(colors) == 1 {
		return colors[0]
	}
	if t >= 1 {
		return colors[len(colors)-1]
	}

	idx := int(t * float64(len(colors)-1))
	if idx >= len(colors)-1 {
		idx = len(colors) - 2
	}
	return colors[idx]
}

func gradientStr(s string, grad string) string {
	cols := getGradient(grad)
	runes := []rune(s)
	n := len(runes)
	if n == 0 {
		return ""
	}

	var b strings.Builder
	for i, r := range runes {
		t := float64(i) / float64(max(1, n-1))
		c := lerpColor(cols, t)
		style := lipgloss.NewStyle().Foreground(lipgloss.Color(c))
		b.WriteString(style.Render(string(r)))
	}
	return b.String()
}

func boxStyle(selected, hovered bool, grad string) lipgloss.Style {
	cols := getGradient(grad)
	borderColor := colors.border

	if selected {
		borderColor = cols[0]
	} else if hovered {
		borderColor = cols[len(cols)-1]
	}

	return lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(borderColor))
}

// ══════════════════════════════════════════════════════════════════
//                         UPDATE
// ══════════════════════════════════════════════════════════════════

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case TickMsg:
		m.frame++
		if m.copyTimer > 0 {
			m.copyTimer--
			if m.copyTimer == 0 {
				m.copied = false
			}
		}
		return m, m.tickCmd()

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.calculateLayout()
		m.recalcHitBoxes()
		return m, nil

	case tea.KeyMsg:
		newM, cmd := m.handleKey(msg)
		finalM := newM.(Model)
		finalM.recalcHitBoxes()
		return finalM, cmd

	case tea.MouseMsg:
		newM, cmd := m.handleMouse(msg)
		finalM := newM.(Model)
		finalM.recalcHitBoxes()
		return finalM, cmd
	}

	if m.searchMode {
		var cmd tea.Cmd
		m.searchInput, cmd = m.searchInput.Update(msg)
		m.updateFiltered()
		m.itemIndex = 0
		m.scrollY = 0
		m.recalcHitBoxes()
		return m, cmd
	}

	return m, nil
}

func (m Model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	key := msg.String()

	// Search mode
	if m.searchMode {
		switch key {
		case "esc":
			m.searchMode = false
			m.searchInput.Blur()
		case "enter":
			m.searchMode = false
			m.searchInput.Blur()
		case "up":
			if m.itemIndex > 0 {
				m.itemIndex--
				m.adjustScroll()
			}
		case "down":
			if m.itemIndex < len(m.filtered)-1 {
				m.itemIndex++
				m.adjustScroll()
			}
		default:
			var cmd tea.Cmd
			m.searchInput, cmd = m.searchInput.Update(msg)
			m.updateFiltered()
			m.itemIndex = 0
			m.scrollY = 0
			// recalcHitBoxes called in Update return
			return m, cmd
		}
		return m, nil
	}

	// Help mode
	if m.showHelp {
		m.showHelp = false
		return m, nil
	}

	maxItem := len(m.filtered) - 1

	switch key {
	case "q", "ctrl+c":
		return m, tea.Quit

	case "up", "k":
		if m.itemIndex > 0 {
			m.itemIndex--
			m.adjustScroll()
		}

	case "down", "j":
		if m.itemIndex < maxItem {
			m.itemIndex++
			m.adjustScroll()
		}

	case "left", "h":
		m.catIndex = (m.catIndex - 1 + len(m.categories)) % len(m.categories)
		m.resetSelection()

	case "right", "l":
		m.catIndex = (m.catIndex + 1) % len(m.categories)
		m.resetSelection()

	case "tab":
		m.catIndex = (m.catIndex + 1) % len(m.categories)
		m.resetSelection()

	case "shift+tab":
		m.catIndex = (m.catIndex - 1 + len(m.categories)) % len(m.categories)
		m.resetSelection()

	case "/", "ctrl+f":
		m.searchMode = true
		m.searchInput.Focus()
		return m, textinput.Blink

	case "?", "f1":
		m.showHelp = true

	case "enter", " ":
		m.doCopy()

	case "home", "g":
		m.itemIndex = 0
		m.scrollY = 0

	case "end", "G":
		m.itemIndex = maxItem
		m.adjustScroll()

	case "pgup":
		m.itemIndex = max(0, m.itemIndex-10)
		m.adjustScroll()

	case "pgdown":
		m.itemIndex = min(maxItem, m.itemIndex+10)
		m.adjustScroll()

	case "esc":
		if m.searchInput.Value() != "" {
			m.searchInput.Reset()
			m.updateFiltered()
			m.itemIndex = 0
			m.scrollY = 0
		}

	case "1", "2", "3", "4", "5", "6", "7", "8", "9":
		idx := int(key[0] - '1')
		if idx < len(m.categories) {
			m.catIndex = idx
			m.resetSelection()
		}
	}

	return m, nil
}

func (m Model) handleMouse(msg tea.MouseMsg) (tea.Model, tea.Cmd) {
	m.mouseX = msg.X
	m.mouseY = msg.Y

	// Reset hover
	m.hoverCat = -1
	m.hoverItem = -1
	m.hoverBtn = ""

	// Check hitboxes
	for _, hb := range m.hitBoxes {
		if msg.X >= hb.X && msg.X < hb.X+hb.W &&
			msg.Y >= hb.Y && msg.Y < hb.Y+hb.H {
			switch hb.Type {
			case "cat":
				m.hoverCat = hb.Index
			case "item":
				m.hoverItem = hb.Index
			case "btn":
				m.hoverBtn = hb.ID
			case "search":
				m.hoverBtn = "search"
			}
		}
	}

	// Handle click
	switch msg.Type {
	case tea.MouseLeft:
		now := time.Now()
		m.doubleClick = now.Sub(m.lastClick) < 300*time.Millisecond
		m.lastClick = now

		if m.hoverCat >= 0 {
			m.catIndex = m.hoverCat
			m.resetSelection()
		}

		if m.hoverItem >= 0 {
			if m.hoverItem == m.itemIndex && m.doubleClick {
				m.doCopy()
			}
			m.itemIndex = m.hoverItem
		}

		if m.hoverBtn == "copy" {
			m.doCopy()
		}

		if m.hoverBtn == "search" {
			m.searchMode = true
			m.searchInput.Focus()
			return m, textinput.Blink
		}

		if m.hoverBtn == "help" {
			m.showHelp = true
		}

	case tea.MouseWheelUp:
		if m.scrollY > 0 {
			m.scrollY--
		}

	case tea.MouseWheelDown:
		maxScroll := max(0, len(m.filtered)-m.layout.ContentH+4)
		if m.scrollY < maxScroll {
			m.scrollY++
		}
	}

	return m, nil
}

func (m *Model) resetSelection() {
	m.itemIndex = 0
	m.scrollY = 0
	m.updateFiltered()
}

func (m *Model) adjustScroll() {
	visible := m.layout.ContentH - 4
	if visible < 1 {
		visible = 1
	}

	if m.itemIndex < m.scrollY {
		m.scrollY = m.itemIndex
	} else if m.itemIndex >= m.scrollY+visible {
		m.scrollY = m.itemIndex - visible + 1
	}
}

func (m *Model) doCopy() {
	if m.itemIndex < len(m.filtered) {
		cmd := m.filtered[m.itemIndex].Cmd
		clipboard.WriteAll(cmd)
		m.copied = true
		m.copyTimer = 25
	}
}

// ══════════════════════════════════════════════════════════════════
//                         VIEW
// ══════════════════════════════════════════════════════════════════

func (m Model) View() string {
	if m.width < 50 || m.height < 15 {
		return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center,
			lipgloss.NewStyle().Foreground(lipgloss.Color(colors.warning)).
				Render("⚠️  Please resize window (min 50x15)"))
	}

	// Hitboxes are now calculated in Update/recalcHitBoxes

	var view strings.Builder

	view.WriteString(m.viewHeader())
	view.WriteString(m.viewTabs())
	view.WriteString(m.viewSearch())
	view.WriteString(m.viewContent())
	view.WriteString(m.viewStatus())

	if m.showHelp {
		return m.viewHelp()
	}

	return view.String()
}

func (m Model) viewHeader() string {
	// Animated logo
	logo := `
 ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗
 ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝
 ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗  
 ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝  
 ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗
  ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝`

	// Cycle gradient
	gradList := []string{"neon", "cyber", "sunset", "ocean", "fire", "matrix"}
	grad := gradList[(m.frame/40)%len(gradList)]

	lines := strings.Split(logo, "\n")
	var header strings.Builder

	for _, line := range lines {
		styled := gradientStr(line, grad)
		header.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center, styled) + "\n")
	}

	// Subtitle with animation
	spin := dots[(m.frame/2)%len(dots)]
	sub := fmt.Sprintf("%s PowerShell Feature Matrix %s", spin, spin)
	header.WriteString(lipgloss.PlaceHorizontal(m.width, lipgloss.Center, gradientStr(sub, "sunset")))

	return header.String() + "\n"
}

func (m *Model) viewTabs() string {
	var tabs strings.Builder
	tabs.WriteString("\n")

	// pad := m.layout.Padding // Unused
	tabW := m.layout.TabW
	perRow := m.layout.TabsPerRow

	for i, cat := range m.categories {
		col := i % perRow
		// row := i / perRow // Unused now
		// x := pad + col*tabW // Unused
		// y := m.layout.HeaderH + row // Unused

		// Hitboxes calculated in recalcHitBoxes

		isSelected := i == m.catIndex
		isHovered := i == m.hoverCat
		grad := getGradient(cat.Gradient)

		var style lipgloss.Style
		if isSelected {
			style = lipgloss.NewStyle().
				Background(lipgloss.Color(grad[0])).
				Foreground(lipgloss.Color("#000000")).
				Bold(true).
				Padding(0, 1)
		} else if isHovered {
			style = lipgloss.NewStyle().
				Background(lipgloss.Color(colors.surfaceHL)).
				Foreground(lipgloss.Color(grad[0])).
				Padding(0, 1)
		} else {
			style = lipgloss.NewStyle().
				Foreground(lipgloss.Color(colors.textDim)).
				Padding(0, 1)
		}

		indicator := " "
		if isSelected {
			indicator = "▸"
		} else if isHovered {
			indicator = "›"
		}

		numKey := ""
		if i < 9 {
			numKey = fmt.Sprintf("%d:", i+1)
		}

		content := fmt.Sprintf("%s%s%s %s", indicator, numKey, cat.Icon, cat.Name)

		// Truncate if needed
		maxLen := tabW - 4
		if len(content) > maxLen {
			content = content[:maxLen-1] + "…"
		}

		tabs.WriteString(style.Width(tabW - 1).Render(content))

		if col == perRow-1 || i == len(m.categories)-1 {
			tabs.WriteString("\n")
		}
	}

	return tabs.String()
}

func (m *Model) viewSearch() string {
	// y := m.layout.HeaderH + m.layout.TabsH + 1 // Unused

	// Hitboxes calculated in recalcHitBoxes

	isActive := m.searchMode
	isHovered := m.hoverBtn == "search"

	borderColor := colors.border
	if isActive {
		borderColor = colors.primary
	} else if isHovered {
		borderColor = colors.borderHL
	}

	bgColor := colors.surface
	if isActive {
		bgColor = colors.surfaceHL
	}

	style := lipgloss.NewStyle().
		Background(lipgloss.Color(bgColor)).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color(borderColor)).
		Padding(0, 1).
		Width(m.width - m.layout.Padding*2 - 4)

	icon := "🔍"
	var content string

	if isActive {
		content = fmt.Sprintf(" %s  %s", icon, m.searchInput.View())
	} else if m.searchInput.Value() != "" {
		content = fmt.Sprintf(" %s  %s (ESC to clear)",
			icon, gradientStr(m.searchInput.Value(), "cyber"))
	} else {
		hint := "Press / to search..."
		if isHovered {
			hint = "Click to search..."
		}
		content = fmt.Sprintf(" %s  %s", icon,
			lipgloss.NewStyle().Foreground(lipgloss.Color(colors.textMuted)).Render(hint))
	}

	bar := style.Render(content)
	return "\n" + lipgloss.PlaceHorizontal(m.width, lipgloss.Center, bar) + "\n\n"
}

func (m *Model) viewContent() string {
	if m.layout.DetailW == 0 {
		// Small screen: only list
		return lipgloss.NewStyle().
			MarginLeft(m.layout.Padding).
			Render(m.viewList())
	}

	// Normal: list + detail
	list := m.viewList()
	detail := m.viewDetail()

	return lipgloss.JoinHorizontal(lipgloss.Top,
		lipgloss.NewStyle().MarginLeft(m.layout.Padding).Render(list),
		lipgloss.NewStyle().MarginLeft(1).Render(detail),
	) + "\n"
}

func (m *Model) viewList() string {
	cat := m.categories[m.catIndex]
	grad := getGradient(cat.Gradient)
	height := m.layout.ContentH

	var s strings.Builder

	// Header
	title := fmt.Sprintf(" %s %s ", cat.Icon, cat.Name)
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(grad[0])).
		Bold(true)

	headerLen := lipgloss.Width(title)
	padLen := m.layout.ListW - headerLen - 4
	if padLen < 0 {
		padLen = 0
	}

	s.WriteString(gradientStr("╭─", cat.Gradient))
	s.WriteString(headerStyle.Render(title))
	s.WriteString(gradientStr(strings.Repeat("─", padLen)+"╮", cat.Gradient))
	s.WriteString("\n")

	// Items
	// listStartY := m.layout.HeaderH + m.layout.TabsH + m.layout.SearchH + 2 // Unused
	visible := height - 3

	for i := 0; i < visible; i++ {
		idx := i + m.scrollY

		// Border color
		borderT := float64(i) / float64(visible)
		borderC := lerpColor(grad, borderT)
		border := lipgloss.NewStyle().Foreground(lipgloss.Color(borderC)).Render("│")

		s.WriteString(border)

		if idx < len(m.filtered) {
			item := m.filtered[idx]
			isSelected := idx == m.itemIndex
			isHovered := idx == m.hoverItem

			// Hitboxes calculated in recalcHitBoxes

			var itemStyle lipgloss.Style
			indicator := "  "

			if isSelected {
				itemStyle = lipgloss.NewStyle().
					Background(lipgloss.Color(grad[0])).
					Foreground(lipgloss.Color("#000000")).
					Bold(true).
					Width(m.layout.ListW - 3)
				indicator = "▶ "
			} else if isHovered {
				itemStyle = lipgloss.NewStyle().
					Background(lipgloss.Color(colors.surfaceHL)).
					Foreground(lipgloss.Color(grad[len(grad)-1])).
					Width(m.layout.ListW - 3)
				indicator = "› "
			} else {
				itemStyle = lipgloss.NewStyle().
					Foreground(lipgloss.Color(colors.text)).
					Width(m.layout.ListW - 3)
			}

			// Truncate command
			cmdDisplay := item.Cmd
			maxLen := m.layout.ListW - 8
			if len(cmdDisplay) > maxLen {
				cmdDisplay = cmdDisplay[:maxLen-1] + "…"
			}

			content := indicator + cmdDisplay
			s.WriteString(itemStyle.Render(content))
		} else {
			s.WriteString(strings.Repeat(" ", m.layout.ListW-2))
		}

		s.WriteString(border + "\n")
	}

	// Scrollbar
	if len(m.filtered) > visible {
		scrollbarH := max(1, visible*visible/len(m.filtered))
		scrollbarPos := m.scrollY * (visible - scrollbarH) / max(1, len(m.filtered)-visible)
		// Could render scrollbar track here
		_ = scrollbarH
		_ = scrollbarPos
	}

	// Footer with stats
	stats := fmt.Sprintf(" %d/%d ", min(m.itemIndex+1, len(m.filtered)), len(m.filtered))
	statsLen := len(stats)
	footerPad := m.layout.ListW - statsLen - 4
	if footerPad < 0 {
		footerPad = 0
	}

	s.WriteString(gradientStr("╰"+strings.Repeat("─", footerPad), cat.Gradient))
	s.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color(colors.textDim)).Render(stats))
	s.WriteString(gradientStr("─╯", cat.Gradient))

	return s.String()
}

func (m *Model) viewDetail() string {
	cat := m.categories[m.catIndex]
	grad := getGradient(cat.Gradient)
	height := m.layout.ContentH
	width := m.layout.DetailW

	var s strings.Builder

	// Header
	title := " 📖 Details "
	headerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color(grad[len(grad)-1])).
		Bold(true)

	headerLen := lipgloss.Width(title)
	padLen := width - headerLen - 4
	if padLen < 0 {
		padLen = 0
	}

	s.WriteString(gradientStr("╭─", cat.Gradient))
	s.WriteString(headerStyle.Render(title))
	s.WriteString(gradientStr(strings.Repeat("─", padLen)+"╮", cat.Gradient))
	s.WriteString("\n")

	// Content
	var lines []string

	if m.itemIndex < len(m.filtered) {
		item := m.filtered[m.itemIndex]

		// Command
		lines = append(lines, "")
		lines = append(lines, lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.textDim)).Render("  COMMAND"))
		lines = append(lines, lipgloss.NewStyle().
			Foreground(lipgloss.Color(grad[0])).
			Bold(true).Render("  "+item.Cmd))
		lines = append(lines, "")

		// Description
		lines = append(lines, lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.textDim)).Render("  DESCRIPTION"))

		// Word wrap description
		desc := item.Desc
		maxDescW := width - 6
		if len(desc) > maxDescW {
			lines = append(lines, lipgloss.NewStyle().
				Foreground(lipgloss.Color(colors.text)).Render("  "+desc[:maxDescW]))
			lines = append(lines, lipgloss.NewStyle().
				Foreground(lipgloss.Color(colors.text)).Render("  "+desc[maxDescW:]))
		} else {
			lines = append(lines, lipgloss.NewStyle().
				Foreground(lipgloss.Color(colors.text)).Render("  "+desc))
		}
		lines = append(lines, "")

		// Hotkey
		if item.Hot != "" {
			lines = append(lines, lipgloss.NewStyle().
				Foreground(lipgloss.Color(colors.textDim)).Render("  HOTKEY"))
			lines = append(lines, "  "+gradientStr(item.Hot, "sunset"))
			lines = append(lines, "")
		}

		// Tags
		if len(item.Tags) > 0 {
			lines = append(lines, lipgloss.NewStyle().
				Foreground(lipgloss.Color(colors.textDim)).Render("  TAGS"))

			var tagLine strings.Builder
			tagLine.WriteString("  ")
			for _, tag := range item.Tags {
				tagStyle := lipgloss.NewStyle().
					Background(lipgloss.Color("#0F3D0F")).
					Foreground(lipgloss.Color(colors.success)).
					Padding(0, 1)
				tagLine.WriteString(tagStyle.Render(tag) + " ")
			}
			lines = append(lines, tagLine.String())
			lines = append(lines, "")
		}

		// Copy button
		lines = append(lines, "")

		// buttonY := m.layout.HeaderH + m.layout.TabsH + m.layout.SearchH + 2 + len(lines)
		// Hitboxes calculated in recalcHitBoxes

		var btn string
		if m.copied {
			btn = lipgloss.NewStyle().
				Background(lipgloss.Color("#064E3B")).
				Foreground(lipgloss.Color(colors.success)).
				Bold(true).
				Padding(0, 2).
				Render("  ✓ Copied to clipboard!  ")
		} else if m.hoverBtn == "copy" {
			btn = lipgloss.NewStyle().
				Background(lipgloss.Color(grad[0])).
				Foreground(lipgloss.Color("#000000")).
				Bold(true).
				Padding(0, 2).
				Render("  📋 Click to Copy  ")
		} else {
			btn = lipgloss.NewStyle().
				Background(lipgloss.Color(colors.surfaceHL)).
				Foreground(lipgloss.Color(grad[0])).
				Padding(0, 2).
				Render("  📋 Press Enter to Copy  ")
		}
		lines = append(lines, "  "+btn)

		// Usage tip
		lines = append(lines, "")
		lines = append(lines, lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.textMuted)).
			Italic(true).
			Render("  💡 Double-click item to copy"))
	} else {
		lines = append(lines, "")
		lines = append(lines, lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.textMuted)).
			Italic(true).
			Render("  No command selected"))
	}

	// Render lines
	visible := height - 3
	for i := 0; i < visible; i++ {
		borderT := float64(i) / float64(visible)
		borderC := lerpColor(grad, borderT)
		border := lipgloss.NewStyle().Foreground(lipgloss.Color(borderC)).Render("│")

		s.WriteString(border)

		if i < len(lines) {
			line := lines[i]
			lineW := lipgloss.Width(line)
			pad := width - lineW - 2
			if pad < 0 {
				pad = 0
			}
			s.WriteString(line + strings.Repeat(" ", pad))
		} else {
			s.WriteString(strings.Repeat(" ", width-2))
		}

		s.WriteString(border + "\n")
	}

	// Footer
	s.WriteString(gradientStr("╰"+strings.Repeat("─", width-2)+"╯", cat.Gradient))

	return s.String()
}

func (m *Model) viewStatus() string {
	bgStyle := lipgloss.NewStyle().
		Background(lipgloss.Color(colors.bgDark)).
		Width(m.width)

	// Hitboxes calculated in recalcHitBoxes

	// Keybinds
	binds := []struct {
		key, label, color string
	}{
		{"↑↓", "Nav", colors.primary},
		{"←→", "Cat", colors.secondary},
		{"/", "Find", colors.accent},
		{"⏎", "Copy", colors.success},
	}

	var left strings.Builder
	for _, b := range binds {
		keyStyle := lipgloss.NewStyle().
			Background(lipgloss.Color(colors.surface)).
			Foreground(lipgloss.Color(b.color)).
			Bold(true).
			Padding(0, 1)
		labelStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.textDim))

		left.WriteString(keyStyle.Render(b.key))
		left.WriteString(labelStyle.Render(" " + b.label + " "))
	}

	// Right side
	cat := m.categories[m.catIndex]
	spin := spinners[m.frame%len(spinners)]

	rightStyle := lipgloss.NewStyle().Foreground(lipgloss.Color(colors.textDim))
	helpStyle := lipgloss.NewStyle()
	if m.hoverBtn == "help" {
		helpStyle = helpStyle.
			Background(lipgloss.Color(colors.surface)).
			Foreground(lipgloss.Color(colors.warning))
	} else {
		helpStyle = helpStyle.Foreground(lipgloss.Color(colors.textMuted))
	}

	right := fmt.Sprintf("%s %s %s  %s",
		gradientStr(spin, cat.Gradient),
		cat.Icon,
		rightStyle.Render(cat.Name),
		helpStyle.Render("? Help"),
	)

	leftStr := left.String()
	leftW := lipgloss.Width(leftStr)
	rightW := lipgloss.Width(right)
	pad := m.width - leftW - rightW - 4
	if pad < 0 {
		pad = 0
	}

	return bgStyle.Render(fmt.Sprintf("  %s%s%s  ", leftStr, strings.Repeat(" ", pad), right))
}

func (m Model) viewHelp() string {
	width := 60

	var help strings.Builder
	help.WriteString(gradientStr("╔══════════════════ ⌨️  CONTROLS ══════════════════╗", "neon") + "\n")

	binds := []struct {
		key, desc string
	}{
		{"↑ / k", "Move up"},
		{"↓ / j", "Move down"},
		{"← / h", "Previous category"},
		{"→ / l", "Next category"},
		{"1-9", "Jump to category"},
		{"Tab", "Next category"},
		{"Shift+Tab", "Previous category"},
		{"/ or Ctrl+F", "Search"},
		{"Enter / Space", "Copy command"},
		{"g / Home", "Go to first"},
		{"G / End", "Go to last"},
		{"PgUp / PgDn", "Page scroll"},
		{"Esc", "Clear search"},
		{"? / F1", "Toggle help"},
		{"q", "Quit"},
	}

	for _, b := range binds {
		keyStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.warning)).
			Bold(true).
			Width(16)
		descStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color(colors.text))

		help.WriteString(gradientStr("║", "neon"))
		line := fmt.Sprintf(" %s %s", keyStyle.Render(b.key), descStyle.Render(b.desc))
		pad := width - lipgloss.Width(line) - 2
		if pad < 0 {
			pad = 0
		}
		help.WriteString(line + strings.Repeat(" ", pad))
		help.WriteString(gradientStr("║", "neon") + "\n")
	}

	help.WriteString(gradientStr("║", "neon") + strings.Repeat(" ", width-2) + gradientStr("║", "neon") + "\n")

	mouseHelp := lipgloss.NewStyle().
		Foreground(lipgloss.Color(colors.primary)).
		Bold(true).
		Render("🖱️  Click • Double-click • Hover • Scroll")

	help.WriteString(gradientStr("║", "neon"))
	help.WriteString("  " + mouseHelp)
	pad := width - lipgloss.Width(mouseHelp) - 4
	if pad < 0 {
		pad = 0
	}
	help.WriteString(strings.Repeat(" ", pad))
	help.WriteString(gradientStr("║", "neon") + "\n")

	help.WriteString(gradientStr("║", "neon") + strings.Repeat(" ", width-2) + gradientStr("║", "neon") + "\n")

	closeHint := lipgloss.NewStyle().
		Foreground(lipgloss.Color(colors.textMuted)).
		Italic(true).
		Render("Press any key to close")

	help.WriteString(gradientStr("║", "neon"))
	pad = (width - lipgloss.Width(closeHint) - 2) / 2
	help.WriteString(strings.Repeat(" ", pad) + closeHint + strings.Repeat(" ", width-pad-lipgloss.Width(closeHint)-2))
	help.WriteString(gradientStr("║", "neon") + "\n")

	help.WriteString(gradientStr("╚"+strings.Repeat("═", width-2)+"╝", "neon"))

	box := lipgloss.NewStyle().
		Background(lipgloss.Color(colors.bgDark)).
		Border(lipgloss.DoubleBorder()).
		BorderForeground(lipgloss.Color(colors.secondary)).
		Padding(1, 2).
		Render(help.String())

	return lipgloss.Place(m.width, m.height,
		lipgloss.Center, lipgloss.Center,
		box,
		lipgloss.WithWhitespaceBackground(lipgloss.Color("#000000")),
	)
}

// ══════════════════════════════════════════════════════════════════
//                         HELPERS
// ══════════════════════════════════════════════════════════════════

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ══════════════════════════════════════════════════════════════════
//                         MAIN
// ══════════════════════════════════════════════════════════════════

func main() {
	p := tea.NewProgram(
		newModel(),
		tea.WithAltScreen(),
		tea.WithMouseAllMotion(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}