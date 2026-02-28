// MCP工具：send_action - 发送动作指令到游戏

import { CommandQueue } from "../sync/command-queue.js";
import { FileWatcher } from "../sync/file-watcher.js";
import { Action, ActionType } from "../types/game.js";

/**
 * 发送动作工具
 */
export class ActionTool {
  private queue: CommandQueue;
  private watcher: FileWatcher;

  constructor(queue: CommandQueue, watcher: FileWatcher) {
    this.queue = queue;
    this.watcher = watcher;
  }

  /**
   * MCP工具定义
   */
  get definition() {
    return {
      name: "send_action",
      description: "向游戏发送一个或多个动作指令。动作将被游戏Mod执行。",
      inputSchema: {
        type: "object",
        properties: {
          actions: {
            type: "array",
            items: {
              type: "object",
              properties: {
                type: {
                  type: "string",
                  enum: [
                    "move", "pickup", "chop", "mine", "dig",
                    "attack", "eat", "equip", "unequip",
                    "craft", "build", "wait", "follow", "revive"
                  ],
                  description: "动作类型",
                },
                target: {
                  type: "object",
                  description: "目标位置（move类型使用）",
                  properties: {
                    x: { type: "number" },
                    y: { type: "number" },
                    z: { type: "number" },
                  },
                },
                entity: {
                  type: "string",
                  description: "目标实体prefab名称（pickup/chop/mine/attack等使用）",
                },
                position: {
                  type: "object",
                  description: "实体位置（用于查找附近实体）",
                  properties: {
                    x: { type: "number" },
                    y: { type: "number" },
                    z: { type: "number" },
                  },
                },
                item: {
                  type: "string",
                  description: "物品名称（equip/craft使用）",
                },
                slot: {
                  type: "string",
                  enum: ["hands", "head", "body"],
                  description: "装备槽位（equip使用）",
                },
                duration: {
                  type: "number",
                  description: "等待时长秒数（wait使用）",
                },
              },
              required: ["type"],
            },
          },
        },
        required: ["actions"],
      },
    } as const;
  }

  /**
   * 执行工具
   */
  async execute(args: { actions: Array<Partial<Action>> }): Promise<{
    success: boolean;
    sequence: number;
    sent: number;
    message: string;
  }> {
    if (!args.actions || args.actions.length === 0) {
      return {
        success: false,
        sequence: 0,
        sent: 0,
        message: "No actions provided",
      };
    }

    // 验证并转换动作
    const validActions: Action[] = [];
    for (const action of args.actions) {
      if (!action.type) {
        continue;
      }
      validActions.push(action as Action);
    }

    if (validActions.length === 0) {
      return {
        success: false,
        sequence: 0,
        sent: 0,
        message: "No valid actions provided",
      };
    }

    // 创建命令
    const command = this.queue.create(validActions);

    // 序列化并写入JSON文件（用于文件通信）
    const json = CommandQueue.serialize(command);
    let written = await this.watcher.writeFile("cmd.txt", json);

    // 同时写入Lua格式文件（用于dofile加载）
    // 将JSON转换为Lua表格式
    const luaActions = validActions.map((a) => {
      let lua = `{type="${a.type}"`;
      if (a.target) lua += `,target={x=${a.target.x},y=${a.target.y},z=${a.target.z}}`;
      if (a.entity) lua += `,entity="${a.entity}"`;
      if (a.item) lua += `,item="${a.item}"`;
      if (a.slot) lua += `,slot="${a.slot}"`;
      if (a.duration) lua += `,duration=${a.duration}`;
      lua += "}";
      return lua;
    }).join(",");

    const luaContent = `
-- DST AI Command File
-- Generated: ${new Date().toISOString()}
-- Seq: ${command.seq}

local cmd = {
    seq = ${command.seq},
    actions = {${luaActions}}
}

-- 执行命令
if _DST_AI_SetCommand then
    _DST_AI_SetCommand(cmd)
else
    print("[DST AI] Error: _DST_AI_SetCommand not found. Make sure the mod is loaded.")
end

return cmd
`;

    // 写入Lua文件到同步目录
    const fs = await import("fs");
    const luaPath = "C:\\Users\\Administrator\\dst-ai-sync\\cmd.lua";
    try {
      await fs.promises.writeFile(luaPath, luaContent, "utf-8");
      written = true;
    } catch {
      // Lua文件写入失败，但JSON可能成功
    }

    if (!written) {
      return {
        success: false,
        sequence: command.seq,
        sent: 0,
        message: "Failed to write command file",
      };
    }

    // 标记为已发送
    this.queue.markAsSent(command);

    return {
      success: true,
      sequence: command.seq,
      sent: validActions.length,
      message: `Sent ${validActions.length} action(s) with sequence ${command.seq}`,
    };
  }

  /**
   * 快捷方法：移动到位置
   */
  async move(x: number, y: number, z: number): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "move", target: { x, y, z } }],
    });
    return result.success;
  }

  /**
   * 快捷方法：拾取物品
   */
  async pickup(entity: string): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "pickup", entity }],
    });
    return result.success;
  }

  /**
   * 快捷方法：砍树
   */
  async chop(): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "chop", entity: "evergreen" }],
    });
    return result.success;
  }

  /**
   * 快捷方法：挖矿
   */
  async mine(): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "mine", entity: "rock" }],
    });
    return result.success;
  }

  /**
   * 快捷方法：攻击
   */
  async attack(entity: string): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "attack", entity }],
    });
    return result.success;
  }

  /**
   * 快捷方法：进食
   */
  async eat(): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "eat" }],
    });
    return result.success;
  }

  /**
   * 快捷方法：装备物品
   */
  async equip(item: string, slot: "hands" | "head" | "body" = "hands"): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "equip", item, slot }],
    });
    return result.success;
  }

  /**
   * 快捷方法：等待
   */
  async wait(duration: number = 1): Promise<boolean> {
    const result = await this.execute({
      actions: [{ type: "wait", duration }],
    });
    return result.success;
  }
}
