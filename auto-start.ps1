# MCP Memory Server - Configurador de Inicialização Automática Windows
# Múltiplas opções para inicialização automática

param(
    [Parameter(Position=0)]
    [ValidateSet("startup", "task", "service", "remove", "status")]
    [string]$Method = "startup",
    
    [switch]$Dashboard = $false,
    [switch]$Silent = $false
)

$ErrorActionPreference = "Stop"

# Caminhos
$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$startupFolder = [Environment]::GetFolderPath("Startup")
$startupScript = Join-Path $startupFolder "MCP-Memory-Server.bat"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    if (-not $Silent) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Initialize-StartupFolder {
    Write-ColorOutput "Configurando inicialização via pasta Startup..." "Blue"
    
    $batContent = @"
@echo off
REM MCP Memory Server - Auto Start
cd /d "$workingDir"

REM Verificar Node.js
node --version >nul 2>&1
if errorlevel 1 goto :error

REM Compilar se necessário
if not exist "build\index.js" (
    call npm run build
    if errorlevel 1 goto :error
)

REM Iniciar servidor
start "MCP Memory Server" /min node build\index.js
"@
    
    if ($Dashboard) {
        $batContent += @"

timeout /t 2 /nobreak >nul
start "MCP Dashboard" /min node dashboard-server.js
"@
    }
    
    $batContent += @"

exit /b 0

:error
echo Erro ao iniciar MCP Memory Server
pause
exit /b 1
"@
    
    $batContent | Out-File -FilePath $startupScript -Encoding ASCII
    
    Write-ColorOutput "Script criado em: $startupScript" "Green"
    Write-ColorOutput "O servidor será iniciado automaticamente no próximo login" "Blue"
}

function Initialize-ScheduledTask {
    Write-ColorOutput "Configurando tarefa agendada..." "Blue"
    
    $taskName = "MCP Memory Server"
    $nodeExe = (Get-Command node).Source
    $serverPath = Join-Path $workingDir "build\index.js"
    
    # Remover tarefa existente se houver
    try {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    } catch {}
    
    # Criar ação principal
    $action1 = New-ScheduledTaskAction -Execute $nodeExe -Argument $serverPath -WorkingDirectory $workingDir
    
    $actions = @($action1)
    
    # Adicionar dashboard se solicitado
    if ($Dashboard) {
        $dashboardPath = Join-Path $workingDir "dashboard-server.js"
        $action2 = New-ScheduledTaskAction -Execute $nodeExe -Argument $dashboardPath -WorkingDirectory $workingDir
        $actions += $action2
    }
    
    # Configurar trigger (no login)
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    
    # Configurar configurações
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Configurar principal (usuário atual)
    $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    
    # Registrar tarefa
    Register-ScheduledTask -TaskName $taskName -Action $actions -Trigger $trigger -Settings $settings -Principal $principal -Description "MCP Memory Server - Automatic startup"
    
    Write-ColorOutput "Tarefa agendada criada: $taskName" "Green"
    Write-ColorOutput "Use 'taskschd.msc' para gerenciar a tarefa" "Blue"
}

function Remove-AutoStart {
    Write-ColorOutput "Removendo configurações de inicialização automática..." "Blue"
    
    # Remover da pasta Startup
    if (Test-Path $startupScript) {
        Remove-Item $startupScript -Force
        Write-ColorOutput "Removido da pasta Startup" "Green"
    }
    
    # Remover tarefa agendada
    try {
        Unregister-ScheduledTask -TaskName "MCP Memory Server" -Confirm:$false -ErrorAction SilentlyContinue
        Write-ColorOutput "Tarefa agendada removida" "Green"
    } catch {}
    
    Write-ColorOutput "Todas as configurações de inicialização removidas" "Green"
}

function Get-AutoStartStatus {
    Write-ColorOutput "Status da inicialização automática:" "Blue"
    Write-ColorOutput "=================================" "Blue"
    
    # Verificar pasta Startup
    if (Test-Path $startupScript) {
        Write-ColorOutput "Pasta Startup: Configurado" "Green"
    } else {
        Write-ColorOutput "Pasta Startup: Não configurado" "Red"
    }
    
    # Verificar tarefa agendada
    try {
        $task = Get-ScheduledTask -TaskName "MCP Memory Server" -ErrorAction SilentlyContinue
        if ($task) {
            $status = if ($task.State -eq "Ready") { "Ativa" } else { $task.State }
            Write-ColorOutput "Tarefa Agendada: $status" "Green"
        } else {
            Write-ColorOutput "Tarefa Agendada: Não configurada" "Red"
        }
    } catch {
        Write-ColorOutput "Tarefa Agendada: Não configurada" "Red"
    }
    
    # Verificar se está rodando atualmente
    $process = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
        $_.CommandLine -like "*build/index.js*" 
    }
    
    if ($process) {
        Write-ColorOutput "Status Atual: Rodando (PID: $($process.Id))" "Green"
    } else {
        Write-ColorOutput "Status Atual: Não está rodando" "Red"
    }
}

# Menu principal
Write-ColorOutput "MCP Memory Server - Configurador de Inicialização" "Cyan"
Write-ColorOutput "===============================================" "Cyan"

switch ($Method.ToLower()) {
    "startup" { 
        Initialize-StartupFolder
        Write-ColorOutput ""
        Write-ColorOutput "Método 'Startup': Mais simples, menos controle" "Yellow"
    }
    "task" { 
        Initialize-ScheduledTask
        Write-ColorOutput ""
        Write-ColorOutput "Método 'Task': Mais controle, pode executar sem login" "Yellow"
    }
    "service" { 
        Write-ColorOutput "Para instalar como serviço Windows, use:" "Blue"
        Write-ColorOutput ".\install-service.ps1 install" "Green"
        Write-ColorOutput ""
        Write-ColorOutput "Método 'Service': Mais robusto, executa sempre" "Yellow"
    }
    "remove" { Remove-AutoStart }
    "status" { Get-AutoStartStatus }
    default {
        Write-ColorOutput "Uso: .\auto-start.ps1 [startup|task|service|remove|status] [-Dashboard] [-Silent]" "Yellow"
        Write-ColorOutput ""
        Write-ColorOutput "Métodos:" "Blue"
        Write-ColorOutput "  startup  - Pasta de inicialização (simples)" "Green"
        Write-ColorOutput "  task     - Tarefa agendada (recomendado)" "Green"
        Write-ColorOutput "  service  - Serviço Windows (avançado)" "Green"
        Write-ColorOutput "  remove   - Remover todas as configurações" "Red"
        Write-ColorOutput "  status   - Ver status atual" "Blue"
        Write-ColorOutput ""
        Write-ColorOutput "Exemplos:" "Blue"
        Write-ColorOutput "  .\auto-start.ps1 task -Dashboard    # Tarefa com dashboard" "Green"
        Write-ColorOutput "  .\auto-start.ps1 startup            # Inicialização simples" "Green"
        Write-ColorOutput "  .\auto-start.ps1 status             # Ver status" "Green"
    }
}