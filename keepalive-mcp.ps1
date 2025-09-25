# =====================================================
# MCP Memory Server - Keep Alive Script
# Garante que o servidor SEMPRE esteja rodando
# =====================================================

param(
    [switch]$Install,
    [switch]$Stop,
    [switch]$Status
)

$projectPath = "c:\vscode\mcp_memory"
$taskName = "MCP-Memory-KeepAlive"
$logFile = "$projectPath\logs\keepalive.log"

function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    
    # Garantir que o diretório de logs existe
    $logDir = Split-Path $logFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Add-Content -Path $logFile -Value $logEntry
}

function Test-MCPRunning {
    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.CommandLine -like "*simple-index.js*" }
    return $processes.Count -gt 0
}

function Start-MCPServer {
    Set-Location $projectPath
    
    Write-Log "🚀 Iniciando servidor MCP..." "START"
    
    # Garantir que o build existe
    if (-not (Test-Path "build\simple-index.js")) {
        Write-Log "📦 Build não encontrado, executando npm run build..." "BUILD"
        npm run build | Out-Null
    }
    
    # Iniciar servidor em background
    $process = Start-Process -FilePath "node" -ArgumentList "build\simple-index.js" -WindowStyle Hidden -PassThru
    Write-Log "✅ Servidor iniciado com PID: $($process.Id)" "SUCCESS"
    
    return $process
}

function Install-KeepAliveTask {
    Write-Log "⚙️ Instalando tarefa de Keep Alive..." "INSTALL"
    
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 2)
    
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($trigger, $trigger2) -Settings $settings -Principal $principal -Force
    
    Write-Log "✅ Tarefa agendada instalada: $taskName" "SUCCESS"
    Write-Log "   • Executa na inicialização do sistema" "INFO"
    Write-Log "   • Verifica a cada 2 minutos se o servidor está rodando" "INFO"
}

function Remove-KeepAliveTask {
    Write-Log "🗑️ Removendo tarefa de Keep Alive..." "REMOVE"
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log "✅ Tarefa removida" "SUCCESS"
}

function Show-Status {
    Write-Host "=" * 50 -ForegroundColor Cyan
    Write-Host "MCP KEEP ALIVE - STATUS" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    # Status do servidor
    if (Test-MCPRunning) {
        Write-Host "🟢 Servidor MCP: RODANDO" -ForegroundColor Green
        $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
                     Where-Object { $_.CommandLine -like "*simple-index.js*" }
        foreach ($proc in $processes) {
            Write-Host "   PID: $($proc.Id) | CPU: $([math]::Round($proc.CPU, 2))s | Mem: $([math]::Round($proc.WorkingSet64/1MB, 1))MB" -ForegroundColor Gray
        }
    } else {
        Write-Host "🔴 Servidor MCP: PARADO" -ForegroundColor Red
    }
    
    # Status da tarefa agendada
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "🟢 Keep Alive Task: INSTALADA" -ForegroundColor Green
        Write-Host "   Estado: $($task.State)" -ForegroundColor Gray
        Write-Host "   Última execução: $($task.LastRunTime)" -ForegroundColor Gray
    } else {
        Write-Host "🔴 Keep Alive Task: NÃO INSTALADA" -ForegroundColor Red
    }
    
    # Log recente
    if (Test-Path $logFile) {
        Write-Host "`n📋 Últimas 5 entradas do log:" -ForegroundColor Yellow
        Get-Content $logFile -Tail 5 | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
    }
}

# =====================================================
# MAIN EXECUTION
# =====================================================

if ($Install) {
    Install-KeepAliveTask
    
    # Também garantir que o servidor esteja rodando agora
    if (-not (Test-MCPRunning)) {
        Start-MCPServer
    }
    
    Write-Log "🎯 MCP configurado para SEMPRE estar ativo!" "SUCCESS"
    exit 0
}

if ($Stop) {
    Remove-KeepAliveTask
    
    # Parar processos MCP
    $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
                 Where-Object { $_.CommandLine -like "*simple-index.js*" }
    foreach ($proc in $processes) {
        Write-Log "🛑 Parando processo MCP PID: $($proc.Id)" "STOP"
        $proc.Kill()
    }
    
    exit 0
}

if ($Status) {
    Show-Status
    exit 0
}

# =====================================================
# KEEP ALIVE LOOP (modo padrão)
# =====================================================

Write-Log "🔄 Iniciando verificação Keep Alive..." "START"

if (-not (Test-MCPRunning)) {
    Write-Log "⚠️ Servidor MCP não está rodando!" "WARN"
    Start-MCPServer
} else {
    Write-Log "✅ Servidor MCP está rodando normalmente" "SUCCESS"
}

Write-Log "🔄 Verificação Keep Alive concluída" "END"