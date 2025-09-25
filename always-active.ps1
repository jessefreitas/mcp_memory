# =====================================================
# MCP ALWAYS ACTIVE - Versão Simples
# Garante que o MCP SEMPRE esteja rodando
# =====================================================

param(
    [switch]$Install,
    [switch]$Status,
    [switch]$Start
)

$projectPath = "c:\vscode\mcp_memory"
$startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$keepAliveScript = "$startupPath\MCP-Monitor.bat"

function Test-MCPRunning {
    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.CommandLine -like "*simple-index.js*" }
    return $processes.Count -gt 0
}

function Start-MCPIfNeeded {
    if (-not (Test-MCPRunning)) {
        Write-Host "🚀 Iniciando MCP Server..." -ForegroundColor Yellow
        Set-Location $projectPath
        
        # Build se necessário
        if (-not (Test-Path "build\simple-index.js")) {
            Write-Host "📦 Executando build..." -ForegroundColor Gray
            npm run build | Out-Null
        }
        
        # Iniciar servidor
        Start-Process -FilePath "node" -ArgumentList "build\simple-index.js" -WindowStyle Hidden
        Start-Sleep 2
        
        if (Test-MCPRunning) {
            Write-Host "✅ MCP Server iniciado com sucesso!" -ForegroundColor Green
        } else {
            Write-Host "❌ Falha ao iniciar MCP Server" -ForegroundColor Red
        }
    } else {
        Write-Host "✅ MCP Server já está rodando" -ForegroundColor Green
    }
}

if ($Install) {
    Write-Host "⚙️ Configurando MCP para SEMPRE estar ativo..." -ForegroundColor Yellow
    
    # Criar script de monitor no startup
    $monitorScript = @"
@echo off
REM MCP Memory Server - Auto Start Monitor
cd /d "$projectPath"
timeout /t 10 /nobreak >nul
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& { Set-Location '$projectPath'; .\always-active.ps1 -Start }"
"@
    
    $monitorScript | Out-File -FilePath $keepAliveScript -Encoding ASCII
    Write-Host "✅ Script de monitor criado em:" -ForegroundColor Green
    Write-Host "   $keepAliveScript" -ForegroundColor Gray
    
    # Criar tarefa em loop para verificar constantemente
    $loopScript = @"
# MCP Monitor Loop - Executa continuamente
while (`$true) {
    try {
        Set-Location '$projectPath'
        .\always-active.ps1 -Start
        Start-Sleep 60  # Verifica a cada 1 minuto
    } catch {
        Start-Sleep 30  # Em caso de erro, espera 30s
    }
}
"@
    
    $loopScript | Out-File -FilePath "$projectPath\mcp-monitor-loop.ps1" -Encoding UTF8
    
    # Iniciar o loop em background
    Start-Process -FilePath "powershell.exe" -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$projectPath\mcp-monitor-loop.ps1`"" -WindowStyle Hidden
    
    Write-Host "🎯 MCP configurado para SEMPRE estar ativo!" -ForegroundColor Green
    Write-Host "   • Inicia automaticamente no Windows" -ForegroundColor Gray
    Write-Host "   • Monitor contínuo em background" -ForegroundColor Gray
    Write-Host "   • Verifica a cada 1 minuto" -ForegroundColor Gray
    
    Start-MCPIfNeeded
    exit 0
}

if ($Status) {
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "MCP ALWAYS ACTIVE - STATUS" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    if (Test-MCPRunning) {
        Write-Host "🟢 MCP Server: RODANDO" -ForegroundColor Green
        $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
                     Where-Object { $_.CommandLine -like "*simple-index.js*" }
        foreach ($proc in $processes) {
            $uptime = (Get-Date) - $proc.StartTime
            Write-Host "   PID: $($proc.Id) | Uptime: $([math]::Round($uptime.TotalMinutes))min | Mem: $([math]::Round($proc.WorkingSet64/1MB, 1))MB" -ForegroundColor Gray
        }
    } else {
        Write-Host "🔴 MCP Server: PARADO" -ForegroundColor Red
    }
    
    # Verificar auto-start
    if (Test-Path $keepAliveScript) {
        Write-Host "🟢 Auto-start: CONFIGURADO" -ForegroundColor Green
    } else {
        Write-Host "🔴 Auto-start: NÃO CONFIGURADO" -ForegroundColor Red
    }
    
    # Verificar monitor loop
    $monitorProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
                      Where-Object { $_.CommandLine -like "*mcp-monitor-loop.ps1*" }
    if ($monitorProcess) {
        Write-Host "🟢 Monitor Loop: ATIVO" -ForegroundColor Green
    } else {
        Write-Host "🔴 Monitor Loop: INATIVO" -ForegroundColor Red
    }
    
    exit 0
}

if ($Start) {
    Start-MCPIfNeeded
    exit 0
}

# Modo padrão - verificar e iniciar se necessário
Start-MCPIfNeeded