// 命令队列管理 - 管理待发送和已确认的命令

import { Action, Command } from "../types/game.js";

/**
 * 队列中的命令项
 */
interface QueuedCommand {
  command: Command;
  timestamp: number;
  acknowledged: boolean;
}

/**
 * 命令队列配置
 */
export interface CommandQueueOptions {
  /** 初始序列号 */
  startSequence?: number;
}

/**
 * 命令队列类
 */
export class CommandQueue {
  private sequence: number;
  private pending: QueuedCommand[] = [];
  private sent: Map<number, QueuedCommand> = new Map();
  private maxSentHistory = 1000;

  constructor(options: CommandQueueOptions = {}) {
    this.sequence = options.startSequence || 1;
  }

  /**
   * 创建新命令
   */
  create(actions: Action[]): Command {
    const command: Command = {
      v: 1,
      t: Date.now(),
      seq: this.sequence++,
      a: actions,
    };

    return command;
  }

  /**
   * 入队待发送命令
   */
  enqueue(command: Command): void {
    this.pending.push({
      command,
      timestamp: Date.now(),
      acknowledged: false,
    });
  }

  /**
   * 出队待发送命令
   */
  dequeue(): Command | null {
    const item = this.pending.shift();
    return item?.command || null;
  }

  /**
   * 标记命令已发送
   */
  markAsSent(command: Command): void {
    const item: QueuedCommand = {
      command,
      timestamp: Date.now(),
      acknowledged: false,
    };

    this.sent.set(command.seq, item);

    // 清理旧记录
    this.cleanupOldSent();
  }

  /**
   * 标记命令已被游戏确认执行
   * 通过检查stats.txt中的序列号或观察cmd.txt被清空
   */
  acknowledge(seq: number): boolean {
    const item = this.sent.get(seq);
    if (item) {
      item.acknowledged = true;
      return true;
    }
    return false;
  }

  /**
   * 标记所有待发送命令为已确认（当cmd.txt被清空时）
   */
  acknowledgeAllPending(): void {
    for (const item of this.sent.values()) {
      if (!item.acknowledged) {
        item.acknowledged = true;
      }
    }
  }

  /**
   * 获取待发送命令数量
   */
  getPendingCount(): number {
    return this.pending.length;
  }

  /**
   * 获取已发送但未确认的命令
   */
  getUnacknowledged(): Command[] {
    const result: Command[] = [];
    for (const item of this.sent.values()) {
      if (!item.acknowledged) {
        result.push(item.command);
      }
    }
    return result;
  }

  /**
   * 获取未确认命令数量
   */
  getUnacknowledgedCount(): number {
    let count = 0;
    for (const item of this.sent.values()) {
      if (!item.acknowledged) {
        count++;
      }
    }
    return count;
  }

  /**
   * 清理旧的已发送记录
   */
  private cleanupOldSent(): void {
    if (this.sent.size <= this.maxSentHistory) {
      return;
    }

    // 找到最旧的已确认命令并删除
    const toDelete: number[] = [];
    for (const [seq, item] of this.sent.entries()) {
      if (item.acknowledged && toDelete.length < 100) {
        toDelete.push(seq);
      }
    }

    for (const seq of toDelete) {
      this.sent.delete(seq);
    }
  }

  /**
   * 清空队列
   */
  clear(): void {
    this.pending = [];
    this.sent.clear();
  }

  /**
   * 获取当前序列号
   */
  getCurrentSequence(): number {
    return this.sequence;
  }

  /**
   * 将命令序列化为JSON字符串
   */
  static serialize(command: Command): string {
    // 简化的JSON序列化，减少文件大小
    const parts: string[] = [];

    parts.push(`"v":${command.v}`);
    parts.push(`"t":${command.t}`);
    parts.push(`"seq":${command.seq}`);

    if (command.a && command.a.length > 0) {
      const actions = command.a.map((action) => {
        const actionParts: string[] = [];
        actionParts.push(`"type":"${action.type}"`);

        if (action.target) {
          actionParts.push(`"target":[${action.target.x},${action.target.y},${action.target.z}]`);
        }
        if (action.entity) {
          actionParts.push(`"entity":"${action.entity}"`);
        }
        if (action.position) {
          actionParts.push(`"position":[${action.position.x},${action.position.y},${action.position.z}]`);
        }
        if (action.item) {
          actionParts.push(`"item":"${action.item}"`);
        }
        if (action.slot) {
          actionParts.push(`"slot":"${action.slot}"`);
        }
        if (action.duration !== undefined) {
          actionParts.push(`"duration":${action.duration}`);
        }

        return `{${actionParts.join(",")}}`;
      });

      parts.push(`"a":[${actions.join(",")}]`);
    }

    return `{${parts.join(",")}}`;
  }

  /**
   * 获取统计信息
   */
  getStats(): {
    sequence: number;
    pending: number;
    sent: number;
    unacknowledged: number;
  } {
    return {
      sequence: this.sequence,
      pending: this.pending.length,
      sent: this.sent.size,
      unacknowledged: this.getUnacknowledgedCount(),
    };
  }
}
