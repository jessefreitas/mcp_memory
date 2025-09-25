# MCP Memory Server - Monitor Contínuo
# Verifica se o servidor está rodando e reinicia se necessário

param(
  [int]$CheckInterval = 30,  # Segundos entre verificações
  [switch]$NotifyOnly,
  [switch]$AutoRestart,
  [switch]$Dashboard
)

$ErrorActionPreference = "SilentlyContinue"

# Caminhos
$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $workingDir "logs\monitor.log"
$pidFile = Join-Path $workingDir "logs\server.pid"

# Criar diretório de logs se não existir
$logsDir = Join-Path $workingDir "logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logMessage = "[$timestamp] [$Level] $Message"
    
  Write-Host $logMessage -ForegroundColor $(
    switch ($Level) {
      "ERROR" { "Red" }
      "WARN" { "Yellow" }
      "SUCCESS" { "Green" }
      default { "White" }
    }
  )
    
  $logMessage | Add-Content -Path $logFile -Encoding UTF8
}

function Test-MCPServer {
  # Verificar processo Node.js com build/index.js
  $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
  Where-Object { $_.CommandLine -like "*build/index.js*" }
    
  if ($processes) {
    return @{
      Running = $true
      PID     = $processes[0].Id
      Count   = $processes.Count
    }
  }
    
  return @{
    Running = $false
    PID     = $null
    Count   = 0
  }
}

function Start-MCPServer {
  Write-Log "Iniciando MCP Memory Server..." "INFO"
    
  # Verificar se precisa compilar
  $buildPath = Join-Path $workingDir "build\index.js"
  if (-not (Test-Path $buildPath)) {
    Write-Log "Build não encontrado, compilando..." "WARN"
    Push-Location $workingDir
    npm run build 2>&1 | Add-Content -Path $logFile
    Pop-Location
  }
    
  # Iniciar servidor
  Push-Location $workingDir
  $process = Start-Process -FilePath "node" -ArgumentList "build\index.js" -WindowStyle Hidden -PassThru
  Pop-Location
    
  if ($process) {
    $process.Id | Set-Content -Path $pidFile
    Write-Log "Servidor iniciado com PID: $($process.Id)" "SUCCESS"
        
    # Iniciar dashboard se solicitado
    if ($Dashboard) {
      Start-Sleep 2
      Start-Process -FilePath "node" -ArgumentList "dashboard-server.js" -WindowStyle Hidden
      Write-Log "Dashboard iniciado" "SUCCESS"
    }
        
    return $true
  }
    
  Write-Log "Falha ao iniciar servidor" "ERROR"
  return $false
}

function Send-Notification {
  param([string]$Title, [string]$Message, [string]$Type = "Info")
    
  # Toast notification (Windows 10+)
  try {
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.BalloonTipTitle = $Title
    $notify.BalloonTipText = $Message
    $notify.Visible = $true
    $notify.ShowBalloonTip(3000)
    $notify.Dispose()
  }
  catch {
    Write-Log "Notificação: $Title - $Message" "INFO"
  }
}

# Configurar padrões
if (-not $NotifyOnly -and -not $PSBoundParameters.ContainsKey('AutoRestart')) {
  $AutoRestart = $true
}

# Loop principal de monitoramento
Write-Log "Iniciando monitor do MCP Memory Server" "INFO"
Write-Log "Intervalo de verificação: $CheckInterval segundos" "INFO"
Write-Log "Auto-restart: $AutoRestart" "INFO"
Write-Log "Dashboard: $Dashboard" "INFO"
Write-Log "Pressione Ctrl+C para parar o monitor" "INFO"

$consecutiveFailures = 0
$maxFailures = 3

try {
  while ($true) {
    $status = Test-MCPServer
        
    if ($status.Running) {
      if ($consecutiveFailures -gt 0) {
        Write-Log "Servidor recuperado após $consecutiveFailures falhas" "SUCCESS"
        Send-Notification "MCP Memory" "Servidor recuperado" "Info"
        $consecutiveFailures = 0
      }
            
      Write-Log "Servidor rodando (PID: $($status.PID), Processos: $($status.Count))" "INFO"
    }
    else {
      $consecutiveFailures++
      Write-Log "Servidor não está rodando (Falha $consecutiveFailures/$maxFailures)" "WARN"
            
      if ($AutoRestart) {
        if ($consecutiveFailures -le $maxFailures) {
          Write-Log "Tentando reiniciar servidor..." "WARN"
          Send-Notification "MCP Memory" "Reiniciando servidor..." "Warning"
                    
          if (Start-MCPServer) {
            $consecutiveFailures = 0
            Send-Notification "MCP Memory" "Servidor reiniciado com sucesso" "Info"
          }
        }
        else {
          Write-Log "Muitas falhas consecutivas, parando tentativas" "ERROR"
          Send-Notification "MCP Memory" "Servidor falhou $maxFailures vezes" "Error"
          break
        }
      }
      elseif ($NotifyOnly) {
        Send-Notification "MCP Memory" "Servidor não está rodando" "Warning"
      }
    }
        
    Start-Sleep $CheckInterval
  }
}
catch {
  Write-Log "Monitor interrompido pelo usuário" "INFO"
}
finally {
  Write-Log "Monitor do MCP Memory Server finalizado" "INFO"
}