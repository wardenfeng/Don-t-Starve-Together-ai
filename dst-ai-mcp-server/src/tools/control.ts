// MCP工具：AI控制相关工具 (enable/disable/status)

import { Heartbeat } from "../sync/heartbeat.js";
import { StateCache } from "../sync/state-cache.js";
import { CommandQueue } from "../sync/command-queue.js";

/**
 * AI控制工具集
 */
export class ControlTools {
  private heartbeat: Heartbeat;
  private cache: StateCache;
  private queue: CommandQueue;

  constructor(heartbeat: Heartbeat, cache: StateCache, queue: CommandQueue) {
    this.heartbeat = heartbeat;
    this.cache = cache;
    this.queue = queue;
  }

  /**
   * get_ai_status 工具定义
   */
  get statusDefinition() {
    return {
      name: "get_ai_status",
      description: "获取AI控制器的状态和统计信息，包括是否启用、连接状态、循环次数、执行动作数等。",
      inputSchema: {
        type: "object",
        properties: {},
      },
    } as const;
  }

  /**
   * 获取AI状态
   */
  async getStatus(): Promise<{
    success: boolean;
    enabled: boolean;
    connected: boolean;
    stats: {
      cycles: number;
      actionsExecuted: number;
      errors: number;
    };
    lastUpdate: number | null;
    queueStats: {
      pending: number;
      sent: number;
      unacknowledged: number;
    };
  }> {
    const stats = await this.readStats();

    return {
      success: true,
      enabled: stats?.enabled ?? false,
      connected: this.heartbeat.isConnected(),
      stats: {
        cycles: stats?.cycles ?? 0,
        actionsExecuted: stats?.actions ?? 0,
        errors: stats?.errors ?? 0,
      },
      lastUpdate: stats?.timestamp ?? null,
      queueStats: this.queue.getStats(),
    };
  }

  /**
   * enable_ai 工具定义
   */
  get enableDefinition() {
    return {
      name: "enable_ai",
      description: "启用AI自动控制。启用后AI将根据MCP工具发送的指令自动操作游戏角色。",
      inputSchema: {
        type: "object",
        properties: {},
      },
    } as const;
  }

  /**
   * 启用AI
   */
  async enable(): Promise<{
    success: boolean;
    enabled: boolean;
    message: string;
  }> {
    const result = await this.heartbeat.writeControl("enable");

    return {
      success: result,
      enabled: result,
      message: result ? "AI control enabled" : "Failed to enable AI control",
    };
  }

  /**
   * disable_ai 工具定义
   */
  get disableDefinition() {
    return {
      name: "disable_ai",
      description: "禁用AI自动控制。禁用后AI将不再自动操作，需要手动控制或重新启用。",
      inputSchema: {
        type: "object",
        properties: {},
      },
    } as const;
  }

  /**
   * 禁用AI
   */
  async disable(): Promise<{
    success: boolean;
    enabled: boolean;
    message: string;
  }> {
    const result = await this.heartbeat.writeControl("disable");

    return {
      success: result,
      enabled: !result,
      message: result ? "AI control disabled" : "Failed to disable AI control",
    };
  }

  /**
   * 读取统计信息
   */
  private async readStats(): Promise<{
    enabled: boolean;
    cycles: number;
    actions: number;
    errors: number;
    timestamp: number;
  } | null> {
    try {
      // 通过watcher读取stats.txt
      // 这里需要注入watcher依赖，暂时返回null
      return null;
    } catch {
      return null;
    }
  }
}
