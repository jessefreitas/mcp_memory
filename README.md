# MCP Memory Server

Um servidor de protocolo de contexto de modelo (MCP) que fornece funcionalidades de memória persistente para conversas com IA. Este servidor permite que aplicações de IA criem, gerenciem e consultem entidades e relacionamentos em um grafo de conhecimento persistente.

## Funcionalidades

- 📊 **Gerenciamento de Entidades**: Crie, atualize e exclua entidades com observações
- 🔗 **Relacionamentos**: Estabeleça e gerencie relacionamentos entre entidades
- 🔍 **Busca Avançada**: Procure entidades e relacionamentos por conteúdo
- 💾 **Persistência**: Armazenamento SQLite para memória de longa duração
- 🎯 **Compatível com MCP**: Funciona com qualquer cliente MCP (Claude Desktop, etc.)

## Instalação

### Via npm (Recomendado)

```bash
npm install -g mcp-memory-server
```

### Desenvolvimento Local

```bash
git clone <repository-url>
cd mcp_memory
npm install
npm install typescript --save-dev
npm run build
```

## Configuração

### Inicialização Automática com Windows

O MCP Memory Server pode ser configurado para iniciar automaticamente com o Windows:

#### 🎯 **Método Rápido (Recomendado)**
```bash
# Habilitar inicialização automática (Tarefa Agendada + Dashboard)
npm run autostart:enable

# Verificar status
npm run autostart:status

# Desabilitar se necessário
npm run autostart:disable
```

#### 🖥️ **Interface Gráfica**
```bash
# Abrir configurador visual
powershell -ExecutionPolicy Bypass -File setup-windows.ps1
```

#### ⚙️ **Métodos Disponíveis**

1. **Pasta de Inicialização** (Simples)
   ```bash
   .\auto-start.ps1 startup -Dashboard
   ```

2. **Tarefa Agendada** (Recomendado)
   ```bash
   .\auto-start.ps1 task -Dashboard
   ```

3. **Serviço Windows** (Avançado - Requer Admin)
   ```bash
   .\install-service.ps1 install
   ```

### Claude Desktop

Adicione ao seu arquivo de configuração do Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "memory": {
      "command": "node",
      "args": ["C:\\vscode\\mcp_memory\\build\\index.js"],
      "env": {
        "MCP_MEMORY_DB_PATH": "C:\\vscode\\mcp_memory\\memory.db"
      }
    }
  }
}
```

### Configuração Local

Para desenvolvimento local:

```json
{
  "mcpServers": {
    "memory": {
      "command": "node",
      "args": ["./build/index.js"],
      "env": {
        "MCP_MEMORY_DB_PATH": "./memory.db"
      }
    }
  }
}
```

## Uso

### Ferramentas Disponíveis

O servidor MCP Memory fornece as seguintes ferramentas:

#### 1. Criar Entidades

```typescript
mcp_memory_create_entities({
  entities: [
    {
      name: "João Silva",
      entityType: "pessoa",
      observations: [
        "Trabalha como engenheiro de software",
        "Mora em São Paulo",
      ],
    },
  ],
});
```

#### 2. Adicionar Observações

```typescript
mcp_memory_add_observations({
  observations: [
    {
      entityName: "João Silva",
      contents: [
        "Gosta de programação em TypeScript",
        "Tem 5 anos de experiência",
      ],
    },
  ],
});
```

#### 3. Criar Relacionamentos

```typescript
mcp_memory_create_relations({
  relations: [
    {
      from: "João Silva",
      to: "TechCorp",
      relationType: "trabalha_para",
    },
  ],
});
```

#### 4. Buscar Nós

```typescript
mcp_memory_search_nodes({
  query: "engenheiro",
});
```

#### 5. Abrir Nós Específicos

```typescript
mcp_memory_open_nodes({
  names: ["João Silva", "TechCorp"],
});
```

#### 6. Ler Grafo Completo

```typescript
mcp_memory_read_graph();
```

### Recursos Disponíveis

O servidor também expõe recursos que podem ser acessados:

- `memory://graph` - Grafo de conhecimento completo
- `memory://entities` - Todas as entidades
- `memory://relations` - Todos os relacionamentos
- `memory://stats` - Estatísticas do grafo

## Estrutura do Projeto

```
mcp_memory/
├── src/
│   ├── index.ts              # Ponto de entrada principal
│   ├── memory/
│   │   └── MemoryManager.ts  # Gerenciador de memória SQLite
│   ├── tools/
│   │   └── index.ts          # Definições de ferramentas MCP
│   └── resources/
│       └── index.ts          # Definições de recursos MCP
├── package.json
├── tsconfig.json
└── README.md
```

## Desenvolvimento

### Executar em Modo de Desenvolvimento

```bash
npm run dev
```

### Construir o Projeto

```bash
npm run build
```

### Executar Testes

```bash
npm test
```

### Linting e Formatação

```bash
npm run lint
npm run format
```

## Variáveis de Ambiente

- `MCP_MEMORY_DB_PATH`: Caminho para o banco de dados SQLite (padrão: `./memory.db`)

## Exemplos de Uso

### Exemplo 1: Gerenciar Informações de Contato

```typescript
// Criar uma pessoa
await mcp_memory_create_entities({
  entities: [
    {
      name: "Ana Costa",
      entityType: "pessoa",
      observations: ["Email: ana@example.com", "Telefone: (11) 99999-9999"],
    },
  ],
});

// Criar uma empresa
await mcp_memory_create_entities({
  entities: [
    {
      name: "Startup XYZ",
      entityType: "empresa",
      observations: ["Startup de tecnologia", "Fundada em 2023"],
    },
  ],
});

// Criar relacionamento
await mcp_memory_create_relations({
  relations: [
    {
      from: "Ana Costa",
      to: "Startup XYZ",
      relationType: "fundadora",
    },
  ],
});
```

### Exemplo 2: Buscar Informações

```typescript
// Buscar por termo específico
const resultado = await mcp_memory_search_nodes({
  query: "startup",
});

// Obter detalhes completos
const entidades = await mcp_memory_open_nodes({
  names: ["Ana Costa", "Startup XYZ"],
});
```

## Arquitetura

O MCP Memory Server utiliza:

- **SQLite**: Para armazenamento persistente de dados
- **TypeScript SDK**: Para implementação do protocolo MCP
- **Better SQLite3**: Para operações de banco de dados síncronas e performáticas
- **UUID**: Para geração de identificadores únicos
- **Zod**: Para validação de esquemas de entrada

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adicionar nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## Suporte

Para questões e suporte:

1. Abra uma issue no GitHub
2. Consulte a documentação do MCP em [modelcontextprotocol.io](https://modelcontextprotocol.io/)
3. Participe das discussões da comunidade MCP

## 💼 Integração com VS Code

### 🚀 Setup Completo para Desenvolvimento

Este projeto está **totalmente integrado ao VS Code** com todas as ferramentas necessárias:

#### 1. **Workspace Configurado**
```bash
# Abrir workspace otimizado
code mcp-memory.code-workspace
```

#### 2. **Command Palette Integration**
Use `Ctrl+Shift+P` para acessar todos os comandos MCP:

- **MCP: Start Server** - Iniciar servidor
- **MCP: Stop Server** - Parar servidor  
- **MCP: Open Dashboard** - Abrir dashboard
- **MCP: Show Status** - Ver status
- **MCP: Debug Mode** - Modo debug
- **MCP: Watch Mode** - Desenvolvimento ativo

#### 3. **Atalhos de Teclado Otimizados**
Comandos rápidos com `Ctrl+Shift+M` + tecla:

- `S` - Iniciar servidor
- `B` - Build projeto
- `W` - Watch mode
- `D` - Debug
- `T` - Executar testes
- `H` - Abrir dashboard

#### 4. **Tasks Integradas**
Acesse via `Ctrl+Shift+P` → "Tasks: Run Task":

- **Build** - Compilar TypeScript
- **Run MCP Memory Server** - Executar servidor
- **Watch and Build** - Modo desenvolvimento
- **Start Dashboard** - Interface web
- **Test Memory Operations** - Executar testes
- **Enable/Disable Auto Start** - Gerenciar auto-início

#### 5. **Debug Configurations**
Múltiplas opções de debug (`F5`):

- **MCP Memory Server** - Debug padrão
- **Debug TS Source** - Debug do código fonte
- **MCP Dashboard** - Servidor + Dashboard
- **MCP Test Mode** - Modo teste
- **All MCP Services** - Tudo junto

#### 6. **PowerShell Integration**
Script avançado para controle total:

```powershell
# Comandos principais
.\vscode-mcp.ps1 init       # Configurar VS Code
.\vscode-mcp.ps1 help       # Mostrar todos os comandos
.\vscode-mcp.ps1 dashboard  # Abrir dashboard
.\vscode-mcp.ps1 status     # Status completo
.\vscode-mcp.ps1 notify "Mensagem"  # Notificação
```

### 📊 Dashboard Visual (XAMPP)

Acesse `http://localhost/mcp-dashboard.html` ou use `npm run dashboard` para:

- Interface web integrada ao XAMPP Apache
- Instruções detalhadas para comandos PowerShell
- Comandos VS Code integrados (Command Palette)
- Fluxo de trabalho completo e otimizado
- Atalhos de teclado e configurações

### 🔧 Configurações Automáticas

O workspace inclui configurações otimizadas para:

- IntelliSense aprimorado
- Formatação automática
- Lint integrado
- Snippets personalizados
- Extensões recomendadas
- Settings específicos do projeto

**Veja `VSCODE_INTEGRATION.md` para documentação completa!**

---

## 🔄 Auto-Start Windows

### Status Atual: ✅ **CONFIGURADO E FUNCIONANDO**

O MCP Memory Server está configurado para:

1. **✅ Auto-inicialização no login** (via Pasta de Inicialização)
2. **✅ Dashboard web automático** (http://localhost:3000)
3. **✅ Interface gráfica** (setup-windows.ps1)
4. **✅ Scripts PowerShell avançados**
5. **✅ Integração completa VS Code**

### Comandos de Gerenciamento:

```bash
# Status completo
.\auto-start.ps1 status

# Habilitar/desabilitar
npm run autostart:enable
npm run autostart:disable

# Interface gráfica
.\setup-windows.ps1

# VS Code integration
.\vscode-mcp.ps1 init
```

---

## Roadmap

- [x] ✅ Interface web para visualização (Dashboard implementado)
- [x] ✅ Auto-inicialização Windows (Configurado via Startup)
- [x] ✅ Integração completa VS Code (Workspace + Commands + Debug)
- [x] ✅ PowerShell scripts avançados (Controle total via scripts)
- [x] ✅ Command Palette integration (Todos os comandos disponíveis)
- [ ] 🔄 Suporte para importação/exportação de dados
- [ ] 🔄 Integração com outros formatos de dados
- [ ] 🔄 Métricas e analytics avançadas
- [ ] 🔄 Backup automático e recuperação
- [ ] 🔄 Suporte para múltiplos bancos de dados
