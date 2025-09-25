import fs from "fs-extra";
import path from "path";
import sqlite3 from "sqlite3";
import { v4 as uuidv4 } from "uuid";

export interface Entity {
  id: string;
  name: string;
  type: string;
  observations: string[];
  createdAt: Date;
  updatedAt: Date;
}

export interface Relation {
  id: string;
  from: string;
  to: string;
  relationType: string;
  createdAt: Date;
}

export interface SearchResult {
  entities: Entity[];
  relations: Relation[];
}

export class MemoryManager {
  private db: sqlite3.Database | null = null;
  private readonly dbPath: string;

  constructor(dbPath: string) {
    this.dbPath = dbPath;
  }

  async initialize(): Promise<void> {
    try {
      // Ensure database directory exists
      const dbDir = path.dirname(this.dbPath);
      await fs.ensureDir(dbDir);

      // Initialize SQLite database
      this.db = new sqlite3.Database(this.dbPath);
      
      // Enable foreign keys and create tables
      await this.runQuery("PRAGMA foreign_keys = ON");
      await this.createTables();
      
      console.error("Memory database initialized at:", this.dbPath);
    } catch (error) {
      console.error("Failed to initialize memory database:", error);
      throw error;
    }
  }

  private async createTables(): Promise<void> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    // Create entities table
    await this.runQuery(`
      CREATE TABLE IF NOT EXISTS entities (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        observations TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Create relations table
    await this.runQuery(`
      CREATE TABLE IF NOT EXISTS relations (
        id TEXT PRIMARY KEY,
        from_entity TEXT NOT NULL,
        to_entity TEXT NOT NULL,
        relation_type TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (from_entity) REFERENCES entities (name),
        FOREIGN KEY (to_entity) REFERENCES entities (name),
        UNIQUE(from_entity, to_entity, relation_type)
      )
    `);

    // Create indexes for better performance
    await this.runQuery(`
      CREATE INDEX IF NOT EXISTS idx_entities_name ON entities(name);
    `);
    await this.runQuery(`
      CREATE INDEX IF NOT EXISTS idx_entities_type ON entities(type);
    `);
    await this.runQuery(`
      CREATE INDEX IF NOT EXISTS idx_relations_from ON relations(from_entity);
    `);
    await this.runQuery(`
      CREATE INDEX IF NOT EXISTS idx_relations_to ON relations(to_entity);
    `);
    await this.runQuery(`
      CREATE INDEX IF NOT EXISTS idx_relations_type ON relations(relation_type);
    `);
  }

  private runQuery(sql: string, params?: any[]): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("Database not initialized"));
        return;
      }
      
      this.db.run(sql, params || [], function(err) {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }

  private queryAll(sql: string, params?: any[]): Promise<any[]> {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("Database not initialized"));
        return;
      }
      
      this.db.all(sql, params || [], (err, rows) => {
        if (err) {
          reject(err);
        } else {
          resolve(rows);
        }
      });
    });
  }

  private queryGet(sql: string, params?: any[]): Promise<any> {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error("Database not initialized"));
        return;
      }
      
      this.db.get(sql, params || [], (err, row) => {
        if (err) {
          reject(err);
        } else {
          resolve(row);
        }
      });
    });
  }

  // Entity operations
  async createEntities(entities: Array<{ name: string; entityType: string; observations: string[] }>): Promise<Entity[]> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    const createdEntities: Entity[] = [];
    
    for (const entityData of entities) {
      const id = uuidv4();
      const observationsJson = JSON.stringify(entityData.observations);
      
      await this.runQuery(`
        INSERT OR REPLACE INTO entities (id, name, type, observations, updated_at)
        VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
      `, [id, entityData.name, entityData.entityType, observationsJson]);
      
      // Fetch the created entity
      const entity = await this.getEntityByName(entityData.name);
      if (entity) {
        createdEntities.push(entity);
      }
    }

    return createdEntities;
  }

  async addObservations(observations: Array<{ entityName: string; contents: string[] }>): Promise<void> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    for (const obs of observations) {
      const entity = await this.getEntityByName(obs.entityName);
      if (entity) {
        const currentObservations = entity.observations || [];
        const newObservations = [...currentObservations, ...obs.contents];
        await this.runQuery(`
          UPDATE entities 
          SET observations = ?, updated_at = CURRENT_TIMESTAMP
          WHERE name = ?
        `, [JSON.stringify(newObservations), obs.entityName]);
      }
    }
  }

  async deleteEntities(entityNames: string[]): Promise<void> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    for (const name of entityNames) {
      await this.runQuery("DELETE FROM relations WHERE from_entity = ? OR to_entity = ?", [name, name]);
      await this.runQuery("DELETE FROM entities WHERE name = ?", [name]);
    }
  }

  async deleteObservations(deletions: Array<{ entityName: string; observations: string[] }>): Promise<void> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    for (const deletion of deletions) {
      const entity = await this.getEntityByName(deletion.entityName);
      if (entity) {
        const currentObservations = entity.observations || [];
        const filteredObservations = currentObservations.filter(
          obs => !deletion.observations.includes(obs)
        );
        await this.runQuery(`
          UPDATE entities 
          SET observations = ?, updated_at = CURRENT_TIMESTAMP
          WHERE name = ?
        `, [JSON.stringify(filteredObservations), deletion.entityName]);
      }
    }
  }

  // Relation operations
  async createRelations(relations: Array<{ from: string; to: string; relationType: string }>): Promise<Relation[]> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    const createdRelations: Relation[] = [];
    
    for (const relationData of relations) {
      const id = uuidv4();
      await this.runQuery(`
        INSERT OR REPLACE INTO relations (id, from_entity, to_entity, relation_type)
        VALUES (?, ?, ?, ?)
      `, [id, relationData.from, relationData.to, relationData.relationType]);
      
      const relation: Relation = {
        id,
        from: relationData.from,
        to: relationData.to,
        relationType: relationData.relationType,
        createdAt: new Date()
      };
      
      createdRelations.push(relation);
    }

    return createdRelations;
  }

  async deleteRelations(relations: Array<{ from: string; to: string; relationType: string }>): Promise<void> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    for (const relation of relations) {
      await this.runQuery(`
        DELETE FROM relations 
        WHERE from_entity = ? AND to_entity = ? AND relation_type = ?
      `, [relation.from, relation.to, relation.relationType]);
    }
  }

  // Search and query operations
  async searchNodes(query: string): Promise<SearchResult> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    const searchQuery = `%${query.toLowerCase()}%`;
    
    const entityRows = await this.queryAll(`
      SELECT * FROM entities 
      WHERE LOWER(name) LIKE ? 
         OR LOWER(type) LIKE ? 
         OR LOWER(observations) LIKE ?
    `, [searchQuery, searchQuery, searchQuery]);

    const relationRows = await this.queryAll(`
      SELECT * FROM relations 
      WHERE LOWER(from_entity) LIKE ? 
         OR LOWER(to_entity) LIKE ? 
         OR LOWER(relation_type) LIKE ?
    `, [searchQuery, searchQuery, searchQuery]);

    const entities: Entity[] = entityRows.map(row => ({
      id: row.id,
      name: row.name,
      type: row.type,
      observations: JSON.parse(row.observations),
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    }));

    const relations: Relation[] = relationRows.map(row => ({
      id: row.id,
      from: row.from_entity,
      to: row.to_entity,
      relationType: row.relation_type,
      createdAt: new Date(row.created_at)
    }));

    return { entities, relations };
  }

  async openNodes(names: string[]): Promise<Entity[]> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    const entities: Entity[] = [];

    for (const name of names) {
      const row = await this.queryGet("SELECT * FROM entities WHERE name = ?", [name]);
      if (row) {
        entities.push({
          id: row.id,
          name: row.name,
          type: row.type,
          observations: JSON.parse(row.observations),
          createdAt: new Date(row.created_at),
          updatedAt: new Date(row.updated_at)
        });
      }
    }

    return entities;
  }

  async readGraph(): Promise<{ entities: Entity[]; relations: Relation[] }> {
    if (!this.db) {
      throw new Error("Database not initialized");
    }

    const entityRows = await this.queryAll("SELECT * FROM entities ORDER BY updated_at DESC", []);
    const relationRows = await this.queryAll("SELECT * FROM relations ORDER BY created_at DESC", []);

    const entities: Entity[] = entityRows.map(row => ({
      id: row.id,
      name: row.name,
      type: row.type,
      observations: JSON.parse(row.observations),
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    }));

    const relations: Relation[] = relationRows.map(row => ({
      id: row.id,
      from: row.from_entity,
      to: row.to_entity,
      relationType: row.relation_type,
      createdAt: new Date(row.created_at)
    }));

    return { entities, relations };
  }

  private async getEntityByName(name: string): Promise<Entity | null> {
    if (!this.db) {
      return null;
    }

    const row = await this.queryGet("SELECT * FROM entities WHERE name = ?", [name]);

    if (!row) {
      return null;
    }

    return {
      id: row.id,
      name: row.name,
      type: row.type,
      observations: JSON.parse(row.observations),
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at)
    };
  }

  async close(): Promise<void> {
    if (this.db) {
      this.db.close();
      this.db = null;
    }
  }
}