// DST AI MCP Server - 主入口文件
// Model Context Protocol 服务器，让AI模型能够与饥荒游戏通信

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

import { FileWatcher } from "./sync/file-watcher.js";
import { StateCache } from "./sync/state-cache.js";
import { CommandQueue } from "./sync/command-queue.js";
import { Heartbeat } from "./sync/heartbeat.js";
import { GameStateTool } from "./tools/game-state.js";
import { ActionTool } from "./tools/action.js";
import { ControlTools } from "./tools/control.js";

/**
 * 获取环境变量
 */
function getEnv(): {
  syncDir: string;
  stateCacheTtl: number;
  commandSequenceStart: number;
} {
  return {
    syncDir: process.env.SYNC_DIR || `${process.env.USERPROFILE || process.env.HOME || "."}\\dst-ai-sync\\`,
    stateCacheTtl: parseInt(process.env.STATE_CACHE_TTL || "5000"),
    commandSequenceStart: parseInt(process.env.COMMAND_SEQUENCE_START || "1"),
  };
}

/**
 * DST AI MCP服务器类
 */
class DSTMCPerver {
  private server: Server;
  private fileWatcher: FileWatcher;
  private stateCache: StateCache;
  private commandQueue: CommandQueue;
  private heartbeat: Heartbeat;
  private gameStateTool: GameStateTool;
  private actionTool: ActionTool;
  private controlTools: ControlTools;

  constructor() {
    const env = getEnv();

    // 初始化组件
    this.fileWatcher = new FileWatcher({
      syncDir: env.syncDir,
      onStateChange: (content) => this.onStateChange(content),
      onStatusChange: (connected) => this.onStatusChange(connected),
      onStatsChange: (stats) => this.onStatsChange(stats),
    });

    this.stateCache = new StateCache({ ttl: env.stateCacheTtl });
    this.commandQueue = new CommandQueue({ startSequence: env.commandSequenceStart });
    this.heartbeat = new Heartbeat({
      syncDir: env.syncDir,
      interval: 1000,
      onConnectionChange: (connected) => console.log(`[Server] Connection changed: ${connected}`),
    });

    // 初始化工具
    this.gameStateTool = new GameStateTool(this.stateCache, this.fileWatcher);
    this.actionTool = new ActionTool(this.commandQueue, this.fileWatcher);
    this.controlTools = new ControlTools(this.heartbeat, this.stateCache, this.commandQueue);

    // 创建MCP服务器
    this.server = new Server(
      {
        name: "dst-ai-mcp-server",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  /**
   * 设置MCP处理器
   */
  private setupHandlers(): void {
    // 列出工具
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          this.gameStateTool.definition,
          this.actionTool.definition,
          this.controlTools.statusDefinition,
          this.controlTools.enableDefinition,
          this.controlTools.disableDefinition,
        ],
      };
    });

    // 调用工具
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "get_game_state":
            return await this.handleGameState(args);

          case "send_action":
            return await this.handleSendAction(args);

          case "get_ai_status":
            return await this.handleGetStatus();

          case "enable_ai":
            return await this.handleEnableAI();

          case "disable_ai":
            return await this.handleDisableAI();

          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({
                success: false,
                error: errorMessage,
              }),
            },
          ],
        };
      }
    });
  }

  /**
   * 处理 get_game_state
   */
  private async handleGameState(args: unknown) {
    const result = await this.gameStateTool.execute(args as { allow_expired?: boolean });

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  /**
   * 处理 send_action
   */
  private async handleSendAction(args: unknown) {
    const result = await this.actionTool.execute(args as { actions: unknown[] });

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  /**
   * 处理 get_ai_status
   */
  private async handleGetStatus() {
    const result = await this.controlTools.getStatus();

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  /**
   * 处理 enable_ai
   */
  private async handleEnableAI() {
    const result = await this.controlTools.enable();

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  /**
   * 处理 disable_ai
   */
  private async handleDisableAI() {
    const result = await this.controlTools.disable();

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(result, null, 2),
        },
      ],
    };
  }

  /**
   * 状态文件变化回调
   */
  private onStateChange(content: string): void {
    const state = StateCache.parse(content);
    if (state) {
      this.stateCache.set(content, state);
      console.log("[Server] State updated, cache age:", this.stateCache.getAge(), "ms");
    }
  }

  /**
   * 连接状态变化回调
   */
  private onStatusChange(connected: boolean): void {
    this.heartbeat.setConnected(connected);
    console.log("[Server] Game", connected ? "connected" : "disconnected");
  }

  /**
   * 统计信息变化回调
   */
  private onStatsChange(stats: unknown): void {
    // 可以在这里更新内部统计状态
  }

  /**
   * 启动服务器
   */
  async start(): Promise<void> {
    // 启动文件监听
    await this.fileWatcher.start();

    // 启动心跳
    await this.heartbeat.start();

    // 启动MCP服务器
    const transport = new StdioServerTransport();
    await this.server.connect(transport);

    console.error("[Server] DST AI MCP Server started");
    console.error(`[Server] Sync directory: ${getEnv().syncDir}`);
    console.error("[Server] Available tools:");
    console.error("  - get_game_state: Get current game state");
    console.error("  - send_action: Send actions to game");
    console.error("  - get_ai_status: Get AI status and stats");
    console.error("  - enable_ai: Enable AI control");
    console.error("  - disable_ai: Disable AI control");
  }

  /**
   * 停止服务器
   */
  async stop(): Promise<void> {
    await this.heartbeat.stop();
    await this.fileWatcher.stop();
    await this.server.close();
    console.error("[Server] Stopped");
  }
}

/**
 * 主函数
 */
async function main(): Promise<void> {
  const server = new DSTMCPerver();

  // 处理优雅退出
  process.on("SIGINT", async () => {
    console.error("\n[Server] Received SIGINT, shutting down...");
    await server.stop();
    process.exit(0);
  });

  process.on("SIGTERM", async () => {
    console.error("\n[Server] Received SIGTERM, shutting down...");
    await server.stop();
    process.exit(0);
  });

  // 启动服务器
  await server.start();
}

// 启动
main().catch((error) => {
  console.error("[Server] Fatal error:", error);
  process.exit(1);
});
