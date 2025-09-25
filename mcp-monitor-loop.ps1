# MCP Monitor Loop - Executa continuamente
while ($true) {
    try {
        Set-Location 'c:\vscode\mcp_memory'
        .\always-active.ps1 -Start
        Start-Sleep 60  # Verifica a cada 1 minuto
    } catch {
        Start-Sleep 30  # Em caso de erro, espera 30s
    }
}
