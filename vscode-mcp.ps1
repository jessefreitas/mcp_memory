# MCP Memory Server - Extensão VS Code Simulada
# Integração completa com comandos e status bar

param(
    [Parameter(Position=0)]
    [ValidateSet("init", "start", "stop", "restart", "status", "dashboard", "autostart", "build", "test", "help")]
    [string]$Command = "help",
    
    [string]$Parameters = "",
    [switch]$Silent = $false
)

$ErrorActionPreference = "Stop"

# Configurações
$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $workingDir "logs\mcp-vscode.log"

# Criar pasta de logs se não existir
$logsDir = Join-Path $workingDir "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "INFO" { Write-Host $logEntry -ForegroundColor Green }
            "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
            "ERROR" { Write-Host $logEntry -ForegroundColor Red }
            default { Write-Host $logEntry }
        }
    }
    
    $logEntry | Out-File -FilePath $logFile -Append -Encoding UTF8
}

function Show-StatusBar {
    $process = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*build/index.js*" 
    }
    
    if ($process) {
        $memory = [math]::Round($process.WorkingSet64/1MB, 2)
        Write-Host "🧠 MCP Memory Server: RUNNING (PID: $($process.Id), RAM: ${memory}MB)" -ForegroundColor Green
        
        # Verificar dashboard XAMPP
        $apacheProcess = Get-Process -Name "httpd" -ErrorAction SilentlyContinue
        if ($apacheProcess) {
            $xamppDashboard = "C:\xampp\htdocs\mcp-dashboard.html"
            if (Test-Path $xamppDashboard) {
                Write-Host "📊 Dashboard: AVAILABLE (http://localhost/mcp-dashboard.html)" -ForegroundColor Cyan
            } else {
                Write-Host "📊 Dashboard: XAMPP running, use .\setup-xampp.ps1 to install" -ForegroundColor Yellow
            }
        } else {
            Write-Host "📊 Dashboard: Apache not running (XAMPP)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "🧠 MCP Memory Server: STOPPED" -ForegroundColor Red
    }
}

function Start-MCPServer {
    Write-Log "Starting MCP Memory Server from VS Code..."
    
    # Build se necessário
    if (-not (Test-Path "build\index.js")) {
        Write-Log "Building project..." "WARN"
        & npm run build
    }
    
    # Verificar se já está rodando
    $existing = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*build/index.js*" 
    }
    
    if ($existing) {
        Write-Log "Server already running (PID: $($existing.Id))" "WARN"
        return
    }
    
    # Iniciar servidor
    Start-Process -FilePath "node" -ArgumentList @("build/index.js") -NoNewWindow -WorkingDirectory $workingDir
    Start-Sleep -Seconds 2
    
    Show-StatusBar
    Write-Log "MCP Memory Server started successfully"
    
    # Mostrar notificação VS Code simulada
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────┐" -ForegroundColor Blue
    Write-Host "│  🧠 MCP Memory Server Started          │" -ForegroundColor Blue  
    Write-Host "│  Ready for AI conversations            │" -ForegroundColor Blue
    Write-Host "│  Use Ctrl+Shift+P > MCP Memory         │" -ForegroundColor Blue
    Write-Host "└─────────────────────────────────────────┘" -ForegroundColor Blue
    Write-Host ""
}

function Stop-MCPServer {
    Write-Log "Stopping MCP Memory Server..."
    
    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*build/index.js*" -or $_.CommandLine -like "*dashboard-server.js*"
    }
    
    if ($processes) {
        foreach ($proc in $processes) {
            Write-Log "Stopping process PID: $($proc.Id)"
            Stop-Process -Id $proc.Id -Force
        }
        Write-Log "MCP Memory Server stopped"
    } else {
        Write-Log "No MCP processes found" "WARN"
    }
    
    Show-StatusBar
}

function Restart-MCPServer {
    Write-Log "Restarting MCP Memory Server..."
    Stop-MCPServer
    Start-Sleep -Seconds 2
    Start-MCPServer
}

function Start-Dashboard {
    Write-Log "Opening MCP Dashboard via XAMPP..."
    
    # Verificar se Apache está rodando
    $apacheProcess = Get-Process -Name "httpd" -ErrorAction SilentlyContinue
    if (-not $apacheProcess) {
        Write-Log "Apache not running. Trying to setup XAMPP dashboard..." "WARN"
        
        # Tentar configurar dashboard no XAMPP
        $setupScript = Join-Path $workingDir "setup-xampp.ps1"
        if (Test-Path $setupScript) {
            & $setupScript
        } else {
            Write-Log "XAMPP setup script not found. Please install XAMPP or use: npm run dashboard" "ERROR"
            return
        }
    }
    
    # Verificar se arquivo dashboard existe no XAMPP
    $xamppDashboard = "C:\xampp\htdocs\mcp-dashboard.html"
    if (-not (Test-Path $xamppDashboard)) {
        Write-Log "Setting up dashboard in XAMPP..." "INFO"
        $setupScript = Join-Path $workingDir "setup-xampp.ps1"
        if (Test-Path $setupScript) {
            & $setupScript
        }
    }
    
    $dashboardUrl = "http://localhost/mcp-dashboard.html"
    Write-Log "Opening dashboard at $dashboardUrl"
    
    # Tentar abrir no navegador
    try {
        Start-Process $dashboardUrl
    } catch {
        Write-Log "Could not open browser. Please visit: $dashboardUrl" "WARN"
    }
    
    # Mostrar informações
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  📊 Dashboard Available via XAMPP      │" -ForegroundColor Cyan
    Write-Host "│  http://localhost/mcp-dashboard.html    │" -ForegroundColor Cyan  
    Write-Host "│  Use Ctrl+Shift+M > H to open          │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────┘" -ForegroundColor Cyan
    Write-Host ""
}

function Show-CommandPalette {
    Write-Host ""
    Write-Host "🎛️  MCP Memory Server - Command Palette" -ForegroundColor Magenta
    Write-Host "═══════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "📋 Available Commands:" -ForegroundColor Blue
    Write-Host "  🚀 mcp.memory.start              - Start MCP Memory Server" -ForegroundColor Green
    Write-Host "  ⏹️  mcp.memory.stop               - Stop MCP Memory Server" -ForegroundColor Red
    Write-Host "  🔄 mcp.memory.restart            - Restart MCP Memory Server" -ForegroundColor Yellow
    Write-Host "  📊 mcp.memory.status             - Show Server Status" -ForegroundColor Cyan
    Write-Host "  📈 mcp.memory.dashboard.open     - Open Dashboard (XAMPP)" -ForegroundColor Cyan
    Write-Host "  📊 mcp.memory.dashboard.start    - Setup Dashboard in XAMPP" -ForegroundColor Cyan
    Write-Host "  ⚙️  mcp.memory.autostart.enable   - Enable Windows AutoStart" -ForegroundColor Blue
    Write-Host "  ❌ mcp.memory.autostart.disable  - Disable Windows AutoStart" -ForegroundColor Red
    Write-Host "  🛠️  mcp.memory.autostart.configure - Configure AutoStart GUI" -ForegroundColor Blue
    Write-Host "  🔨 mcp.memory.build              - Build Project" -ForegroundColor Yellow
    Write-Host "  🧹 mcp.memory.clean              - Clean Build" -ForegroundColor Yellow
    Write-Host "  🧪 mcp.memory.test               - Test Memory Operations" -ForegroundColor Green
    Write-Host ""
    Write-Host "⌨️  Keyboard Shortcuts:" -ForegroundColor Blue
    Write-Host "  Ctrl+Shift+M > S  - Start Server" -ForegroundColor Green
    Write-Host "  Ctrl+Shift+M > B  - Build Project" -ForegroundColor Yellow
    Write-Host "  Ctrl+Shift+M > H  - Open Dashboard (XAMPP)" -ForegroundColor Cyan
    Write-Host "  Ctrl+Shift+M > A  - Enable AutoStart" -ForegroundColor Blue
    Write-Host "  Ctrl+Shift+M > G  - AutoStart GUI" -ForegroundColor Blue
    Write-Host ""
}

function Initialize-VSCodeIntegration {
    Write-Log "Initializing VS Code MCP Integration..." "INFO"
    
    # Verificar dependências
    try {
        $nodeVersion = & node --version
        Write-Log "Node.js version: $nodeVersion"
    } catch {
        Write-Log "Node.js not found! Please install Node.js" "ERROR"
        return
    }
    
    # Verificar projeto
    if (-not (Test-Path "package.json")) {
        Write-Log "Not in MCP Memory project directory" "ERROR"
        return
    }
    
    # Build se necessário
    if (-not (Test-Path "build")) {
        Write-Log "Building project for first time..."
        & npm run build
    }
    
    # Mostrar status
    Show-StatusBar
    
    Write-Host ""
    Write-Host "✅ VS Code MCP Integration Ready!" -ForegroundColor Green
    Write-Host "   Use: .\vscode-mcp.ps1 help for commands" -ForegroundColor Cyan
    Write-Host ""
}

# Menu principal
switch ($Command.ToLower()) {
    "init" { Initialize-VSCodeIntegration }
    "start" { Start-MCPServer }
    "stop" { Stop-MCPServer }
    "restart" { Restart-MCPServer }
    "status" { Show-StatusBar }
    "dashboard" { Start-Dashboard }
    "autostart" { 
        if ($Args -eq "enable") {
            & ".\auto-start.ps1" startup -Dashboard
        } elseif ($Args -eq "disable") {
            & ".\auto-start.ps1" remove
        } elseif ($Args -eq "gui") {
            & ".\setup-windows.ps1"
        } else {
            & ".\auto-start.ps1" status
        }
    }
    "build" { & npm run build }
    "test" { & npm run server:memory }
    "help" { Show-CommandPalette }
    default { Show-CommandPalette }
}