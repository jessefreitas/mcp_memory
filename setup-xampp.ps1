# Script para configurar Dashboard no XAMPP
param(
    [string]$XamppPath = "C:\xampp\htdocs",
    [switch]$Open = $false
)

$ErrorActionPreference = "Stop"

Write-Host "Configurando Dashboard MCP no XAMPP..." -ForegroundColor Cyan

# Verificar se XAMPP existe
if (-not (Test-Path $XamppPath)) {
    Write-Host "XAMPP nao encontrado em: $XamppPath" -ForegroundColor Red
    Write-Host "Instale o XAMPP ou forneca o caminho correto:" -ForegroundColor Yellow
    Write-Host "   .\setup-xampp.ps1 -XamppPath 'C:\seu\caminho\xampp\htdocs'" -ForegroundColor Yellow
    exit 1
}

# Caminho do arquivo fonte
$sourceFile = Join-Path $PSScriptRoot "mcp-dashboard-xampp.html"
$destFile = Join-Path $XamppPath "mcp-dashboard.html"

# Verificar arquivo fonte
if (-not (Test-Path $sourceFile)) {
    Write-Host "Arquivo dashboard nao encontrado: $sourceFile" -ForegroundColor Red
    exit 1
}

try {
    # Copiar arquivo
    Copy-Item $sourceFile $destFile -Force
    Write-Host "Dashboard copiado para XAMPP!" -ForegroundColor Green
    Write-Host "Local: $destFile" -ForegroundColor White
    
    # Verificar se Apache esta rodando
    $apacheProcess = Get-Process -Name "httpd" -ErrorAction SilentlyContinue
    if ($apacheProcess) {
        Write-Host "Apache esta rodando!" -ForegroundColor Green
        $url = "http://localhost/mcp-dashboard.html"
        Write-Host "Dashboard disponivel em: $url" -ForegroundColor Cyan
        
        if ($Open) {
            Write-Host "Abrindo dashboard..." -ForegroundColor Yellow
            Start-Process $url
        }
    } else {
        Write-Host "Apache nao esta rodando!" -ForegroundColor Yellow
        Write-Host "Inicie o Apache no XAMPP Control Panel" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Instrucoes de uso:" -ForegroundColor White
    Write-Host "1. Certifique-se que Apache esta rodando no XAMPP" -ForegroundColor Gray
    Write-Host "2. Acesse: http://localhost/mcp-dashboard.html" -ForegroundColor Gray
    Write-Host "3. Use os comandos mostrados no dashboard" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Para executar comandos MCP:" -ForegroundColor White
    Write-Host "   - Abra VS Code: code mcp-memory.code-workspace" -ForegroundColor Gray
    Write-Host "   - Use: Ctrl+Shift+P -> 'MCP:'" -ForegroundColor Gray
    Write-Host "   - Ou terminal: .\vscode-mcp.ps1 status" -ForegroundColor Gray
    
} catch {
    Write-Host "Erro ao copiar dashboard: $_" -ForegroundColor Red
    exit 1
}