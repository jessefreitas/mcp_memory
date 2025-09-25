@echo off
REM MCP Memory Server - Windows Startup Script
REM Este arquivo pode ser colocado na pasta de inicialização do Windows

echo 🧠 Iniciando MCP Memory Server...

REM Navegar para o diretório do projeto
cd /d "C:\vscode\mcp_memory"

REM Verificar se Node.js está disponível
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Node.js não encontrado no PATH
    echo 💡 Instale Node.js ou adicione ao PATH do sistema
    pause
    exit /b 1
)

REM Verificar se o projeto está compilado
if not exist "build\index.js" (
    echo 🔨 Compilando projeto...
    call npm run build
    if errorlevel 1 (
        echo ❌ Erro na compilação
        pause
        exit /b 1
    )
)

REM Iniciar o servidor em background
echo ✅ Iniciando servidor MCP Memory...
start "MCP Memory Server" /min node build\index.js

REM Aguardar alguns segundos para verificar se iniciou
timeout /t 3 /nobreak >nul

REM Verificar se o processo está rodando
tasklist /fi "windowtitle eq MCP Memory Server*" 2>nul | find /i "node.exe" >nul
if errorlevel 1 (
    echo ⚠️ Servidor pode não ter iniciado corretamente
) else (
    echo ✅ MCP Memory Server iniciado com sucesso!
)

REM Opcional: iniciar dashboard também
REM start "MCP Dashboard" /min node dashboard-server.js

echo ℹ️ Para parar o servidor, feche a janela "MCP Memory Server"
exit /b 0