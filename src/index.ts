#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { MemoryManager } from "./memory/MemoryManager.js";
import { setupResources } from "./resources/index.js";
import { setupTools } from "./tools/index.js";

class MCPMemoryServer {
  private server: Server;
  private memoryManager: MemoryManager;

  constructor() {
    this.server = new Server(
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

    // Initialize memory manager with default database path
    const dbPath = process.env.MCP_MEMORY_DB_PATH || "./memory.db";
    this.memoryManager = new MemoryManager(dbPath);
  }

  async start() {
    try {
      // Initialize memory manager
      await this.memoryManager.initialize();

      // Setup tools and resources
      setupTools(this.server, this.memoryManager);
      setupResources(this.server, this.memoryManager);

      // Setup transport
      const transport = new StdioServerTransport();
      await this.server.connect(transport);

      console.error("MCP Memory Server running on stdio");
    } catch (error) {
      console.error("Failed to start MCP Memory Server:", error);
      process.exit(1);
    }
  }

  async stop() {
    await this.memoryManager.close();
  }
}

// Handle graceful shutdown
const server = new MCPMemoryServer();

process.on("SIGINT", async () => {
  console.error("Received SIGINT, shutting down gracefully...");
  await server.stop();
  process.exit(0);
});

process.on("SIGTERM", async () => {
  console.error("Received SIGTERM, shutting down gracefully...");
  await server.stop();
  process.exit(0);
});

// Start the server
server.start().catch((error) => {
  console.error("Unhandled error:", error);
  process.exit(1);
});