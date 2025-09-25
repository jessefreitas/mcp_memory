#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListResourcesRequestSchema,
  ListToolsRequestSchema,
  ReadResourceRequestSchema
} from "@modelcontextprotocol/sdk/types.js";
import fs from "fs/promises";

// Simple in-memory storage with JSON persistence
class SimpleMemoryManager {
  public memoryPath: string;
  private memory: any = { entities: [], relations: [] };

  constructor(memoryPath: string = "./memory.json") {
    this.memoryPath = memoryPath;
  }

  async initialize() {
    try {
      // Try to load existing memory
      const data = await fs.readFile(this.memoryPath, 'utf-8');
      this.memory = JSON.parse(data);
      console.error(`Memory loaded from ${this.memoryPath}`);
    } catch (error) {
      // File doesn't exist or is invalid, start with empty memory
      this.memory = { entities: [], relations: [] };
      console.error(`Starting with empty memory at ${this.memoryPath}`);
    }
  }

  async save() {
    try {
      await fs.writeFile(this.memoryPath, JSON.stringify(this.memory, null, 2));
      console.error(`Memory saved to ${this.memoryPath}`);
    } catch (error) {
      console.error("Failed to save memory:", error);
    }
  }

  createEntities(entities: any[]) {
    entities.forEach(entity => {
      // Remove existing entity with same name
      this.memory.entities = this.memory.entities.filter((e: any) => e.name !== entity.name);
      
      // Add new entity
      this.memory.entities.push({
        type: "entity",
        name: entity.name,
        entityType: entity.entityType,
        observations: entity.observations || []
      });
    });
    
    this.save();
    return { success: true, count: entities.length };
  }

  readGraph() {
    return {
      entities: this.memory.entities,
      relations: this.memory.relations
    };
  }

  searchNodes(query: string) {
    const lowerQuery = query.toLowerCase();
    const matchingEntities = this.memory.entities.filter((entity: any) => 
      entity.name.toLowerCase().includes(lowerQuery) ||
      entity.entityType.toLowerCase().includes(lowerQuery) ||
      entity.observations.some((obs: string) => obs.toLowerCase().includes(lowerQuery))
    );

    return {
      entities: matchingEntities,
      relations: this.memory.relations.filter((rel: any) => 
        matchingEntities.some((e: any) => e.name === rel.from || e.name === rel.to)
      )
    };
  }

  addObservations(observations: any[]) {
    observations.forEach(obs => {
      const entity = this.memory.entities.find((e: any) => e.name === obs.entityName);
      if (entity) {
        entity.observations = [...new Set([...entity.observations, ...obs.contents])];
      }
    });
    
    this.save();
    return { success: true };
  }

  createRelations(relations: any[]) {
    relations.forEach(rel => {
      this.memory.relations.push({
        from: rel.from,
        to: rel.to,
        relationType: rel.relationType
      });
    });
    
    this.save();
    return { success: true, count: relations.length };
  }
}

// Create server
const server = new Server(
  {
    name: "mcp-memory-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
      resources: {},
    },
  }
);

// Initialize memory manager
const memoryManager = new SimpleMemoryManager(
  process.env.MCP_MEMORY_FILE || "./memory.json"
);

// Setup tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "mcp_memory_create_entities",
        description: "Create multiple new entities in the knowledge graph",
        inputSchema: {
          type: "object",
          properties: {
            entities: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  name: { type: "string" },
                  entityType: { type: "string" },
                  observations: {
                    type: "array",
                    items: { type: "string" }
                  }
                },
                required: ["name", "entityType", "observations"]
              }
            }
          },
          required: ["entities"]
        }
      },
      {
        name: "mcp_memory_read_graph",
        description: "Read the entire knowledge graph",
        inputSchema: {
          type: "object",
          properties: {},
          additionalProperties: false
        }
      },
      {
        name: "mcp_memory_search_nodes",
        description: "Search for nodes in the knowledge graph",
        inputSchema: {
          type: "object",
          properties: {
            query: { type: "string" }
          },
          required: ["query"]
        }
      },
      {
        name: "mcp_memory_add_observations",
        description: "Add observations to existing entities",
        inputSchema: {
          type: "object",
          properties: {
            observations: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  entityName: { type: "string" },
                  contents: {
                    type: "array",
                    items: { type: "string" }
                  }
                },
                required: ["entityName", "contents"]
              }
            }
          },
          required: ["observations"]
        }
      },
      {
        name: "mcp_memory_create_relations",
        description: "Create relations between entities",
        inputSchema: {
          type: "object",
          properties: {
            relations: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  from: { type: "string" },
                  to: { type: "string" },
                  relationType: { type: "string" }
                },
                required: ["from", "to", "relationType"]
              }
            }
          },
          required: ["relations"]
        }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "mcp_memory_create_entities":
        const createResult = memoryManager.createEntities((args as any)?.entities || []);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(createResult, null, 2)
            }
          ]
        };

      case "mcp_memory_read_graph":
        const graph = memoryManager.readGraph();
        return {
          content: [
            {
              type: "text", 
              text: JSON.stringify(graph, null, 2)
            }
          ]
        };

      case "mcp_memory_search_nodes":
        const searchResult = memoryManager.searchNodes((args as any)?.query || "");
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(searchResult, null, 2)
            }
          ]
        };

      case "mcp_memory_add_observations":
        const addResult = memoryManager.addObservations((args as any)?.observations || []);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(addResult, null, 2)
            }
          ]
        };

      case "mcp_memory_create_relations":
        const relResult = memoryManager.createRelations((args as any)?.relations || []);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(relResult, null, 2)
            }
          ]
        };

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error instanceof Error ? error.message : String(error)}`
        }
      ],
      isError: true
    };
  }
});

// Setup resources (memory status)
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "memory://status",
        name: "Memory Status",
        description: "Current status of the memory graph",
        mimeType: "application/json"
      }
    ]
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;
  
  if (uri === "memory://status") {
    const graph = memoryManager.readGraph();
    const status = {
      entityCount: graph.entities.length,
      relationCount: graph.relations.length,
      memoryFile: memoryManager.memoryPath
    };
    
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(status, null, 2)
        }
      ]
    };
  }
  
  throw new Error(`Unknown resource: ${uri}`);
});

// Start server
async function main() {
  try {
    await memoryManager.initialize();
    
    const transport = new StdioServerTransport();
    await server.connect(transport);
    
    console.error("Simple MCP Memory Server running on stdio");
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
}

main();