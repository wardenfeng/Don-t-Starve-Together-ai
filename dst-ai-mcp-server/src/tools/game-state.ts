// MCP工具：get_game_state - 获取当前游戏状态

import { DSTLogParser, findClientLogPath, type ParsedGameState } from "../sync/log-parser.js";
import type { GameState } from "../types/game.js";

/**
 * 获取游戏状态工具
 */
export class GameStateTool {
  private logParser: DSTLogParser | null = null;
  private logState: ParsedGameState | null = null;

  constructor() {
    this.initLogParser();
  }

  /**
   * 初始化日志解析器
   */
  private initLogParser(): void {
    findClientLogPath().then(logPath => {
      if (logPath) {
        this.logParser = new DSTLogParser(logPath, 100);
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
      description: "获取当前饥荒游戏状态",
      inputSchema: {
        type: "object",
        properties: {
          allow_expired: {
            type: "boolean",
            description: "允许返回过期的数据",
            default: false,
          },
        },
      },
    };
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
      const entities = (this.logState.entities || []).map(e => ({
        prefab: e.prefab,
        position: { x: e.x, y: 0, z: e.z },
        distance: e.distance,
        pickable: e.notes.includes("可采集"),
        chopable: e.notes.includes("可砍伐"),
        mineable: e.notes.includes("可开采"),
        diggable: e.notes.includes("可挖掘"),
        hostile: e.notes.includes("敌对"),
        pickup_item: e.notes.includes("物品"),
      }));

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
          time: this.logState.world.time,
          season: "summer",
          isday: true,
          isnight: false,
          isdusk: false,
          moonphase: "new",
          israining: false,
        },
        entities,
        inventory: (this.logState.inventory || []).map(i => ({
          prefab: i.prefab,
          count: i.stack || 1,
        })),
      };

      const readableState = this.formatForAIWithEntities(state, this.logState.entities || []);
      return {
        success: true,
        timestamp: this.logState.timestamp,
        cacheAge: dataAge,
        state: readableState as GameState,
        message: `Game state retrieved from log (data age: ${Math.round(dataAge)}ms)`,
      };
    }

    // 如果日志解析器没有数据，主动读取日志
    const state = await this.readLatestFromLog();
    if (state) {
      const entities = (state.entities || []).map(e => ({
        prefab: e.prefab,
        position: { x: e.x, y: 0, z: e.z },
        distance: e.distance,
        pickable: e.notes.includes("可采集"),
        chopable: e.notes.includes("可砍伐"),
        mineable: e.notes.includes("可开采"),
        diggable: e.notes.includes("可挖掘"),
        hostile: e.notes.includes("敌对"),
        pickup_item: e.notes.includes("物品"),
      }));

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
          time: state.world.time,
          season: "summer",
          isday: true,
          isnight: false,
          isdusk: false,
          moonphase: "new",
          israining: false,
        },
        entities,
        inventory: (state.inventory || []).map(i => ({
          prefab: i.prefab,
          count: i.stack || 1,
        })),
      };
      const readableState = this.formatForAIWithEntities(gameState, state.entities || []);
      return {
        success: true,
        timestamp: state.timestamp,
        cacheAge: 0,
        state: readableState as GameState,
        message: "Game state retrieved from log (live)",
      };
    }

    return {
      success: false,
      timestamp: null,
      cacheAge: null,
      state: null,
      message: "No game state available. Make sure the game is running and the mod is enabled.",
    };
  }

  /**
   * 直接从日志读取最新状态
   */
  private async readLatestFromLog(): Promise<ParsedGameState | null> {
    if (!this.logParser) return null;

    const latest = this.logParser.getLatestState();
    if (latest) return latest;

    // 如果解析器没有数据，尝试直接读取日志文件
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
        }
      }
    } catch {
      return null;
    }

    return null;
  }

  /**
   * 格式化状态和实体信息以便AI理解
   */
  private formatForAIWithEntities(state: GameState, parsedEntities: ParsedEntity[]): unknown {
    // 按距离排序
    const sorted = parsedEntities.slice().sort((a, b) => a.distance - b.distance);

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
      nearby: sorted.slice(0, 20).map((e) => ({
        name: e.name,
        prefab: e.prefab,
        distance: `${e.distance.toFixed(1)}m`,
        position: `(${e.x}, ${e.z})`,
        notes: e.notes || "",
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
}

interface ParsedEntity {
  prefab: string;
  name: string;
  x: number;
  z: number;
  distance: number;
  notes: string;
}

interface InventoryItem {
  prefab: string;
  name: string;
  stack: number;
}
