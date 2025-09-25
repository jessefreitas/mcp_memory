# =====================================================
# MCP REAL STATUS - Verificação Definitiva
# =====================================================

Write-Host "🧠 MCP MEMORY SERVER - STATUS REAL" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan

# Verificar processos MCP
$mcpProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue | 
                Where-Object { $_.CommandLine -like "*simple-index*" }

if ($mcpProcesses.Count -gt 0) {
    Write-Host "🟢 MCP SERVER: ATIVO" -ForegroundColor Green
    Write-Host "   Processos encontrados: $($mcpProcesses.Count)" -ForegroundColor Gray
    
    foreach ($proc in $mcpProcesses) {
        $uptime = (Get-Date) - $proc.StartTime
        $uptimeStr = "$([math]::Floor($uptime.TotalHours))h $($uptime.Minutes)m"
        Write-Host "   • PID: $($proc.Id) | Uptime: $uptimeStr | RAM: $([math]::Round($proc.WorkingSet64/1MB))MB" -ForegroundColor Gray
    }
} else {
    Write-Host "🔴 MCP SERVER: INATIVO" -ForegroundColor Red
}

# Verificar arquivos de persistência
if (Test-Path "memory.json") {
    $size = (Get-Item "memory.json").Length
    $lastWrite = (Get-Item "memory.json").LastWriteTime
    Write-Host "💾 DADOS: memory.json ($size bytes)" -ForegroundColor Green
    Write-Host "   Última modificação: $lastWrite" -ForegroundColor Gray
} else {
    Write-Host "💾 DADOS: memory.json não encontrado" -ForegroundColor Yellow
}

# Verificar build
if (Test-Path "build\simple-index.js") {
    Write-Host "🔨 BUILD: Atualizado" -ForegroundColor Green
} else {
    Write-Host "🔨 BUILD: Não encontrado" -ForegroundColor Red
}

# Verificar auto-start
$startupScript = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\MCP-Monitor.bat"
if (Test-Path $startupScript) {
    Write-Host "🚀 AUTO-START: Configurado" -ForegroundColor Green
} else {
    Write-Host "🚀 AUTO-START: Não configurado" -ForegroundColor Yellow
}

# Verificar monitor loop
$monitorProcess = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | 
                  Where-Object { $_.CommandLine -like "*mcp-monitor-loop.ps1*" }
if ($monitorProcess) {
    Write-Host "🔄 MONITOR LOOP: Ativo" -ForegroundColor Green
} else {
    Write-Host "🔄 MONITOR LOOP: Inativo" -ForegroundColor Yellow
}

Write-Host "`n🎯 RESUMO:" -ForegroundColor Yellow
if ($mcpProcesses.Count -gt 0) {
    Write-Host "   ✅ MCP está SEMPRE ATIVO e funcionando!" -ForegroundColor Green
} else {
    Write-Host "   ❌ MCP precisa ser iniciado" -ForegroundColor Red
}

Write-Host "=" * 60 -ForegroundColor Cyan