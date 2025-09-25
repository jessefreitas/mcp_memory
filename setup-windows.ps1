# MCP Memory Server - Instalador Visual para Windows
# Interface gráfica para configuração de inicialização automática

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Verificar se está rodando como administrador para algumas opções
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator

# Criar form principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "MCP Memory Server - Configuração Windows"
$form.Size = New-Object System.Drawing.Size(500, 450)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Logo/Título
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "🧠 MCP Memory Server"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Blue
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(450, 40)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($titleLabel)

# Descrição
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = "Configure a inicialização automática do servidor MCP Memory no Windows"
$descLabel.Location = New-Object System.Drawing.Point(20, 70)
$descLabel.Size = New-Object System.Drawing.Size(450, 30)
$descLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($descLabel)

# GroupBox para opções
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = "Método de Inicialização"
$optionsGroup.Location = New-Object System.Drawing.Point(20, 110)
$optionsGroup.Size = New-Object System.Drawing.Size(450, 180)
$form.Controls.Add($optionsGroup)

# Radio buttons para métodos
$radioStartup = New-Object System.Windows.Forms.RadioButton
$radioStartup.Text = "Pasta de Inicialização (Simples)"
$radioStartup.Location = New-Object System.Drawing.Point(20, 30)
$radioStartup.Size = New-Object System.Drawing.Size(400, 20)
$radioStartup.Checked = $true
$optionsGroup.Controls.Add($radioStartup)

$startupDesc = New-Object System.Windows.Forms.Label
$startupDesc.Text = "• Inicia apenas quando o usuário faz login`n• Método mais simples e compatível"
$startupDesc.Location = New-Object System.Drawing.Point(40, 50)
$startupDesc.Size = New-Object System.Drawing.Size(380, 35)
$startupDesc.ForeColor = [System.Drawing.Color]::Gray
$optionsGroup.Controls.Add($startupDesc)

$radioTask = New-Object System.Windows.Forms.RadioButton
$radioTask.Text = "Tarefa Agendada (Recomendado)"
$radioTask.Location = New-Object System.Drawing.Point(20, 90)
$radioTask.Size = New-Object System.Drawing.Size(400, 20)
$optionsGroup.Controls.Add($radioTask)

$taskDesc = New-Object System.Windows.Forms.Label
$taskDesc.Text = "• Maior controle e confiabilidade`n• Pode ser configurada para executar sem login"
$taskDesc.Location = New-Object System.Drawing.Point(40, 110)
$taskDesc.Size = New-Object System.Drawing.Size(380, 35)
$taskDesc.ForeColor = [System.Drawing.Color]::Gray
$optionsGroup.Controls.Add($taskDesc)

$radioService = New-Object System.Windows.Forms.RadioButton
$radioService.Text = "Serviço Windows (Avançado)"
$radioService.Location = New-Object System.Drawing.Point(20, 150)
$radioService.Size = New-Object System.Drawing.Size(400, 20)
if (-not $isAdmin) {
    $radioService.Enabled = $false
    $radioService.Text += " - Requer Administrador"
}
$optionsGroup.Controls.Add($radioService)

# Checkbox para dashboard
$dashboardCheck = New-Object System.Windows.Forms.CheckBox
$dashboardCheck.Text = "Incluir Dashboard (Interface Web)"
$dashboardCheck.Location = New-Object System.Drawing.Point(20, 300)
$dashboardCheck.Size = New-Object System.Drawing.Size(450, 20)
$dashboardCheck.Checked = $true
$form.Controls.Add($dashboardCheck)

# Status atual
$statusGroup = New-Object System.Windows.Forms.GroupBox
$statusGroup.Text = "Status Atual"
$statusGroup.Location = New-Object System.Drawing.Point(20, 330)
$statusGroup.Size = New-Object System.Drawing.Size(450, 50)
$form.Controls.Add($statusGroup)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Verificando..."
$statusLabel.Location = New-Object System.Drawing.Point(10, 20)
$statusLabel.Size = New-Object System.Drawing.Size(430, 20)
$statusGroup.Controls.Add($statusLabel)

# Botões
$buttonPanel = New-Object System.Windows.Forms.Panel
$buttonPanel.Location = New-Object System.Drawing.Point(20, 390)
$buttonPanel.Size = New-Object System.Drawing.Size(450, 40)
$form.Controls.Add($buttonPanel)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Instalar"
$installButton.Location = New-Object System.Drawing.Point(0, 0)
$installButton.Size = New-Object System.Drawing.Size(100, 35)
$installButton.BackColor = [System.Drawing.Color]::Green
$installButton.ForeColor = [System.Drawing.Color]::White
$buttonPanel.Controls.Add($installButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remover"
$removeButton.Location = New-Object System.Drawing.Point(110, 0)
$removeButton.Size = New-Object System.Drawing.Size(100, 35)
$removeButton.BackColor = [System.Drawing.Color]::Red
$removeButton.ForeColor = [System.Drawing.Color]::White
$buttonPanel.Controls.Add($removeButton)

$statusButton = New-Object System.Windows.Forms.Button
$statusButton.Text = "Atualizar Status"
$statusButton.Location = New-Object System.Drawing.Point(220, 0)
$statusButton.Size = New-Object System.Drawing.Size(120, 35)
$buttonPanel.Controls.Add($statusButton)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Fechar"
$closeButton.Location = New-Object System.Drawing.Point(350, 0)
$closeButton.Size = New-Object System.Drawing.Size(100, 35)
$buttonPanel.Controls.Add($closeButton)

# Função para verificar status
function Update-Status {
    try {
        $status = @()
        
        # Verificar pasta startup
        $startupFolder = [Environment]::GetFolderPath("Startup")
        $startupScript = Join-Path $startupFolder "MCP-Memory-Server.bat"
        if (Test-Path $startupScript) {
            $status += "Startup: ✅"
        }
        
        # Verificar tarefa agendada
        $task = Get-ScheduledTask -TaskName "MCP Memory Server" -ErrorAction SilentlyContinue
        if ($task) {
            $status += "Tarefa: ✅"
        }
        
        # Verificar serviço
        $service = Get-Service -Name "MCPMemoryServer" -ErrorAction SilentlyContinue
        if ($service) {
            $status += "Serviço: ✅"
        }
        
        # Verificar se está rodando
        $process = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { 
            $_.CommandLine -like "*build/index.js*" 
        }
        if ($process) {
            $status += "Rodando: ✅"
        }
        
        if ($status.Count -eq 0) {
            $statusLabel.Text = "❌ Nenhuma configuração de inicialização ativa"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        } else {
            $statusLabel.Text = $status -join " | "
            $statusLabel.ForeColor = [System.Drawing.Color]::Green
        }
    } catch {
        $statusLabel.Text = "⚠️ Erro ao verificar status"
        $statusLabel.ForeColor = [System.Drawing.Color]::Orange
    }
}

# Event handlers
$installButton.Add_Click({
    try {
        $workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        
        if ($radioStartup.Checked) {
            & "$workingDir\auto-start.ps1" startup $(if ($dashboardCheck.Checked) { "-Dashboard" } else { "" }) | Out-Null
            [System.Windows.Forms.MessageBox]::Show("Configuração da pasta de inicialização concluída!", "Sucesso", "OK", "Information")
        }
        elseif ($radioTask.Checked) {
            & "$workingDir\auto-start.ps1" task $(if ($dashboardCheck.Checked) { "-Dashboard" } else { "" }) | Out-Null
            [System.Windows.Forms.MessageBox]::Show("Tarefa agendada criada com sucesso!", "Sucesso", "OK", "Information")
        }
        elseif ($radioService.Checked) {
            if ($isAdmin) {
                $result = & "$workingDir\install-service.ps1" install
                [System.Windows.Forms.MessageBox]::Show("Serviço Windows instalado com sucesso!", "Sucesso", "OK", "Information")
            } else {
                [System.Windows.Forms.MessageBox]::Show("Execute como Administrador para instalar serviço!", "Erro", "OK", "Error")
            }
        }
        
        Update-Status
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro na instalação: $($_.Exception.Message)", "Erro", "OK", "Error")
    }
})

$removeButton.Add_Click({
    try {
        $result = [System.Windows.Forms.MessageBox]::Show("Remover todas as configurações de inicialização?", "Confirmação", "YesNo", "Question")
        if ($result -eq "Yes") {
            $workingDir = Split-Path -Parent $MyInvocation.MyCommand.Path
            & "$workingDir\auto-start.ps1" remove
            
            if ($isAdmin) {
                & "$workingDir\install-service.ps1" uninstall
            }
            
            [System.Windows.Forms.MessageBox]::Show("Configurações removidas com sucesso!", "Sucesso", "OK", "Information")
            Update-Status
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Erro na remoção: $($_.Exception.Message)", "Erro", "OK", "Error")
    }
})

$statusButton.Add_Click({
    Update-Status
})

$closeButton.Add_Click({
    $form.Close()
})

# Verificar status inicial
Update-Status

# Mostrar form
$form.ShowDialog() | Out-Null