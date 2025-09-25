# Exemplo de Uso do MCP Memory Server

Este documento demonstra como usar o MCP Memory Server para gerenciar entidades e relacionamentos.

## Testando o Servidor

### 1. Iniciar o Servidor

```bash
npm run build
node build/index.js
```

### 2. Configuração no Claude Desktop

Adicione ao seu arquivo de configuração do Claude Desktop (`%APPDATA%\Claude\claude_desktop_config.json` no Windows):

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

### 3. Ferramentas Disponíveis

O servidor fornece as seguintes ferramentas MCP:

- `mcp_memory_create_entities` - Criar múltiplas entidades
- `mcp_memory_add_observations` - Adicionar observações a entidades
- `mcp_memory_delete_entities` - Deletar entidades
- `mcp_memory_delete_observations` - Deletar observações específicas
- `mcp_memory_create_relations` - Criar relacionamentos entre entidades
- `mcp_memory_delete_relations` - Deletar relacionamentos
- `mcp_memory_search_nodes` - Buscar entidades e relacionamentos
- `mcp_memory_open_nodes` - Abrir entidades específicas por nome
- `mcp_memory_read_graph` - Ler todo o grafo de conhecimento

### 4. Exemplo de Uso

Uma vez conectado ao Claude Desktop, você pode usar comandos como:

- "Crie uma entidade chamada 'João' do tipo 'pessoa' com a observação 'trabalha como desenvolvedor'"
- "Crie um relacionamento onde 'João' 'trabalha_em' 'Empresa XYZ'"
- "Busque por todas as entidades relacionadas a 'desenvolvimento'"
- "Mostre-me todo o grafo de conhecimento"

### 5. Recursos Disponíveis

O servidor também expõe recursos MCP:

- `memory://graph` - Todo o grafo de conhecimento
- `memory://entities` - Todas as entidades
- `memory://relations` - Todos os relacionamentos
- `memory://stats` - Estatísticas do grafo

## Estrutura do Banco de Dados

O servidor usa SQLite com as seguintes tabelas:

### Tabela `entities`

- `id` - UUID único
- `name` - Nome da entidade
- `type` - Tipo da entidade
- `observations` - JSON com observações
- `created_at` - Data de criação
- `updated_at` - Data de atualização

### Tabela `relations`

- `id` - UUID único
- `from_entity` - Nome da entidade origem
- `to_entity` - Nome da entidade destino
- `relation_type` - Tipo do relacionamento
- `created_at` - Data de criação

## Desenvolvimento

Para contribuir com o projeto:

1. Clone o repositório
2. Instale as dependências: `npm install`
3. Compile o TypeScript: `npm run build`
4. Execute os testes: `npm test` (quando disponível)
5. Execute o servidor: `node build/index.js`

O servidor está configurado para usar stdio para comunicação MCP, o que é compatível com a maioria dos clientes MCP.
