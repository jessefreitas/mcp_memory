# MCP Memory Server - Inicialização Automática Windows

Este guia explica como configurar o MCP Memory Server para iniciar automaticamente com o Windows.

## 🚀 Configuração Rápida

### Método Mais Simples
```bash
# 1. Compilar o projeto
npm run build

# 2. Habilitar inicialização automática
npm run autostart:enable

# 3. Verificar se está funcionando
npm run autostart:status
```

### Interface Gráfica
Para uma experiência visual, use o configurador:
```bash
powershell -ExecutionPolicy Bypass -File setup-windows.ps1
```

## 📋 Métodos Disponíveis

### 1. 📁 **Pasta de Inicialização** (Mais Simples)
- **Como funciona**: Coloca um script na pasta de inicialização do Windows
- **Vantagens**: Simples, compatível com todas as versões do Windows
- **Desvantagens**: Só inicia quando o usuário faz login
- **Comando**: `.\auto-start.ps1 startup`

**Localização**: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`

### 2. 📅 **Tarefa Agendada** (Recomendado)
- **Como funciona**: Cria uma tarefa agendada no Windows
- **Vantagens**: Maior controle, pode executar sem login visível
- **Desvantagens**: Requer conhecimento básico de tarefas agendadas
- **Comando**: `.\auto-start.ps1 task`

**Gerenciar**: `taskschd.msc` ou `Ctrl+Shift+Esc` → `Mais detalhes` → `Aba Inicializar`

### 3. 🔧 **Serviço Windows** (Mais Robusto)
- **Como funciona**: Instala como serviço real do Windows
- **Vantagens**: Reinicia automaticamente, executa sempre, mais profissional
- **Desvantagens**: Requer privilégios de administrador
- **Comando**: `.\install-service.ps1 install` (como Admin)

**Gerenciar**: `services.msc`

## ⚙️ Opções de Configuração

### Incluir Dashboard Web
Todos os métodos podem incluir o dashboard web (interface visual):
```bash
# Com dashboard
.\auto-start.ps1 task -Dashboard
.\auto-start.ps1 startup -Dashboard

# Sem dashboard
.\auto-start.ps1 task
.\auto-start.ps1 startup
```

### Configurações de Banco de Dados
- **Padrão**: `memory.db` (arquivo local)
- **Teste**: `:memory:` (apenas na RAM)
- **Personalizado**: Definir `MCP_MEMORY_DB` 

## 🛠️ Comandos Úteis

### Scripts NPM Disponíveis
```bash
npm run autostart:enable    # Habilitar (tarefa + dashboard)
npm run autostart:disable   # Desabilitar tudo
npm run autostart:status    # Ver status atual
npm run install:service     # Instalar serviço (Admin)
npm run uninstall:service   # Remover serviço (Admin)
```

### Scripts PowerShell Diretos
```bash
# Configuração automática
.\auto-start.ps1 [startup|task|remove|status] [-Dashboard]

# Serviço Windows  
.\install-service.ps1 [install|uninstall|start|stop|restart|status]

# Interface gráfica
.\setup-windows.ps1

# Controle manual
.\mcp-server.ps1 [start|stop|restart|status|build|test]
```

## 📊 Verificação e Monitoramento

### Verificar se está rodando
```bash
# Via script
npm run autostart:status

# Via PowerShell
Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*build/index.js*" }

# Via Task Manager
Ctrl+Shift+Esc → Procurar por "node.exe"
```

### Dashboard Web
Se habilitado, acesse: `http://localhost:3000`

### Logs do Sistema
- **Windows Event Viewer**: `eventvwr.msc`
- **Task Scheduler Logs**: `taskschd.msc` → Task → History
- **Service Logs**: `services.msc` → Service → Properties → Log On

## 🔧 Troubleshooting

### Servidor não inicia
1. **Verificar compilação**:
   ```bash
   npm run build
   ```

2. **Verificar Node.js**:
   ```bash
   node --version
   ```

3. **Testar manualmente**:
   ```bash
   node build/index.js
   ```

### Permissões
- **Pasta Startup**: Não requer admin
- **Tarefa Agendada**: Não requer admin (para usuário atual)
- **Serviço Windows**: **Requer administrador**

### Conflitos de Porta
Se o dashboard não carregar:
1. Verificar se porta 3000 está livre
2. Alterar porta no `dashboard-server.js`
3. Reiniciar o servidor

### Múltiplas Instâncias
Para evitar múltiplas instâncias rodando:
```bash
# Parar todos
.\mcp-server.ps1 stop

# Remover todas as configurações
npm run autostart:disable

# Reconfigurar
npm run autostart:enable
```

## 📁 Estrutura de Arquivos

### Scripts de Inicialização
- `auto-start.ps1` - Configurador principal
- `install-service.ps1` - Instalador de serviço
- `setup-windows.ps1` - Interface gráfica
- `mcp-server.ps1` - Controle manual
- `startup.bat` - Script batch simples

### Arquivos Gerados
- `service-wrapper.js` - Wrapper para serviço Windows
- `%STARTUP%\MCP-Memory-Server.bat` - Script da pasta startup
- Task Scheduler entry - Tarefa agendada
- Windows Service entry - Serviço do sistema

## 🎯 Recomendações

### Para Usuários Comuns
```bash
npm run autostart:enable
```
Usa tarefa agendada com dashboard - equilibrio perfeito entre simplicidade e funcionalidade.

### Para Desenvolvedores
```bash
.\auto-start.ps1 startup -Dashboard
```
Inicialização simples que permite fácil debugging.

### Para Produção/Empresas
```bash
.\install-service.ps1 install
```
Serviço Windows robusto com reinicialização automática.

### Para Testes
```bash
.\auto-start.ps1 task
# Sem dashboard para menor consumo de recursos
```

## 🔄 Migração Entre Métodos

Para trocar de método:
```bash
# 1. Remover configuração atual
npm run autostart:disable

# 2. Escolher novo método
.\auto-start.ps1 [startup|task]
# ou
.\install-service.ps1 install

# 3. Verificar
npm run autostart:status
```

---

**💡 Dica**: Use `npm run autostart:enable` para começar rapidamente, e depois ajuste conforme necessário!