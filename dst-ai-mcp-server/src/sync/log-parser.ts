// DST客户端日志解析器 - 从日志中提取游戏状态

import { promises as fs } from "fs";
import { join } from "path";
import { watch } from "chokidar";

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
  };
}

/**
 * DST日志解析器
 */
export class DSTLogParser {
  private logPath: string;
  private lastPosition: number = 0;
  private latestState: ParsedGameState | null = null;
  private watcher: ReturnType<typeof watch> | null = null;

  constructor(logPath: string) {
    this.logPath = logPath;
  }

  /**
   * 启动日志监听
   */
  async start(onUpdate: (state: ParsedGameState) => void): Promise<void> {
    // 检查日志文件是否存在
    try {
      await fs.access(this.logPath);
      // 获取文件大小
      const stats = await fs.stat(this.logPath);
      this.lastPosition = stats.size;

      // 解析文件中已存在的DST_AI_STATE行
      await this.parseExistingLogs(onUpdate);
    } catch {
      // 文件不存在，等待创建
      this.lastPosition = 0;
    }

    // 创建监听器
    this.watcher = watch(this.logPath, {
      persistent: true,
      ignoreInitial: true,
    });

    this.watcher.on("change", () => this.parseNewLogs(onUpdate));
    this.watcher.on("error", (error) => console.error("[LogParser] Watcher error:", error));

    console.log(`[LogParser] Watching log: ${this.logPath}`);
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
   * 停止监听
   */
  async stop(): Promise<void> {
    if (this.watcher) {
      await this.watcher.close();
      this.watcher = null;
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
    // 查找 DST_AI_STATE {"v":1,...}
    const match = line.match(/DST_AI_STATE (\{.+\})/);
    if (!match) return null;

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
        },
      };
    } catch {
      return null;
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
