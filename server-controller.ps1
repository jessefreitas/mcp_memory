# MCP Memory Server - Controlador Inteligente
# Evita reinicializações desnecessárias e gerencia o servidor de forma eficiente

param(
  [Parameter(Position = 0)]
  [ValidateSet("start", "stop", "restart", "status", "cleanup")]
  [string]$Action = "status",
    
  [switch]$Force,
  [switch]$Silent
)

$ErrorActionPreference = "Stop"

# Caminhos e configurações
$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $workingDir "logs\server.pid"
$lockFile = Join-Path $workingDir "logs\server.lock"
$logFile = Join-Path $workingDir "logs\controller.log"

# Criar diretório de logs se não existir
$logsDir = Join-Path $workingDir "logs"
if (-not (Test-Path $logsDir)) {
  New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

function Write-Log {
  param([string]$Message, [string]$Level = "INFO")
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $logEntry = "[$timestamp] [$Level] $Message"
    
  if (-not $Silent) {
    $color = switch ($Level) {
      "ERROR" { "Red" }
      "WARN" { "Yellow" }
      "SUCCESS" { "Green" }
      "INFO" { "Cyan" }
      default { "White" }
    }
    Write-Host $logEntry -ForegroundColor $color
  }
    
  $logEntry | Add-Content -Path $logFile -Encoding UTF8
}

function Test-ServerLock {
  if (Test-Path $lockFile) {
    $lockContent = Get-Content $lockFile -ErrorAction SilentlyContinue
    if ($lockContent) {
      $lockData = $lockContent | ConvertFrom-Json -ErrorAction SilentlyContinue
      if ($lockData -and $lockData.timestamp) {
        $lockTime = [DateTime]::Parse($lockData.timestamp)
        $timeDiff = (Get-Date) - $lockTime
                
        # Se o lock tem menos de 5 minutos, considerar válido
        if ($timeDiff.TotalMinutes -lt 5) {
          return $true
        }
      }
    }
  }
  return $false
}

function Set-ServerLock {
  $lockData = @{
    pid       = $PID
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    action    = $Action
  }
  $lockData | ConvertTo-Json | Set-Content -Path $lockFile -Encoding UTF8
}

function Remove-ServerLock {
  if (Test-Path $lockFile) {
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
  }
}

function Get-MCPServerProcess {
  $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
  Where-Object { $_.CommandLine -like "*simple-index.js*" }
  return $processes  
}function Start-MCPServer {
  Write-Log "Verificando se servidor já está rodando..." "INFO"
    
  $existingProcess = Get-MCPServerProcess
  if ($existingProcess -and -not $Force) {
    Write-Log "Servidor já está rodando (PID: $($existingProcess[0].Id))" "WARN"
    return $existingProcess[0]
  }
    
  if (Test-ServerLock -and -not $Force) {
    Write-Log "Servidor está sendo iniciado por outro processo. Aguarde..." "WARN"
    return $null
  }
    
  Set-ServerLock
    
  try {
    Write-Log "Iniciando MCP Memory Server..." "INFO"
        
    # Verificar build
    $buildPath = Join-Path $workingDir "build\simple-index.js"
    if (-not (Test-Path $buildPath)) {
      Write-Log "Build não encontrado, compilando..." "WARN"
      Push-Location $workingDir
      npm run build 2>&1 | Add-Content -Path $logFile
      Pop-Location
    }
        
    # Iniciar servidor
    Push-Location $workingDir
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "node"
    $startInfo.Arguments = "build\simple-index.js"
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    $startInfo.WorkingDirectory = $workingDir
        
    # Configurar variáveis de ambiente
    $memoryFile = Join-Path $workingDir "memory.json"
    $startInfo.EnvironmentVariables.Add("MCP_MEMORY_FILE", $memoryFile)
        
    $process = [System.Diagnostics.Process]::Start($startInfo)
    Pop-Location
        
    if ($process) {
      # Aguardar um pouco para verificar se o processo não falhou imediatamente
      Start-Sleep -Milliseconds 500
            
      if (-not $process.HasExited) {
        $process.Id | Set-Content -Path $pidFile -Encoding UTF8
        Write-Log "Servidor iniciado com sucesso (PID: $($process.Id))" "SUCCESS"
        return $process
      }
      else {
        Write-Log "Servidor falhou ao iniciar" "ERROR"
        return $null
      }
    }
        
  }
  catch {
    Write-Log "Erro ao iniciar servidor: $($_.Exception.Message)" "ERROR"
    return $null
  }
  finally {
    Remove-ServerLock
  }
}

function Stop-MCPServer {
  Write-Log "Parando MCP Memory Server..." "INFO"
    
  $processes = Get-MCPServerProcess
  if (-not $processes) {
    Write-Log "Nenhum servidor encontrado rodando" "WARN"
    return
  }
    
  foreach ($proc in $processes) {
    try {
      Write-Log "Parando processo PID: $($proc.Id)" "INFO"
      $proc.Kill()
      $proc.WaitForExit(5000)  # Aguardar até 5 segundos
      Write-Log "Processo $($proc.Id) parado" "SUCCESS"
    }
    catch {
      Write-Log "Erro ao parar processo $($proc.Id): $($_.Exception.Message)" "ERROR"
    }
  }
    
  # Limpar arquivos de controle
  if (Test-Path $pidFile) {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
  }
  Remove-ServerLock
}

function Get-MCPServerStatus {
  $processes = Get-MCPServerProcess
    
  if (-not $processes) {
    Write-Log "❌ Servidor não está rodando" "ERROR"
    return @{ Running = $false; ProcessCount = 0 }
  }
    
  $mainProcess = $processes[0]
  $uptime = (Get-Date) - $mainProcess.StartTime
    
  Write-Log "✅ Servidor rodando" "SUCCESS"
  Write-Log "   PID: $($mainProcess.Id)" "INFO"
  Write-Log "   Iniciado: $($mainProcess.StartTime.ToString('HH:mm:ss'))" "INFO"
  Write-Log "   Uptime: $([int]$uptime.TotalMinutes)m $([int]$uptime.Seconds)s" "INFO"
  Write-Log "   CPU: $([math]::Round($mainProcess.CPU, 2))s" "INFO"
  Write-Log "   Memória: $([math]::Round($mainProcess.WorkingSet / 1MB, 1)) MB" "INFO"
    
  if ($processes.Count -gt 1) {
    Write-Log "⚠️  Múltiplos processos detectados ($($processes.Count))" "WARN"
  }
    
  return @{ 
    Running      = $true
    ProcessCount = $processes.Count
    MainPID      = $mainProcess.Id
    Uptime       = $uptime
  }
}

function Invoke-Cleanup {
  Write-Log "Executando limpeza..." "INFO"
    
  # Parar processos duplicados
  $allNodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
  $mcpProcesses = $allNodeProcesses | Where-Object { $_.CommandLine -like "*build/index.js*" }
    
  if ($mcpProcesses.Count -gt 1) {
    Write-Log "Encontrados $($mcpProcesses.Count) processos MCP, mantendo apenas o mais antigo..." "WARN"
        
    $oldestProcess = $mcpProcesses | Sort-Object StartTime | Select-Object -First 1
    $duplicateProcesses = $mcpProcesses | Where-Object { $_.Id -ne $oldestProcess.Id }
        
    foreach ($proc in $duplicateProcesses) {
      Write-Log "Parando processo duplicado PID: $($proc.Id)" "INFO"
      $proc.Kill()
    }
  }
    
  # Limpar arquivos de lock antigos
  Remove-ServerLock
    
  # Parar monitors órfãos
  $monitorProcesses = Get-Process -Name "powershell", "pwsh" -ErrorAction SilentlyContinue | 
  Where-Object { $_.CommandLine -like "*monitor.ps1*" }
    
  foreach ($proc in $monitorProcesses) {
    Write-Log "Parando monitor órfão PID: $($proc.Id)" "INFO"
    $proc.Kill()
  }
    
  Write-Log "Limpeza concluída" "SUCCESS"
}

# Executar ação
switch ($Action.ToLower()) {
  "start" { Start-MCPServer | Out-Null }
  "stop" { Stop-MCPServer }
  "restart" { 
    Stop-MCPServer
    Start-Sleep 2
    Start-MCPServer | Out-Null
  }
  "status" { Get-MCPServerStatus | Out-Null }
  "cleanup" { Invoke-Cleanup }
  default {
    Write-Log "Ação desconhecida: $Action" "ERROR"
    Write-Log "Use: start, stop, restart, status, cleanup" "INFO"
  }
}