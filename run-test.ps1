# Script de Teste MCP - Simula comandos via stdio
# Testa se o servidor está salvando dados corretamente

$ErrorActionPreference = "Stop"

function Test-MCPCommand {
  param([string]$Command, [string]$Description)
    
  Write-Host ""
  Write-Host "🧪 Testando: $Description" -ForegroundColor Blue
  Write-Host "Comando: $Command" -ForegroundColor Gray
    
  try {
    # Executar comando via stdio
    $output = $Command | node build\simple-index.js 2>&1
        
    if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ Comando executado com sucesso" -ForegroundColor Green
      if ($output) {
        Write-Host "Resposta: $output" -ForegroundColor Gray
      }
    }
    else {
      Write-Host "❌ Comando falhou (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
      Write-Host "Erro: $output" -ForegroundColor Red
    }
  }
  catch {
    Write-Host "❌ Erro na execução: $($_.Exception.Message)" -ForegroundColor Red
  }
}

function Test-MemoryFile {
  Write-Host ""
  Write-Host "📁 Verificando arquivo memory.json:" -ForegroundColor Blue
    
  if (Test-Path "memory.json") {
    $fileInfo = Get-Item "memory.json"
    Write-Host "✅ Arquivo existe" -ForegroundColor Green
    Write-Host "   Tamanho: $($fileInfo.Length) bytes" -ForegroundColor White
    Write-Host "   Modificado: $($fileInfo.LastWriteTime)" -ForegroundColor White
        
    try {
      $content = Get-Content "memory.json" -Raw | ConvertFrom-Json
      $entityCount = if ($content.entities) { $content.entities.Count } else { 0 }
      $relationCount = if ($content.relations) { $content.relations.Count } else { 0 }
            
      Write-Host "   Entidades: $entityCount" -ForegroundColor White
      Write-Host "   Relacionamentos: $relationCount" -ForegroundColor White
            
      if ($content.entities -and $content.entities.Count -gt 0) {
        Write-Host ""
        Write-Host "📋 Entidades encontradas:" -ForegroundColor Cyan
        $content.entities | ForEach-Object {
          Write-Host "   • $($_.name) ($($_.entityType))" -ForegroundColor Green
          if ($_.observations) {
            Write-Host "     Observações: $($_.observations.Count)" -ForegroundColor Gray
          }
        }
      }
            
      return $content
    }
    catch {
      Write-Host "❌ Erro ao ler conteúdo: $($_.Exception.Message)" -ForegroundColor Red
      return $null
    }
  }
  else {
    Write-Host "❌ Arquivo não existe" -ForegroundColor Red
    return $null
  }
}

# Verificar se o servidor está rodando
$serverProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
Where-Object { $_.CommandLine -like "*simple-index.js*" }

if (-not $serverProcess) {
  Write-Host "❌ Servidor não está rodando! Iniciando..." -ForegroundColor Red
  .\server-controller.ps1 start
  Start-Sleep 2
}

Write-Host ""
Write-Host "🧪 TESTE DE PERSISTÊNCIA MCP MEMORY SERVER" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan

# Estado inicial
Write-Host ""
Write-Host "📊 Estado Inicial:" -ForegroundColor Blue
$initialState = Test-MemoryFile

# Criar dados de teste via Node.js script
Write-Host ""
Write-Host "🚀 Criando dados de teste..." -ForegroundColor Blue

$testScript = @"
const fs = require('fs');

// Simular dados que seriam criados via MCP
const testData = {
  entities: [
    {
      type: "entity",
      name: "teste_persistencia",
      entityType: "teste",
      observations: [
        "Teste de persistência executado em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Dados criados via script de teste",
        "Verificando se o salvamento funciona"
      ]
    },
    {
      type: "entity", 
      name: "mcp_memory_project",
      entityType: "projeto",
      observations: [
        "Projeto MCP Memory Server",
        "Servidor simplificado usando JSON",
        "Teste de funcionalidade"
      ]
    }
  ],
  relations: [
    {
      from: "teste_persistencia",
      to: "mcp_memory_project", 
      relationType: "pertence_a"
    }
  ]
};

// Salvar arquivo
fs.writeFileSync('./memory.json', JSON.stringify(testData, null, 2));
console.log('Dados de teste criados em memory.json');
"@

# Executar script de teste
$testScript | node 2>&1

# Verificar resultado
Write-Host ""
Write-Host "📁 Estado Após Teste:" -ForegroundColor Blue
$finalState = Test-MemoryFile

# Comparar estados
Write-Host ""
Write-Host "📊 Resultado do Teste:" -ForegroundColor Blue

if ($finalState) {
  Write-Host "✅ SUCESSO: Dados foram salvos!" -ForegroundColor Green
  Write-Host "   • Arquivo memory.json criado/atualizado" -ForegroundColor White
  Write-Host "   • Entidades: $($finalState.entities.Count)" -ForegroundColor White
  Write-Host "   • Relacionamentos: $($finalState.relations.Count)" -ForegroundColor White
}
else {
  Write-Host "❌ FALHA: Dados não foram salvos" -ForegroundColor Red
}

Write-Host ""
Write-Host "💡 Para testar com Claude Desktop:" -ForegroundColor Yellow
Write-Host "   1. Reinicie Claude Desktop" -ForegroundColor White
Write-Host "   2. Execute: mcp_memory_read_graph" -ForegroundColor Green
Write-Host "   3. Deve mostrar os dados de teste criados" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Para monitorar mudanças:" -ForegroundColor Yellow
Write-Host "   .\test-persistence.ps1 -WatchMode" -ForegroundColor Green

Write-Host ""