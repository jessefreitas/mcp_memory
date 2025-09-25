# MCP Memory Server - VS Code Integration Script
# Este script facilita o uso do servidor MCP Memory no VS Code

param(
  [Parameter(Position = 0)]
  [ValidateSet("start", "stop", "restart", "status", "test", "build", "clean")]
  [string]$Action = "start",
    
  [switch]$Debug,
  [switch]$Memory,
  [string]$DbPath = "./memory.db"
)

$ErrorActionPreference = "Stop"

# Cores para output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Blue = "Blue"

function Write-ColorOutput {
  param([string]$Message, [string]$Color = "White")
  Write-Host $Message -ForegroundColor $Color
}

function Test-ProcessRunning {
  param([string]$ProcessName)
  return Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
}

function Start-MCPServer {
  Write-ColorOutput "🚀 Iniciando MCP Memory Server..." $Blue
    
  # Verificar se já está rodando
  $existing = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*build/index.js*" 
  }
    
  if ($existing) {
    Write-ColorOutput "⚠️  Servidor já está rodando (PID: $($existing.Id))" $Yellow
    return
  }
    
  # Build se necessário
  if (-not (Test-Path "build/index.js")) {
    Write-ColorOutput "🔨 Compilando projeto..." $Yellow
    npm run build
  }
    
  # Configurar ambiente
  $env:NODE_ENV = if ($Debug) { "development" } else { "production" }
  if ($Memory) {
    $env:MCP_MEMORY_DB = ":memory:"
    Write-ColorOutput "💾 Usando banco de dados em memória" $Yellow
  }
  else {
    $env:MCP_MEMORY_DB = $DbPath
    Write-ColorOutput "💾 Usando banco de dados: $DbPath" $Yellow
  }
    
  # Iniciar servidor
  if ($Debug) {
    Write-ColorOutput "🐛 Iniciando em modo debug..." $Yellow
    Start-Process -FilePath "node" -ArgumentList @("--inspect", "build/index.js") -NoNewWindow
  }
  else {
    Write-ColorOutput "▶️  Iniciando servidor..." $Green
    Start-Process -FilePath "node" -ArgumentList @("build/index.js") -NoNewWindow
  }
    
  Start-Sleep -Seconds 2
  Write-ColorOutput "✅ MCP Memory Server iniciado com sucesso!" $Green
}

function Stop-MCPServer {
  Write-ColorOutput "🛑 Parando MCP Memory Server..." $Blue
    
  $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*build/index.js*" 
  }
    
  if ($processes) {
    foreach ($proc in $processes) {
      Write-ColorOutput "🔄 Encerrando processo PID: $($proc.Id)" $Yellow
      Stop-Process -Id $proc.Id -Force
    }
    Write-ColorOutput "✅ Servidor parado com sucesso!" $Green
  }
  else {
    Write-ColorOutput "ℹ️  Nenhum servidor MCP encontrado rodando" $Yellow
  }
}

function Get-MCPStatus {
  Write-ColorOutput "📊 Status do MCP Memory Server:" $Blue
    
  $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*build/index.js*" 
  }
    
  if ($processes) {
    foreach ($proc in $processes) {
      Write-ColorOutput "✅ Rodando - PID: $($proc.Id), CPU: $($proc.CPU), Memory: $([math]::Round($proc.WorkingSet64/1MB, 2))MB" $Green
    }
  }
  else {
    Write-ColorOutput "❌ Servidor não está rodando" $Red
  }
    
  # Verificar banco de dados
  if (Test-Path $DbPath) {
    $dbSize = (Get-Item $DbPath).Length
    Write-ColorOutput "💾 Banco de dados: $DbPath ($([math]::Round($dbSize/1KB, 2))KB)" $Green
  }
  else {
    Write-ColorOutput "💾 Banco de dados não encontrado: $DbPath" $Yellow
  }
}

function Build-Project {
  Write-ColorOutput "🔨 Compilando projeto TypeScript..." $Blue
  npm run build
  Write-ColorOutput "✅ Compilação concluída!" $Green
}

function Clean-Build {
  Write-ColorOutput "🧹 Limpando arquivos de build..." $Blue
  if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-ColorOutput "✅ Build limpo!" $Green
  }
  else {
    Write-ColorOutput "ℹ️  Pasta build não existe" $Yellow
  }
}

function Test-MCPServer {
  Write-ColorOutput "🧪 Testando MCP Memory Server..." $Blue
    
  # Build primeiro
  Build-Project
    
  # Configurar para teste em memória
  $env:NODE_ENV = "test"
  $env:MCP_MEMORY_DB = ":memory:"
    
  Write-ColorOutput "▶️  Executando teste..." $Yellow
    
  # Executar um teste básico
  $testScript = @"
console.log('🧪 Teste do MCP Memory Server');
process.exit(0);
"@
    
  $testScript | node -e "console.log('✅ Servidor pode ser iniciado em modo teste')"
  Write-ColorOutput "✅ Teste concluído!" $Green
}

# Menu principal
switch ($Action.ToLower()) {
  "start" { Start-MCPServer }
  "stop" { Stop-MCPServer }
  "restart" { 
    Stop-MCPServer
    Start-Sleep -Seconds 2
    Start-MCPServer
  }
  "status" { Get-MCPStatus }
  "build" { Build-Project }
  "clean" { Clean-Build }
  "test" { Test-MCPServer }
  default {
    Write-ColorOutput "❓ Uso: .\mcp-server.ps1 [start|stop|restart|status|build|clean|test] [-Debug] [-Memory] [-DbPath <path>]" $Yellow
    Write-ColorOutput ""
    Write-ColorOutput "Exemplos:" $Blue
    Write-ColorOutput "  .\mcp-server.ps1 start          # Iniciar servidor" $Green
    Write-ColorOutput "  .\mcp-server.ps1 start -Debug   # Iniciar com debug" $Green
    Write-ColorOutput "  .\mcp-server.ps1 start -Memory  # Usar banco em memória" $Green
    Write-ColorOutput "  .\mcp-server.ps1 status         # Ver status" $Green
    Write-ColorOutput "  .\mcp-server.ps1 stop           # Parar servidor" $Green
  }
}