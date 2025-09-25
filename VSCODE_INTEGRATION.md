# Integração VS Code - MCP Memory Server

Este documento explica como usar o MCP Memory Server integrado ao VS Code para desenvolvimento e operação mais eficiente.

## 🚀 Recursos de Integração

### 1. **Workspace Configurado**

- Arquivo `mcp-memory.code-workspace` com configurações otimizadas
- Extensões recomendadas automaticamente
- Configurações de TypeScript e formatação

### 2. **Tasks Automatizadas**

Acesse via `Ctrl+Shift+P` → "Tasks: Run Task":

- **build** - Compilar o projeto TypeScript
- **Run MCP Memory Server** - Iniciar o servidor com dependência de build
- **Watch and Build** - Compilação automática em modo watch
- **Install Dependencies** - Instalar dependências npm
- **Clean Build** - Limpar arquivos de build
- **Test Memory Operations** - Executar testes

### 3. **Debugging Integrado**

Configurações de debug disponíveis (`F5`):

- **Debug MCP Memory Server** - Debug da versão compilada
- **Debug TS Source** - Debug direto do código TypeScript
- **Test MCP Memory Server** - Debug em modo teste com banco em memória

### 4. **Script PowerShell Integrado**

Use o arquivo `mcp-server.ps1` para controle completo:

```powershell
# Comandos básicos
.\mcp-server.ps1 start          # Iniciar servidor
.\mcp-server.ps1 start -Debug   # Iniciar com debug
.\mcp-server.ps1 start -Memory  # Usar banco em memória
.\mcp-server.ps1 status         # Ver status
.\mcp-server.ps1 stop           # Parar servidor
.\mcp-server.ps1 restart        # Reiniciar
.\mcp-server.ps1 build          # Compilar
.\mcp-server.ps1 test           # Testar
```

### 5. **Atalhos de Teclado**

Comandos rápidos com `Ctrl+Shift+M` + tecla:

- `Ctrl+Shift+M` → `S` - Iniciar servidor
- `Ctrl+Shift+M` → `B` - Build projeto
- `Ctrl+Shift+M` → `W` - Watch mode
- `Ctrl+Shift+M` → `D` - Debug
- `Ctrl+Shift+M` → `T` - Executar testes
- `Ctrl+Shift+M` → `H` - Abrir dashboard

### 6. **Dashboard Visual**

Acesse `dashboard.html` para interface gráfica com:

- Status do servidor em tempo real
- Botões para comandos rápidos
- Logs do sistema
- Configurações atuais
- Contadores de entidades e relacionamentos

### 7. **Snippets de Código**

Snippets disponíveis para desenvolvimento:

- `mcp-start` - Comando para iniciar servidor
- `mcp-debug` - Comando para debug
- `mcp-status` - Verificar status
- `mcp-entity` - Template para entidade
- `mcp-relation` - Template para relacionamento

## 📋 Fluxo de Trabalho Recomendado

### Desenvolvimento:

1. Abrir workspace: `File` → `Open Workspace` → `mcp-memory.code-workspace`
2. Instalar extensões recomendadas quando solicitado
3. Usar `Ctrl+Shift+M` → `W` para modo watch durante desenvolvimento
4. Usar `F5` para debug quando necessário

### Teste:

1. `Ctrl+Shift+M` → `T` para executar testes
2. Usar `mcp-server.ps1 start -Memory` para testes com banco em memória
3. Verificar logs no dashboard

### Produção:

1. `Ctrl+Shift+M` → `B` para build final
2. `Ctrl+Shift+M` → `S` para iniciar servidor
3. `Ctrl+Shift+M` → `H` para monitorar via dashboard

## 🛠️ Configuração Inicial

### 1. Primeira vez:

```bash
# No terminal do VS Code
npm install
npm run build
.\mcp-server.ps1 start
```

### 2. Claude Desktop:

Adicione ao `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "memory-server": {
      "command": "node",
      "args": ["C:\\vscode\\mcp_memory\\build\\index.js"],
      "env": {}
    }
  }
}
```

### 3. VS Code Settings:

O workspace já inclui configurações otimizadas para:

- TypeScript
- Formatação automática
- Lint
- Terminal PowerShell
- Problem matchers

## 🔧 Troubleshooting

### Servidor não inicia:

1. Verificar se está compilado: `npm run build`
2. Verificar dependências: `npm install`
3. Usar debug mode: `.\mcp-server.ps1 start -Debug`

### Problemas de TypeScript:

1. Reinstalar dependências: `npm install`
2. Limpar build: `.\mcp-server.ps1 clean` → `npm run build`
3. Verificar versão do Node.js: `node --version`

### Dashboard não carrega:

1. Verificar caminho no keybinding
2. Usar `Ctrl+Shift+P` → "Simple Browser: Show"
3. Navegar para arquivo manualmente

## 📊 Monitoramento

### Logs:

- Dashboard HTML para interface visual
- Terminal integrado para logs detalhados
- Problem panel para erros de compilação

### Status:

- Use `.\mcp-server.ps1 status` para verificação rápida
- Dashboard mostra status em tempo real
- Task manager para verificar processos Node.js

### Performance:

- Monitor CPU/Memory via dashboard
- Usar modo teste para desenvolvimento
- Banco em memória para testes rápidos

---

**💡 Dica:** Mantenha o VS Code workspace aberto e use os atalhos de teclado para máxima produtividade!
