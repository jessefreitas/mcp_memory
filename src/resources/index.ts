import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { ListResourcesRequestSchema, ReadResourceRequestSchema } from "@modelcontextprotocol/sdk/types.js";
import { MemoryManager } from "../memory/MemoryManager.js";

export function setupResources(server: Server, memoryManager: MemoryManager) {
  // List available resources
  server.setRequestHandler(ListResourcesRequestSchema, async () => {
    return {
      resources: [
        {
          uri: "memory://graph",
          name: "Knowledge Graph",
          description: "The complete knowledge graph with all entities and relations",
          mimeType: "application/json"
        },
        {
          uri: "memory://entities",
          name: "Entities",
          description: "All entities in the knowledge graph",
          mimeType: "application/json"
        },
        {
          uri: "memory://relations",
          name: "Relations",
          description: "All relations in the knowledge graph",
          mimeType: "application/json"
        },
        {
          uri: "memory://stats",
          name: "Memory Statistics",
          description: "Statistics about the knowledge graph",
          mimeType: "application/json"
        }
      ]
    };
  });

  // Read resource content
  server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
    const { uri } = request.params;

    try {
      switch (uri) {
        case "memory://graph": {
          const graph = await memoryManager.readGraph();
          return {
            contents: [{
              uri,
              mimeType: "application/json",
              text: JSON.stringify(graph, null, 2)
            }]
          };
        }

        case "memory://entities": {
          const graph = await memoryManager.readGraph();
          return {
            contents: [{
              uri,
              mimeType: "application/json",
              text: JSON.stringify(graph.entities, null, 2)
            }]
          };
        }

        case "memory://relations": {
          const graph = await memoryManager.readGraph();
          return {
            contents: [{
              uri,
              mimeType: "application/json",
              text: JSON.stringify(graph.relations, null, 2)
            }]
          };
        }

        case "memory://stats": {
          const graph = await memoryManager.readGraph();
          
          const entityTypes = graph.entities.reduce((acc, e) => {
            acc[e.type] = (acc[e.type] || 0) + 1;
            return acc;
          }, {} as Record<string, number>);
          
          const relationTypes = graph.relations.reduce((acc, r) => {
            acc[r.relationType] = (acc[r.relationType] || 0) + 1;
            return acc;
          }, {} as Record<string, number>);

          const stats = {
            totalEntities: graph.entities.length,
            totalRelations: graph.relations.length,
            entityTypes,
            relationTypes,
            lastUpdated: new Date().toISOString()
          };

          return {
            contents: [{
              uri,
              mimeType: "application/json",
              text: JSON.stringify(stats, null, 2)
            }]
          };
        }

        default:
          throw new Error(`Unknown resource: ${uri}`);
      }
    } catch (error) {
      throw new Error(`Failed to read resource ${uri}: ${error instanceof Error ? error.message : String(error)}`);
    }
  });
}