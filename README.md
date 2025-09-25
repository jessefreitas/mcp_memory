# MCP Memory Server

Um servidor de protocolo de contexto de modelo (MCP) que fornece funcionalidades de memória persistente para conversas com IA. Este servidor permite que aplicações de IA criem, gerenciem e consultem entidades e relacionamentos em um grafo de conhecimento persistente.

## 🚀 Início Rápido

### 1. Clone e Configure

```powershell
git clone https://github.com/jessefreitas/mcp_memory.git
cd mcp_memory
npm install
npm run build
```

### 2. Inicie o Servidor

```powershell
# Configurar auto-start (Windows)
.\auto-start.ps1

# OU iniciar manualmente
.\server-controller.ps1
```

### 3. Teste a Funcionalidade

```powershell
# Executar teste completo
.\run-test.ps1

# Verificar status
.\quick-status.ps1
```

### 4. Configure Claude Desktop

Adicione ao `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "mcp_memory": {
      "command": "node",
      "args": ["./build/simple-index.js"],
      "cwd": "c:\\vscode\\mcp_memory"
    }
  }
}
```

### 5. Teste no Claude Desktop

```
Use o comando: mcp_memory_read_graph
```

## Funcionalidades

- 📊 **Gerenciamento de Entidades**: Crie, atualize e exclua entidades com observações
- 🔗 **Relacionamentos**: Estabeleça e gerencie relacionamentos entre entidades
- 🔍 **Busca Avançada**: Procure entidades e relacionamentos por conteúdo
- 💾 **Persistência**: Armazenamento JSON simples e confiável
- 🎯 **Compatível com MCP**: Funciona com qualquer cliente MCP (Claude Desktop, etc.)
- 🚀 **Auto-start**: Configuração automática no Windows
- 🔧 **VS Code Integration**: Integração completa com VS Code
- 🧪 **Suite de Testes**: Scripts PowerShell para teste e validação
- 📊 **Dashboard**: Interface web para monitoramento

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

### Claude Desktop

Adicione ao seu arquivo de configuração do Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "mcp-memory-server"],
      "env": {
        "MCP_MEMORY_DB_PATH": "./memory.db"
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
    "mcp_memory": {
      "command": "node",
      "args": ["./build/simple-index.js"],
      "cwd": "c:\\vscode\\mcp_memory"
    }
  }
}
```

### Configuração Automática (Windows)

Execute o script de configuração automática:

```powershell
# Configurar auto-start
.\auto-start.ps1

# Verificar status
.\quick-status.ps1

# Executar testes
.\run-test.ps1
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
│   ├── index.ts              # Servidor MCP original (SQLite)
│   ├── simple-index.ts       # Servidor MCP simplificado (JSON) ⭐
│   ├── memory/
│   │   └── MemoryManager.ts  # Gerenciador de memória SQLite
│   ├── tools/
│   │   └── index.ts          # Definições de ferramentas MCP
│   └── resources/
│       └── index.ts          # Definições de recursos MCP
├── scripts PowerShell/       # Scripts de gerenciamento
│   ├── run-test.ps1         # Teste de funcionalidades
│   ├── test-mcp-direct.ps1  # Teste direto do servidor
│   ├── quick-status.ps1     # Verificação de status
│   ├── server-controller.ps1 # Controle do servidor
│   └── auto-start.ps1       # Configuração de auto-start
├── .vscode/                 # Configuração VS Code
│   ├── tasks.json           # Tarefas do projeto
│   ├── settings.json        # Configurações
│   └── keybindings.json     # Atalhos
├── memory.json              # Dados persistentes
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

## Scripts de Gerenciamento

### Windows PowerShell

- `.\run-test.ps1` - Executa teste completo de funcionalidades
- `.\test-mcp-direct.ps1` - Testa comunicação direta com o servidor
- `.\quick-status.ps1` - Verifica status do servidor e dados
- `.\server-controller.ps1` - Inicia/para o servidor
- `.\auto-start.ps1` - Configura inicialização automática
- `.\test-persistence.ps1` - Monitora persistência em tempo real

### VS Code

- `Ctrl+Shift+P` → "MCP: Start Server" - Iniciar servidor
- `Ctrl+Shift+P` → "MCP: Test Memory" - Executar testes
- `Ctrl+Shift+P` → "MCP: Check Status" - Verificar status
- `F5` - Executar em modo debug

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

O MCP Memory Server oferece duas implementações:

### Servidor Principal (simple-index.ts) ⭐

- **JSON**: Armazenamento simples e confiável em `memory.json`
- **TypeScript SDK**: Implementação do protocolo MCP
- **Sincronização**: Operações síncronas de leitura/escrita
- **Simplicidade**: Código minimalista e fácil debugging

### Servidor Avançado (index.ts)

- **SQLite**: Para armazenamento mais robusto
- **Better SQLite3**: Operações de banco performáticas
- **UUID**: Identificadores únicos
- **Zod**: Validação de esquemas

### Tecnologias Utilizadas

- **Node.js**: Runtime JavaScript
- **TypeScript**: Linguagem de programação
- **MCP SDK**: Protocolo de contexto de modelo
- **PowerShell**: Scripts de automação Windows
- **VS Code**: Integração completa de desenvolvimento

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

## Status Atual ✅

### Implementado

- ✅ Servidor MCP funcional com persistência JSON
- ✅ Suite completa de testes PowerShell
- ✅ Auto-start no Windows
- ✅ Integração total com VS Code
- ✅ Scripts de gerenciamento e monitoramento
- ✅ Dashboard de status HTML
- ✅ Migração do servidor oficial MCP
- ✅ Verificação de persistência em tempo real

### Testado e Validado

- ✅ Criação e leitura de entidades
- ✅ Relacionamentos entre entidades
- ✅ Persistência em memory.json
- ✅ Carregamento automático na inicialização
- ✅ Integração com Claude Desktop

## Roadmap Futuro

- [ ] Interface web para visualização do grafo
- [ ] Suporte para importação/exportação de dados
- [ ] Integração com outros formatos de dados
- [ ] Métricas e analytics avançadas
- [ ] Backup automático e recuperação
- [ ] Suporte para múltiplos bancos de dados
- [ ] API REST para acesso externo
- [ ] Clustering e replicação
