
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
