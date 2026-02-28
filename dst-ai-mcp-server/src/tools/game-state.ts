// MCP工具：get_game_state - 获取当前游戏状态

import { StateCache } from "../sync/state-cache.js";
import { FileWatcher } from "../sync/file-watcher.js";
import { GameState } from "../types/game.js";
import { DSTLogParser, findClientLogPath, type ParsedGameState } from "../sync/log-parser.js";

/**
 * 获取游戏状态工具
 */
export class GameStateTool {
  private cache: StateCache;
  private watcher: FileWatcher;
  private logParser: DSTLogParser | null = null;
  private logState: ParsedGameState | null = null;

  constructor(cache: StateCache, watcher: FileWatcher) {
    this.cache = cache;
    this.watcher = watcher;
    this.initLogParser();
  }

  /**
   * 初始化日志解析器
   */
  private initLogParser(): void {
    findClientLogPath().then(logPath => {
      if (logPath) {
        this.logParser = new DSTLogParser(logPath);
        this.logParser.start((state) => {
          this.logState = state;
        });
        console.log("[GameStateTool] Log parser started:", logPath);
      }
    });
  }

  /**
   * MCP工具定义
   */
  get definition() {
    return {
      name: "get_game_state",
      description: "获取当前饥荒游戏状态的完整快照，包括玩家状态、世界状态、附近实体和背包物品。",
      inputSchema: {
        type: "object",
        properties: {
          allow_expired: {
            type: "boolean",
            description: "如果为true，允许返回过期的缓存状态；如果为false，只有最新状态才会返回",
            default: false,
          },
        },
      },
    } as const;
  }

  /**
   * 执行工具
   */
  async execute(args: { allow_expired?: boolean } = {}): Promise<{
    success: boolean;
    timestamp: number | null;
    cacheAge: number | null;
    state: GameState | null;
    message?: string;
  }> {
    const allowExpired = args.allow_expired ?? false;

    // 优先使用日志解析器的数据
    if (this.logState) {
      const now = Date.now();
      const dataAge = now - this.logState.timestamp;

      if (!allowExpired && dataAge > 5000) {
        return {
          success: false,
          timestamp: this.logState.timestamp,
          cacheAge: dataAge,
          state: null,
          message: `Game data is stale (${Math.round(dataAge / 1000)}s old). The game may not be running.`,
        };
      }

      // 转换日志状态为游戏状态格式
      const state: GameState = {
        player: {
          health: this.logState.player.health,
          hunger: this.logState.player.hunger,
          sanity: this.logState.player.sanity,
          position: this.logState.player.position,
          isGhost: false,
        },
        world: {
          day: this.logState.world.day,
          time: 0.5,
          season: "summer",
          isday: true,
          isnight: false,
          isdusk: false,
          moonphase: "new",
          israining: false,
        },
        entities: [],
        inventory: [],
      };

      const readableState = this.formatForAI(state);
      return {
        success: true,
        timestamp: this.logState.timestamp,
        cacheAge: dataAge,
        state: readableState as GameState,
        message: `Game state retrieved from log (data age: ${Math.round(dataAge)}ms)`,
      };
    }

    // 如果日志解析器没有数据，主动读取日志
    if (this.logParser) {
      const state = await this.readLatestFromLog();
      if (state) {
        const gameState: GameState = {
          player: {
            health: state.player.health,
            hunger: state.player.hunger,
            sanity: state.player.sanity,
            position: state.player.position,
            isGhost: false,
          },
          world: {
            day: state.world.day,
            time: 0.5,
            season: "summer",
            isday: true,
            isnight: false,
            isdusk: false,
            moonphase: "new",
            israining: false,
          },
          entities: [],
          inventory: [],
        };
        const readableState = this.formatForAI(gameState);
        return {
          success: true,
          timestamp: state.timestamp,
          cacheAge: 0,
          state: readableState as GameState,
          message: "Game state retrieved from log (live)",
        };
      }
    }

    // 回退到文件读取
    const raw = await this.watcher.readFile("state.txt");
    if (!raw) {
      return {
        success: false,
        timestamp: null,
        cacheAge: null,
        state: null,
        message: "No game state available. Make sure the game is running and the mod is enabled.",
      };
    }

    // 解析原始JSON获取游戏时间戳
    let gameTimestamp: number | null = null;
    try {
      const parsed = JSON.parse(raw);
      gameTimestamp = parsed.t || null;
    } catch {
      // 忽略解析错误
    }

    // 检查数据新鲜度（使用游戏写入的时间戳）
    const STALE_THRESHOLD_MS = 10000;
    const now = Date.now();
    const dataAge = gameTimestamp ? (now - gameTimestamp) : Infinity;

    if (!allowExpired && dataAge > STALE_THRESHOLD_MS) {
      return {
        success: false,
        timestamp: gameTimestamp,
        cacheAge: dataAge,
        state: null,
        message: `Game data is stale (${Math.round(dataAge / 1000)}s old). The game may not be running.`,
      };
    }

    // 数据新鲜，解析并返回状态
    const state = StateCache.parse(raw);
    if (!state) {
      return {
        success: false,
        timestamp: gameTimestamp,
        cacheAge: dataAge,
        state: null,
        message: "Failed to parse game state data.",
      };
    }

    // 更新缓存
    this.cache.set(raw, state);

    // 格式化输出，便于AI阅读
    const readableState = this.formatForAI(state);

    return {
      success: true,
      timestamp: gameTimestamp,
      cacheAge: dataAge,
      state: readableState as GameState,
      message: `Game state retrieved (data age: ${Math.round(dataAge)}ms)`,
    };
  }

  /**
   * 格式化状态以便AI理解
   */
  private formatForAI(state: GameState): unknown {
    return {
      player: {
        health: Math.round(state.player.health * 100) + "%",
        hunger: Math.round(state.player.hunger * 100) + "%",
        sanity: Math.round(state.player.sanity * 100) + "%",
        position: `(${state.player.position.x.toFixed(1)}, ${state.player.position.z.toFixed(1)})`,
        isGhost: state.player.isGhost || false,
      },
      world: {
        day: state.world.day,
        time: this.formatTime(state.world.time),
        season: state.world.season,
        phase: state.world.isday ? "day" : state.world.isnight ? "night" : "dusk",
        moon: state.world.moonphase || "unknown",
        raining: state.world.israining || false,
      },
      nearby: state.entities.slice(0, 10).map((e) => ({
        type: e.prefab,
        distance: `${e.distance.toFixed(1)} units`,
        position: `(${e.position.x.toFixed(1)}, ${e.position.z.toFixed(1)})`,
        notes: this.getEntityNotes(e),
      })),
      inventory: state.inventory.map((i) => `${i.prefab} x${i.count}`).join(", ") || "empty",
    };
  }

  /**
   * 格式化时间
   */
  private formatTime(time: number): string {
    const hours = Math.floor(time * 24);
    const minutes = Math.floor((time * 24 - hours) * 60);
    return `Day ${hours}:${minutes.toString().padStart(2, "0")}`;
  }

  /**
   * 获取实体备注
   */
  private getEntityNotes(entity: import("../types/game.js").EntityState): string {
    const notes: string[] = [];

    if (entity.pickable) notes.push("pickable");
    if (entity.chopable) notes.push("choppable");
    if (entity.mineable) notes.push("mineable");
    if (entity.diggable) notes.push("diggable");
    if (entity.hostile) notes.push("hostile");
    if (entity.pickup_item) notes.push("item on ground");

    return notes.join(", ") || "";
  }

  /**
   * 直接从日志读取最新状态
   */
  private async readLatestFromLog(): Promise<ParsedGameState | null> {
    if (!this.logParser) return null;

    const latest = this.logParser.getLatestState();
    if (latest) return latest;

    // 如果解析器没有数据，尝试直接读取日志文件
    const { findClientLogPath } = await import("../sync/log-parser.js");
    const logPath = await findClientLogPath();
    if (!logPath) return null;

    try {
      const fs = await import("fs");
      const content = await fs.promises.readFile(logPath, "utf-8");
      const lines = content.split("\n").reverse();

      for (const line of lines) {
        const match = line.match(/DST_AI_STATE (\{.+\})/);
        if (match) {
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
        }
      }
    } catch {
      return null;
    }

    return null;
  }
}
