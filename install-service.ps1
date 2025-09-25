# MCP Memory Server - Windows Service Installer
# Execute como Administrador para instalar o serviço Windows

param(
    [Parameter(Position=0)]
    [ValidateSet("install", "uninstall", "start", "stop", "restart", "status")]
    [string]$Action = "install",
    
    [string]$ServiceName = "MCPMemoryServer",
    [string]$DisplayName = "MCP Memory Server",
    [string]$Description = "Model Context Protocol Memory Server for AI applications",
    [switch]$AutoStart
)

$ErrorActionPreference = "Stop"

# Verificar se está rodando como administrador
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "❌ Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Write-Host "💡 Clique com botão direito no PowerShell e escolha 'Executar como administrador'" -ForegroundColor Yellow
    exit 1
}

# Caminhos
$workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$nodeExePath = (Get-Command node).Source
$serverPath = Join-Path $workingDir "build\index.js"
$wrapperPath = Join-Path $workingDir "service-wrapper.js"

# Cores para output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Install-MCPService {
    Write-ColorOutput "🔧 Instalando serviço Windows para MCP Memory Server..." "Blue"
    
    # Verificar se Node.js existe
    if (-not (Test-Path $nodeExePath)) {
        Write-ColorOutput "❌ Node.js não encontrado no PATH" "Red"
        exit 1
    }
    
    # Verificar se o servidor existe
    if (-not (Test-Path $serverPath)) {
        Write-ColorOutput "⚠️ Servidor não compilado. Compilando..." "Yellow"
        Push-Location $workingDir
        npm run build
        Pop-Location
    }
    
    # Criar wrapper para o serviço
    $wrapperContent = @"
// MCP Memory Server - Windows Service Wrapper
const { spawn } = require('child_process');
const path = require('path');

const serverPath = path.join(__dirname, 'build', 'index.js');
let serverProcess = null;

function startServer() {
    console.log('🚀 Iniciando MCP Memory Server...');
    
    serverProcess = spawn('node', [serverPath], {
        cwd: __dirname,
        stdio: 'inherit',
        env: {
            ...process.env,
            NODE_ENV: 'production',
            MCP_MEMORY_DB: path.join(__dirname, 'memory.db')
        }
    });
    
    serverProcess.on('exit', (code) => {
        console.log('⚠️ Servidor parou com código:', code);
        if (code !== 0) {
            console.log('🔄 Reiniciando em 5 segundos...');
            setTimeout(startServer, 5000);
        }
    });
    
    serverProcess.on('error', (err) => {
        console.error('❌ Erro no servidor:', err);
        setTimeout(startServer, 5000);
    });
}

function stopServer() {
    if (serverProcess) {
        console.log('🛑 Parando MCP Memory Server...');
        serverProcess.kill('SIGTERM');
        serverProcess = null;
    }
}

// Handlers para sinais do sistema
process.on('SIGTERM', () => {
    console.log('📢 Recebido SIGTERM, parando servidor...');
    stopServer();
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('📢 Recebido SIGINT, parando servidor...');
    stopServer();
    process.exit(0);
});

// Iniciar servidor
startServer();

console.log('✅ MCP Memory Server Service iniciado');
"@
    
    $wrapperContent | Out-File -FilePath $wrapperPath -Encoding UTF8
    
    # Criar o serviço usando NSSM (Non-Sucking Service Manager) ou sc.exe
    try {
        # Tentar usar NSSM primeiro (mais robusto)
        $nssmPath = Get-Command nssm -ErrorAction SilentlyContinue
        if ($nssmPath) {
            Write-ColorOutput "📦 Usando NSSM para criar serviço..." "Blue"
            & nssm install $ServiceName $nodeExePath $wrapperPath
            & nssm set $ServiceName DisplayName $DisplayName
            & nssm set $ServiceName Description $Description
            & nssm set $ServiceName Start SERVICE_AUTO_START
            & nssm set $ServiceName AppDirectory $workingDir
        } else {
            # Usar New-Service como fallback
            Write-ColorOutput "📦 Usando New-Service para criar serviço..." "Blue"
            $startupType = if ($AutoStart) { "Automatic" } else { "Manual" }
            
            New-Service -Name $ServiceName `
                       -DisplayName $DisplayName `
                       -Description $Description `
                       -BinaryPathName "`"$nodeExePath`" `"$wrapperPath`"" `
                       -StartupType $startupType `
                       -Credential (Get-Credential -Message "Digite as credenciais para o serviço")
        }
        
        Write-ColorOutput "✅ Serviço '$ServiceName' instalado com sucesso!" "Green"
        Write-ColorOutput "ℹ️ Use 'services.msc' para gerenciar o serviço" "Blue"
        
        if ($AutoStart) {
            Write-ColorOutput "🚀 Iniciando serviço..." "Blue"
            Start-Service -Name $ServiceName
            Write-ColorOutput "✅ Serviço iniciado!" "Green"
        }
        
    } catch {
        Write-ColorOutput "❌ Erro ao instalar serviço: $($_.Exception.Message)" "Red"
        exit 1
    }
}

function Uninstall-MCPService {
    Write-ColorOutput "🗑️ Removendo serviço Windows..." "Blue"
    
    try {
        # Parar o serviço se estiver rodando
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-ColorOutput "🛑 Parando serviço..." "Yellow"
            Stop-Service -Name $ServiceName -Force
        }
        
        # Remover o serviço
        $nssmPath = Get-Command nssm -ErrorAction SilentlyContinue
        if ($nssmPath) {
            & nssm remove $ServiceName confirm
        } else {
            Remove-Service -Name $ServiceName
        }
        
        # Remover wrapper
        if (Test-Path $wrapperPath) {
            Remove-Item $wrapperPath -Force
        }
        
        Write-ColorOutput "✅ Serviço removido com sucesso!" "Green"
        
    } catch {
        Write-ColorOutput "❌ Erro ao remover serviço: $($_.Exception.Message)" "Red"
        exit 1
    }
}

function Start-MCPService {
    Write-ColorOutput "🚀 Iniciando serviço MCP Memory Server..." "Blue"
    try {
        Start-Service -Name $ServiceName
        Write-ColorOutput "✅ Serviço iniciado!" "Green"
    } catch {
        Write-ColorOutput "❌ Erro ao iniciar serviço: $($_.Exception.Message)" "Red"
    }
}

function Stop-MCPService {
    Write-ColorOutput "🛑 Parando serviço MCP Memory Server..." "Blue"
    try {
        Stop-Service -Name $ServiceName -Force
        Write-ColorOutput "✅ Serviço parado!" "Green"
    } catch {
        Write-ColorOutput "❌ Erro ao parar serviço: $($_.Exception.Message)" "Red"
    }
}

function Restart-MCPService {
    Write-ColorOutput "🔄 Reiniciando serviço MCP Memory Server..." "Blue"
    try {
        Restart-Service -Name $ServiceName -Force
        Write-ColorOutput "✅ Serviço reiniciado!" "Green"
    } catch {
        Write-ColorOutput "❌ Erro ao reiniciar serviço: $($_.Exception.Message)" "Red"
    }
}

function Get-MCPServiceStatus {
    Write-ColorOutput "📊 Status do serviço MCP Memory Server:" "Blue"
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            $statusColor = switch ($service.Status) {
                "Running" { "Green" }
                "Stopped" { "Red" }
                default { "Yellow" }
            }
            
            Write-ColorOutput "Serviço: $($service.DisplayName)" "White"
            Write-ColorOutput "Status: $($service.Status)" $statusColor
            Write-ColorOutput "Tipo de Inicialização: $($service.StartType)" "White"
            
            # Verificar se está mesmo rodando
            $process = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
                $_.CommandLine -like "*build/index.js*" 
            }
            
            if ($process) {
                Write-ColorOutput "Processo: PID $($process.Id), Memory: $([math]::Round($process.WorkingSet64/1MB, 2))MB" "Green"
            }
            
        } else {
            Write-ColorOutput "❌ Serviço '$ServiceName' não encontrado" "Red"
        }
        
    } catch {
        Write-ColorOutput "❌ Erro ao verificar status: $($_.Exception.Message)" "Red"
    }
}

# Menu principal
Write-ColorOutput "🧠 MCP Memory Server - Windows Service Manager" "Cyan"
Write-ColorOutput "=======================================" "Cyan"

switch ($Action.ToLower()) {
    "install" { Install-MCPService }
    "uninstall" { Uninstall-MCPService }
    "start" { Start-MCPService }
    "stop" { Stop-MCPService }
    "restart" { Restart-MCPService }
    "status" { Get-MCPServiceStatus }
    default {
        Write-ColorOutput "❓ Uso: .\install-service.ps1 [install|uninstall|start|stop|restart|status]" "Yellow"
        Write-ColorOutput ""
        Write-ColorOutput "Exemplos:" "Blue"
        Write-ColorOutput "  .\install-service.ps1 install    # Instalar e iniciar serviço" "Green"
        Write-ColorOutput "  .\install-service.ps1 status     # Ver status do serviço" "Green"
        Write-ColorOutput "  .\install-service.ps1 uninstall  # Remover serviço" "Green"
        Write-ColorOutput ""
        Write-ColorOutput "💡 Execute como Administrador!" "Yellow"
    }
}