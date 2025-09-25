import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { CallToolRequestSchema, ListToolsRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import { MemoryManager } from "../memory/MemoryManager.js";

// Tool schemas
const CreateEntitiesSchema = z.object({
  entities: z.array(z.object({
    name: z.string().describe("The name of the entity"),
    entityType: z.string().describe("The type of the entity"),
    observations: z.array(z.string()).describe("An array of observation contents associated with the entity")
  }))
});

const AddObservationsSchema = z.object({
  observations: z.array(z.object({
    entityName: z.string().describe("The name of the entity to add the observations to"),
    contents: z.array(z.string()).describe("An array of observation contents to add")
  }))
});

const DeleteEntitiesSchema = z.object({
  entityNames: z.array(z.string()).describe("An array of entity names to delete")
});

const DeleteObservationsSchema = z.object({
  deletions: z.array(z.object({
    entityName: z.string().describe("The name of the entity containing the observations"),
    observations: z.array(z.string()).describe("An array of observations to delete")
  }))
});

const CreateRelationsSchema = z.object({
  relations: z.array(z.object({
    from: z.string().describe("The name of the entity where the relation starts"),
    to: z.string().describe("The name of the entity where the relation ends"),
    relationType: z.string().describe("The type of the relation")
  }))
});

const DeleteRelationsSchema = z.object({
  relations: z.array(z.object({
    from: z.string().describe("The name of the entity where the relation starts"),
    to: z.string().describe("The name of the entity where the relation ends"),
    relationType: z.string().describe("The type of the relation")
  }))
});

const SearchNodesSchema = z.object({
  query: z.string().describe("The search query to match against entity names, types, and observation content")
});

const OpenNodesSchema = z.object({
  names: z.array(z.string()).describe("An array of entity names to retrieve")
});

export function setupTools(server: Server, memoryManager: MemoryManager) {
  // Create multiple new entities in the knowledge graph
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    try {
      switch (name) {
        case "mcp_memory_create_entities": {
          const parsed = CreateEntitiesSchema.parse(args);
          const entities = await memoryManager.createEntities(parsed.entities);
          
          return {
            content: [{
              type: "text",
              text: `Created ${entities.length} entities: ${entities.map(e => e.name).join(", ")}`
            }]
          };
        }

        case "mcp_memory_add_observations": {
          const parsed = AddObservationsSchema.parse(args);
          await memoryManager.addObservations(parsed.observations);
          
          return {
            content: [{
              type: "text",
              text: `Added observations to ${parsed.observations.length} entities`
            }]
          };
        }

        case "mcp_memory_delete_entities": {
          const parsed = DeleteEntitiesSchema.parse(args);
          await memoryManager.deleteEntities(parsed.entityNames);
          
          return {
            content: [{
              type: "text",
              text: `Deleted entities: ${parsed.entityNames.join(", ")}`
            }]
          };
        }

        case "mcp_memory_delete_observations": {
          const parsed = DeleteObservationsSchema.parse(args);
          await memoryManager.deleteObservations(parsed.deletions);
          
          return {
            content: [{
              type: "text",
              text: `Deleted observations from ${parsed.deletions.length} entities`
            }]
          };
        }

        case "mcp_memory_create_relations": {
          const parsed = CreateRelationsSchema.parse(args);
          const relations = await memoryManager.createRelations(parsed.relations);
          
          return {
            content: [{
              type: "text",
              text: `Created ${relations.length} relations: ${relations.map(r => `${r.from} -> ${r.to} (${r.relationType})`).join(", ")}`
            }]
          };
        }

        case "mcp_memory_delete_relations": {
          const parsed = DeleteRelationsSchema.parse(args);
          await memoryManager.deleteRelations(parsed.relations);
          
          return {
            content: [{
              type: "text",
              text: `Deleted ${parsed.relations.length} relations`
            }]
          };
        }

        case "mcp_memory_search_nodes": {
          const parsed = SearchNodesSchema.parse(args);
          const result = await memoryManager.searchNodes(parsed.query);
          
          const summary = `Found ${result.entities.length} entities and ${result.relations.length} relations matching "${parsed.query}"`;
          const entityList = result.entities.map(e => `- ${e.name} (${e.type}): ${e.observations.length} observations`).join("\n");
          const relationList = result.relations.map(r => `- ${r.from} -> ${r.to} (${r.relationType})`).join("\n");
          
          const responseText = [
            summary,
            result.entities.length > 0 ? `\nEntities:\n${entityList}` : "",
            result.relations.length > 0 ? `\nRelations:\n${relationList}` : ""
          ].filter(Boolean).join("");

          return {
            content: [{
              type: "text",
              text: responseText
            }]
          };
        }

        case "mcp_memory_open_nodes": {
          const parsed = OpenNodesSchema.parse(args);
          const entities = await memoryManager.openNodes(parsed.names);
          
          const responseText = entities.length > 0
            ? entities.map(e => `${e.name} (${e.type}):\n  Observations: ${e.observations.join(", ")}\n  Created: ${e.createdAt.toISOString()}\n  Updated: ${e.updatedAt.toISOString()}`).join("\n\n")
            : "No entities found with the specified names.";

          return {
            content: [{
              type: "text",
              text: responseText
            }]
          };
        }

        case "mcp_memory_read_graph": {
          const graph = await memoryManager.readGraph();
          
          const summary = `Knowledge Graph Overview:\n- ${graph.entities.length} entities\n- ${graph.relations.length} relations`;
          
          const entityTypes = graph.entities.reduce((acc, e) => {
            acc[e.type] = (acc[e.type] || 0) + 1;
            return acc;
          }, {} as Record<string, number>);
          
          const relationTypes = graph.relations.reduce((acc, r) => {
            acc[r.relationType] = (acc[r.relationType] || 0) + 1;
            return acc;
          }, {} as Record<string, number>);
          
          const typesSummary = `\nEntity Types:\n${Object.entries(entityTypes).map(([type, count]) => `- ${type}: ${count}`).join("\n")}`;
          const relationsSummary = `\nRelation Types:\n${Object.entries(relationTypes).map(([type, count]) => `- ${type}: ${count}`).join("\n")}`;
          
          return {
            content: [{
              type: "text",
              text: summary + typesSummary + relationsSummary
            }]
          };
        }

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    } catch (error) {
      return {
        content: [{
          type: "text",
          text: `Error: ${error instanceof Error ? error.message : String(error)}`
        }],
        isError: true
      };
    }
  });

  // Register tools with their schemas
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
                    name: { type: "string", description: "The name of the entity" },
                    entityType: { type: "string", description: "The type of the entity" },
                    observations: {
                      type: "array",
                      items: { type: "string" },
                      description: "An array of observation contents associated with the entity"
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
          name: "mcp_memory_add_observations",
          description: "Add new observations to existing entities in the knowledge graph",
          inputSchema: {
            type: "object",
            properties: {
              observations: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    entityName: { type: "string", description: "The name of the entity to add the observations to" },
                    contents: {
                      type: "array",
                      items: { type: "string" },
                      description: "An array of observation contents to add"
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
          name: "mcp_memory_delete_entities",
          description: "Delete multiple entities and their associated relations from the knowledge graph",
          inputSchema: {
            type: "object",
            properties: {
              entityNames: {
                type: "array",
                items: { type: "string" },
                description: "An array of entity names to delete"
              }
            },
            required: ["entityNames"]
          }
        },
        {
          name: "mcp_memory_delete_observations",
          description: "Delete specific observations from entities in the knowledge graph",
          inputSchema: {
            type: "object",
            properties: {
              deletions: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    entityName: { type: "string", description: "The name of the entity containing the observations" },
                    observations: {
                      type: "array",
                      items: { type: "string" },
                      description: "An array of observations to delete"
                    }
                  },
                  required: ["entityName", "observations"]
                }
              }
            },
            required: ["deletions"]
          }
        },
        {
          name: "mcp_memory_create_relations",
          description: "Create multiple new relations between entities in the knowledge graph. Relations should be in active voice",
          inputSchema: {
            type: "object",
            properties: {
              relations: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    from: { type: "string", description: "The name of the entity where the relation starts" },
                    to: { type: "string", description: "The name of the entity where the relation ends" },
                    relationType: { type: "string", description: "The type of the relation" }
                  },
                  required: ["from", "to", "relationType"]
                }
              }
            },
            required: ["relations"]
          }
        },
        {
          name: "mcp_memory_delete_relations",
          description: "Delete multiple relations from the knowledge graph",
          inputSchema: {
            type: "object",
            properties: {
              relations: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    from: { type: "string", description: "The name of the entity where the relation starts" },
                    to: { type: "string", description: "The name of the entity where the relation ends" },
                    relationType: { type: "string", description: "The type of the relation" }
                  },
                  required: ["from", "to", "relationType"]
                }
              }
            },
            required: ["relations"]
          }
        },
        {
          name: "mcp_memory_search_nodes",
          description: "Search for nodes in the knowledge graph based on a query",
          inputSchema: {
            type: "object",
            properties: {
              query: { type: "string", description: "The search query to match against entity names, types, and observation content" }
            },
            required: ["query"]
          }
        },
        {
          name: "mcp_memory_open_nodes",
          description: "Open specific nodes in the knowledge graph by their names",
          inputSchema: {
            type: "object",
            properties: {
              names: {
                type: "array",
                items: { type: "string" },
                description: "An array of entity names to retrieve"
              }
            },
            required: ["names"]
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
        }
      ]
    };
  });
}