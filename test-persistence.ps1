# MCP Memory Server - Teste de Persistência Simplificado

param(
  [switch]$WatchMode,
  [int]$WatchInterval = 5
)

$ErrorActionPreference = "SilentlyContinue"

function Test-MemoryChanges {
  $memoryPath = "memory.json"
    
  Write-Host ""
  Write-Host "🧪 MCP Memory Server - Teste de Persistência" -ForegroundColor Cyan
  Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
  Write-Host ""
    
  # Verificar se o servidor está rodando
  $serverProcess = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
  Where-Object { $_.CommandLine -like "*simple-index.js*" }
    
  if (-not $serverProcess) {
    Write-Host "❌ Servidor MCP não está rodando!" -ForegroundColor Red
    Write-Host "   Execute: .\server-controller.ps1 start" -ForegroundColor Yellow
    return
  }
    
  Write-Host "✅ Servidor detectado (PID: $($serverProcess[0].Id))" -ForegroundColor Green
    
  # Estado inicial do arquivo JSON
  if (Test-Path $memoryPath) {
    $initialInfo = Get-Item $memoryPath
    $initialContent = Get-Content $memoryPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        
    Write-Host ""
    Write-Host "📊 Estado Atual do Arquivo:" -ForegroundColor Blue
    Write-Host "   Arquivo: memory.json" -ForegroundColor White
    Write-Host "   Tamanho: $($initialInfo.Length) bytes" -ForegroundColor White
    Write-Host "   Modificado: $($initialInfo.LastWriteTime)" -ForegroundColor White
        
    if ($initialContent) {
      $entityCount = if ($initialContent.entities) { $initialContent.entities.Count } else { 0 }
      $relationCount = if ($initialContent.relations) { $initialContent.relations.Count } else { 0 }
            
      Write-Host "   Entidades: $entityCount" -ForegroundColor White
      Write-Host "   Relacionamentos: $relationCount" -ForegroundColor White
            
      # Mostrar entidades se existirem
      if ($initialContent.entities -and $initialContent.entities.Count -gt 0) {
        Write-Host ""
        Write-Host "📋 Entidades Encontradas:" -ForegroundColor Blue
        $initialContent.entities | ForEach-Object {
          Write-Host "   • $($_.name) ($($_.entityType))" -ForegroundColor Green
          if ($_.observations) {
            Write-Host "     Observações: $($_.observations.Count)" -ForegroundColor Gray
            $_.observations | Select-Object -First 3 | ForEach-Object {
              Write-Host "       - $_" -ForegroundColor Gray
            }
            if ($_.observations.Count -gt 3) {
              Write-Host "       ... e mais $($_.observations.Count - 3)" -ForegroundColor Gray
            }
          }
        }
      }
    }
        
  }
  else {
    Write-Host ""
    Write-Host "⚠️ Arquivo memory.json não existe" -ForegroundColor Yellow
    Write-Host "   Será criado quando dados forem salvos via MCP" -ForegroundColor White
  }
    
  Write-Host ""
  Write-Host "📝 Para Testar o Salvamento:" -ForegroundColor Blue
  Write-Host "   1. Reinicie Claude Desktop" -ForegroundColor White
  Write-Host "   2. Execute um comando MCP como:" -ForegroundColor White
  Write-Host "      'mcp_memory_create_entities'" -ForegroundColor Green
  Write-Host "   3. Execute este script novamente para ver mudanças" -ForegroundColor White
    
  if ($WatchMode) {
    Write-Host ""
    Write-Host "👀 Modo Watch ativo - Ctrl+C para parar" -ForegroundColor Yellow
        
    $lastModified = if (Test-Path $memoryPath) { (Get-Item $memoryPath).LastWriteTime } else { $null }
        
    while ($true) {
      Start-Sleep $WatchInterval
            
      if (Test-Path $memoryPath) {
        $currentModified = (Get-Item $memoryPath).LastWriteTime
        if ($lastModified -ne $currentModified) {
          Write-Host "🎉 MUDANÇA DETECTADA! $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
          $content = Get-Content $memoryPath -Raw | ConvertFrom-Json
          if ($content.entities) {
            Write-Host "   Entidades: $($content.entities.Count)" -ForegroundColor White
          }
          $lastModified = $currentModified
        }
      }
      else {
        Write-Host "⏳ Aguardando arquivo... $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
      }
    }
  }
}

Test-MemoryChanges