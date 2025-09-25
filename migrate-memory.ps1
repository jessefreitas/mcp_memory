# MCP Memory Migration - Migrar dados do servidor oficial para nosso servidor customizado

param(
  [switch]$DryRun,
  [switch]$Backup
)

$ErrorActionPreference = "Stop"

# Caminhos
$officialMemoryPath = "C:\mcp\memory.json"
$customServerPath = "C:\vscode\mcp_memory"

function Write-ColorOutput {
  param([string]$Message, [string]$Color = "White")
  Write-Host $Message -ForegroundColor $Color
}

function Test-CustomServerRunning {
  $processes = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
  Where-Object { $_.CommandLine -like "*build/index.js*" }
  return $processes.Count -gt 0
}

Write-ColorOutput "🔄 MCP Memory Migration Tool" "Cyan"
Write-ColorOutput "=============================" "Cyan"
Write-ColorOutput ""

# Verificar servidor customizado
if (-not (Test-CustomServerRunning)) {
  Write-ColorOutput "❌ Servidor customizado não está rodando!" "Red"
  Write-ColorOutput "   Execute: .\mcp-server.ps1 start" "Yellow"
  exit 1
}

Write-ColorOutput "✅ Servidor customizado detectado" "Green"

# Verificar dados do servidor oficial
if (-not (Test-Path $officialMemoryPath)) {
  Write-ColorOutput "❌ Arquivo de memória oficial não encontrado: $officialMemoryPath" "Red"
  exit 1
}

Write-ColorOutput "✅ Dados do servidor oficial encontrados" "Green"

# Carregar dados
$officialData = Get-Content $officialMemoryPath | ConvertFrom-Json

Write-ColorOutput ""
Write-ColorOutput "📊 Dados a serem migrados:" "Blue"
Write-ColorOutput "   Entidade: $($officialData.name)" "White"
Write-ColorOutput "   Tipo: $($officialData.entityType)" "White"
Write-ColorOutput "   Observações: $($officialData.observations.Count)" "White"

if ($DryRun) {
  Write-ColorOutput ""
  Write-ColorOutput "🔍 Modo DRY RUN - Nenhuma alteração será feita" "Yellow"
  Write-ColorOutput ""
  Write-ColorOutput "Comando que seria executado:" "Blue"
  Write-ColorOutput "   mcp_memory_create_entities com dados:" "White"
    
  $entityData = @{
    name         = $officialData.name
    entityType   = $officialData.entityType
    observations = $officialData.observations
  }
    
  Write-ColorOutput ($entityData | ConvertTo-Json -Depth 3) "Gray"
  exit 0
}

# Backup por padrão (a menos que explicitamente desabilitado)
if (-not $PSBoundParameters.ContainsKey('Backup') -or $Backup) {
  $backupPath = Join-Path $customServerPath "backup-official-memory-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
  Copy-Item $officialMemoryPath $backupPath
  Write-ColorOutput "💾 Backup criado: $backupPath" "Green"
}

Write-ColorOutput ""
Write-ColorOutput "🚀 Iniciando migração..." "Blue"

try {
  # Aqui seria onde faríamos a migração real
  # Como não podemos executar comandos MCP diretamente via PowerShell,
  # vamos criar um arquivo de instruções
    
  $migrationScript = @"
# Instruções para migração MCP Memory
# Execute estes comandos no Claude Desktop:

1. Certifique-se que está usando o servidor customizado em claude_desktop_config.json:
{
  "mcpServers": {
    "memory-server": {
      "command": "node",
      "args": ["C:\\vscode\\mcp_memory\\build\\index.js"],
      "env": {}
    }
  }
}

2. Execute o comando para criar a entidade:

mcp_memory_create_entities com os dados:
{
  "entities": [
    {
      "name": "$($officialData.name)",
      "entityType": "$($officialData.entityType)",
      "observations": [
        $(($officialData.observations | ForEach-Object { """$_""" }) -join ",`n        ")
      ]
    }
  ]
}

3. Verificar se a migração funcionou:
mcp_memory_read_graph

Data da migração: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

  $instructionsPath = Join-Path $customServerPath "migration-instructions.txt"
  $migrationScript | Out-File -FilePath $instructionsPath -Encoding UTF8
    
  Write-ColorOutput "📋 Instruções de migração criadas: $instructionsPath" "Green"
  Write-ColorOutput ""
  Write-ColorOutput "⚠️  ATENÇÃO: A migração deve ser feita via Claude Desktop" "Yellow"
  Write-ColorOutput "   1. Abra Claude Desktop" "White"
  Write-ColorOutput "   2. Configure para usar nosso servidor customizado" "White"
  Write-ColorOutput "   3. Execute os comandos das instruções criadas" "White"
    
}
catch {
  Write-ColorOutput "❌ Erro durante a migração: $($_.Exception.Message)" "Red"
  exit 1
}

Write-ColorOutput ""
Write-ColorOutput "✅ Processo de migração preparado!" "Green"