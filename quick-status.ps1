# MCP Memory Server - Verificação Rápida de Status
# Use: .\quick-status.ps1

param(
  [switch]$Detailed,
  [switch]$JSON
)

$ErrorActionPreference = "SilentlyContinue"

function Get-MCPStatus {
  $workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
  Where-Object { $_.CommandLine -like "*build/index.js*" }
    
  $dbPath = Join-Path $workingDir "memory.db"
  $dbSize = if (Test-Path $dbPath) { 
    [math]::Round((Get-Item $dbPath).Length / 1KB, 2) 
  }
  else { 0 }
    
  $buildPath = Join-Path $workingDir "build\index.js"
    
  $status = @{
    Running             = $processes.Count -gt 0
    ProcessCount        = $processes.Count
    PIDs                = if ($processes) { $processes.Id } else { @() }
    DatabaseSize        = "$dbSize KB"
    LastModified        = if (Test-Path $dbPath) { 
      (Get-Item $dbPath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") 
    }
    else { "N/A" }
    BuildExists         = Test-Path $buildPath
    ConfiguredAutoStart = @{
      Startup       = Test-Path (Join-Path ([Environment]::GetFolderPath("Startup")) "MCP-Memory-Server.bat")
      ScheduledTask = $null -ne (Get-ScheduledTask -TaskName "MCP Memory Server" -ErrorAction SilentlyContinue)
    }
    Timestamp           = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  }
    
  return $status
}

$status = Get-MCPStatus

if ($JSON) {
  $status | ConvertTo-Json -Depth 3
  exit 0
}

# Output colorido
Write-Host ""
Write-Host "🧠 MCP Memory Server - Status Check" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Status principal
$statusColor = if ($status.Running) { "Green" } else { "Red" }
$statusText = if ($status.Running) { "✅ RODANDO" } else { "❌ PARADO" }
Write-Host "Status: $statusText" -ForegroundColor $statusColor

if ($status.Running) {
  Write-Host "PIDs: $($status.PIDs -join ', ')" -ForegroundColor Green
  Write-Host "Processos: $($status.ProcessCount)" -ForegroundColor Green
}
else {
  Write-Host "Nenhum processo ativo encontrado" -ForegroundColor Yellow
}

Write-Host ""

# Informações do banco
Write-Host "📊 Database:" -ForegroundColor Blue
Write-Host "   Tamanho: $($status.DatabaseSize)" -ForegroundColor White
Write-Host "   Última modificação: $($status.LastModified)" -ForegroundColor White

Write-Host ""

# Build status
$buildColor = if ($status.BuildExists) { "Green" } else { "Red" }
$buildText = if ($status.BuildExists) { "✅ OK" } else { "❌ Não encontrado" }
Write-Host "🔨 Build: $buildText" -ForegroundColor $buildColor

Write-Host ""

# Auto-start configuration
Write-Host "🚀 Inicialização Automática:" -ForegroundColor Blue
$startupColor = if ($status.ConfiguredAutoStart.Startup) { "Green" } else { "Red" }
$startupText = if ($status.ConfiguredAutoStart.Startup) { "✅ Configurado" } else { "❌ Não configurado" }
Write-Host "   Pasta Startup: $startupText" -ForegroundColor $startupColor

$taskColor = if ($status.ConfiguredAutoStart.ScheduledTask) { "Green" } else { "Red" }
$taskText = if ($status.ConfiguredAutoStart.ScheduledTask) { "✅ Configurado" } else { "❌ Não configurado" }
Write-Host "   Tarefa Agendada: $taskText" -ForegroundColor $taskColor

if ($Detailed) {
  Write-Host ""
  Write-Host "🔍 Informações Detalhadas:" -ForegroundColor Blue
    
  if ($status.Running) {
    $processes = Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*build/index.js*" }
    foreach ($proc in $processes) {
      Write-Host "   PID $($proc.Id):" -ForegroundColor Yellow
      Write-Host "     CPU: $([math]::Round($proc.CPU, 2))s" -ForegroundColor White
      Write-Host "     Memória: $([math]::Round($proc.WorkingSet / 1MB, 2)) MB" -ForegroundColor White
      Write-Host "     Iniciado: $($proc.StartTime)" -ForegroundColor White
    }
  }
    
  # Verificar logs recentes
  $logPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "logs\mcp-vscode.log"
  if (Test-Path $logPath) {
    Write-Host ""
    Write-Host "📋 Últimas 3 entradas do log:" -ForegroundColor Blue
    Get-Content $logPath -Tail 3 | ForEach-Object {
      Write-Host "   $_" -ForegroundColor Gray
    }
  }
}

Write-Host ""
Write-Host "Verificação realizada em: $($status.Timestamp)" -ForegroundColor Gray

# Sugestões baseadas no status
Write-Host ""
Write-Host "💡 Sugestões:" -ForegroundColor Yellow

if (-not $status.Running) {
  Write-Host "   • Execute: .\mcp-server.ps1 start" -ForegroundColor White
  if (-not $status.BuildExists) {
    Write-Host "   • Execute primeiro: npm run build" -ForegroundColor White
  }
}

if (-not $status.ConfiguredAutoStart.Startup -and -not $status.ConfiguredAutoStart.ScheduledTask) {
  Write-Host "   • Configure auto-start: .\auto-start.ps1 task" -ForegroundColor White
}

if ($status.Running) {
  Write-Host "   • Monitor contínuo: .\monitor.ps1 -Dashboard" -ForegroundColor White
  Write-Host "   • Dashboard visual: .\status-monitor.html" -ForegroundColor White
}

Write-Host ""