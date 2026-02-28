// DST客户端日志解析器 - 使用轮询方式从日志中提取游戏状态

import { promises as fs } from "fs";
import { join } from "path";

/**
 * 实体信息
 */
export interface ParsedEntity {
  prefab: string;
  name: string;
  x: number;
  z: number;
  distance: number;
  notes: string;
}

/**
 * 背包物品
 */
export interface InventoryItem {
  prefab: string;
  name: string;
  stack: number;
}

/**
 * 解析后的游戏状态
 */
export interface ParsedGameState {
  timestamp: number;
  player: {
    health: number;
    hunger: number;
    sanity: number;
    position: { x: number; y: number; z: number };
  };
  world: {
    day: number;
    time: number;
  };
  entities: ParsedEntity[];
  inventory: InventoryItem[];
}

/**
 * DST日志解析器 - 使用轮询方式
 */
export class DSTLogParser {
  private logPath: string;
  private lastPosition: number = 0;
  private lastFileSize: number = 0;
  private latestState: ParsedGameState | null = null;
  private pollInterval: NodeJS.Timeout | null = null;
  private pollMs: number;

  constructor(logPath: string, pollMs: number = 100) {
    this.logPath = logPath;
    this.pollMs = pollMs;
  }

  /**
   * 启动日志轮询
   */
  async start(onUpdate: (state: ParsedGameState) => void): Promise<void> {
    // 检查日志文件是否存在
    try {
      await fs.access(this.logPath);
      const stats = await fs.stat(this.logPath);
      this.lastPosition = stats.size;
      this.lastFileSize = stats.size;

      // 解析文件中已存在的DST_AI_STATE行
      await this.parseExistingLogs(onUpdate);
    } catch {
      // 文件不存在，等待创建
      this.lastPosition = 0;
      this.lastFileSize = 0;
    }

    // 启动轮询
    this.pollInterval = setInterval(async () => {
      await this.checkAndUpdate(onUpdate);
    }, this.pollMs);

    console.log(`[LogParser] Polling log every ${this.pollMs}ms: ${this.logPath}`);
  }

  /**
   * 检查文件变化并更新
   */
  private async checkAndUpdate(onUpdate: (state: ParsedGameState) => void): Promise<void> {
    try {
      const stats = await fs.stat(this.logPath);

      // 只有文件大小变化时才读取
      if (stats.size === this.lastFileSize) {
        return;
      }

      this.lastFileSize = stats.size;
      await this.parseNewLogs(onUpdate);
    } catch (error) {
      // 文件可能被删除或暂时不可访问，忽略错误
    }
  }

  /**
   * 解析已存在的日志内容
   */
  private async parseExistingLogs(onUpdate: (state: ParsedGameState) => void): Promise<void> {
    try {
      const content = await fs.readFile(this.logPath, "utf-8");
      const lines = content.split("\n");
      let found = 0;
      for (const line of lines) {
        const state = this.parseStateLine(line);
        if (state) {
          this.latestState = state;
          onUpdate(state);
          found++;
        }
      }
      if (found > 0) {
        console.log(`[LogParser] Parsed ${found} existing states from log`);
      }
    } catch (error) {
      console.error("[LogParser] Error reading existing log:", error);
    }
  }

  /**
   * 停止轮询
   */
  async stop(): Promise<void> {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
  }

  /**
   * 解析新日志内容
   */
  private async parseNewLogs(onUpdate: (state: ParsedGameState) => void): Promise<void> {
    try {
      const content = await fs.readFile(this.logPath, "utf-8");
      const newContent = content.slice(this.lastPosition);
      this.lastPosition = content.length;

      // 查找DST_AI_STATE开头的行
      const lines = newContent.split("\n");
      for (const line of lines) {
        const state = this.parseStateLine(line);
        if (state) {
          this.latestState = state;
          onUpdate(state);
        }
      }
    } catch (error) {
      console.error("[LogParser] Error reading log:", error);
    }
  }

  /**
   * 解析单行状态
   */
  private parseStateLine(line: string): ParsedGameState | null {
    // 查找 DST_AI_STATE {"v":2,...}
    const match = line.match(/DST_AI_STATE (\{.+\})/);
    if (!match) return null;

    try {
      const data = JSON.parse(match[1]);

      // 解析实体列表
      const entities: ParsedEntity[] = [];
      if (Array.isArray(data.e)) {
        for (const ent of data.e) {
          entities.push({
            prefab: ent.p || ent.prefab || "unknown",
            name: ent.n || ent.name || ent.p || "unknown",
            x: ent.x || 0,
            z: ent.z || 0,
            distance: ent.d || ent.distance || 0,
            notes: ent.notes || "",
          });
        }
      }

      // 解析背包物品
      const inventory: InventoryItem[] = [];
      if (Array.isArray(data.i)) {
        for (const item of data.i) {
          inventory.push({
            prefab: item.p || item.prefab || "unknown",
            name: item.n || item.name || item.p || "unknown",
            stack: item.s || item.stack || 1,
          });
        }
      }

      return {
        timestamp: Date.now(),
        player: {
          health: data.hp || 1,
          hunger: data.hu || 1,
          sanity: data.sa || 1,
          position: { x: data.x || 0, y: 0, z: data.z || 0 },
        },
        world: {
          day: data.day || 0,
          time: data.time || 0,
        },
        entities,
        inventory,
      };
    } catch (e) {
      // 解析失败，可能是旧格式，尝试简单解析
      try {
        const data = JSON.parse(match[1]);
        return {
          timestamp: Date.now(),
          player: {
            health: data.hp || 1,
            hunger: data.hu || 1,
            sanity: data.sa || 1,
            position: { x: data.x || 0, y: 0, z: data.z || 0 },
          },
          world: {
            day: data.day || 0,
            time: data.time || 0,
          },
          entities: [],
          inventory: [],
        };
      } catch {
        return null;
      }
    }
  }

  /**
   * 获取最新状态
   */
  getLatestState(): ParsedGameState | null {
    return this.latestState;
  }
}

/**
 * 查找DST客户端日志文件
 */
export async function findClientLogPath(): Promise<string | null> {
  const basePaths = [
    join(process.env.USERPROFILE || "", "Documents", "Klei", "DoNotStarveTogether"),
    join(process.env.USERPROFILE || "", "Documents", "Klei"),
  ];

  // 首先检查根目录下的client_log.txt
  const rootLog = join(process.env.USERPROFILE || "", "Documents", "Klei", "DoNotStarveTogether", "client_log.txt");
  try {
    await fs.access(rootLog);
    return rootLog;
  } catch {
    // 继续查找其他位置
  }

  for (const basePath of basePaths) {
    try {
      const dirs = await fs.readdir(basePath);
      for (const dir of dirs) {
        // 查找数字目录（用户ID）
        if (/^\d+$/.test(dir)) {
          const logPath = join(basePath, dir, "client_log.txt");
          try {
            await fs.access(logPath);
            return logPath;
          } catch {
            continue;
          }
        }
      }
    } catch {
      continue;
    }
  }

  return null;
}
