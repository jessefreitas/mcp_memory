# Teste direto do servidor MCP - Verifica se consegue ler dados salvos

$testJson = @'
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "mcp_memory_read_graph",
    "arguments": {}
  }
}
'@

Write-Host "🧪 Testando leitura de dados pelo servidor MCP..." -ForegroundColor Blue
Write-Host ""

try {
  # Enviar comando JSON para o servidor via stdio
  $result = $testJson | node build\simple-index.js 2>&1
    
  Write-Host "📤 Comando enviado:" -ForegroundColor Green
  Write-Host $testJson -ForegroundColor Gray
  Write-Host ""
    
  Write-Host "📥 Resposta do servidor:" -ForegroundColor Green
  Write-Host $result -ForegroundColor White
    
}
catch {
  Write-Host "❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📁 Conteúdo atual do memory.json:" -ForegroundColor Blue
if (Test-Path "memory.json") {
  Get-Content "memory.json" | ConvertFrom-Json | ConvertTo-Json -Depth 4
}
else {
  Write-Host "❌ Arquivo não encontrado" -ForegroundColor Red
}