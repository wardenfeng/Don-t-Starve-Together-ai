// 心跳管理 - 维护与游戏的双向心跳检测

import { promises as fs } from "fs";
import { join } from "path";

/**
 * 心跳配置
 */
export interface HeartbeatOptions {
  /** 同步目录路径 */
  syncDir: string;
  /** 心跳间隔（毫秒），默认1000ms */
  interval?: number;
  /** 连接状态变化回调 */
  onConnectionChange?: (connected: boolean) => void;
}

/**
 * 心跳状态
 */
export interface HeartbeatStatus {
  running: boolean;
  connected: boolean;
  lastWrite: number | null;
  lastRead: number | null;
}

/**
 * 心跳管理类
 */
export class Heartbeat {
  private syncDir: string;
  private interval: number;
  private timer: NodeJS.Timeout | null = null;
  private connected: boolean = false;
  private running: boolean = false;
  private lastWrite: number | null = null;
  private lastRead: number | null = null;
  private onConnectionChange?: (connected: boolean) => void;

  constructor(options: HeartbeatOptions) {
    this.syncDir = options.syncDir;
    this.interval = options.interval || 1000;
    this.onConnectionChange = options.onConnectionChange;
  }

  /**
   * 启动心跳
   */
  async start(): Promise<void> {
    if (this.running) {
      return;
    }

    this.running = true;

    // 立即写入一次状态
    await this.writeStatus();

    // 定时写入心跳
    this.timer = setInterval(async () => {
      await this.writeStatus();
      await this.checkConnection();
    }, this.interval);

    console.log(`[Heartbeat] Started with interval ${this.interval}ms`);
  }

  /**
   * 停止心跳
   */
  async stop(): Promise<void> {
    this.running = false;

    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }

    // 删除状态文件
    try {
      await fs.unlink(join(this.syncDir, "status.txt"));
    } catch {
      // 文件不存在或删除失败，忽略
    }

    console.log("[Heartbeat] Stopped");
  }

  /**
   * 写入状态文件
   */
  private async writeStatus(): Promise<void> {
    try {
      const content = "CONNECTED";
      await fs.writeFile(join(this.syncDir, "status.txt"), content, "utf-8");
      this.lastWrite = Date.now();
    } catch (error) {
      console.error("[Heartbeat] Failed to write status:", error);
    }
  }

  /**
   * 检查连接状态
   * 通过读取stats.txt来判断游戏是否在运行
   */
  private async checkConnection(): Promise<void> {
    try {
      const content = await fs.readFile(join(this.syncDir, "stats.txt"), "utf-8");
      const stats = JSON.parse(content);

      // 如果stats.txt在最近更新过，认为游戏在运行
      const timestamp = stats.timestamp || 0;
      const age = Date.now() - timestamp;
      const wasConnected = this.connected;
      this.connected = age < 5000; // 5秒内有更新认为连接

      this.lastRead = Date.now();

      if (wasConnected !== this.connected && this.onConnectionChange) {
        this.onConnectionChange(this.connected);
      }
    } catch {
      const wasConnected = this.connected;
      this.connected = false;

      if (wasConnected !== this.connected && this.onConnectionChange) {
        this.onConnectionChange(false);
      }
    }
  }

  /**
   * 手动设置连接状态
   */
  setConnected(connected: boolean): void {
    const wasConnected = this.connected;
    this.connected = connected;

    if (wasConnected !== connected && this.onConnectionChange) {
      this.onConnectionChange(connected);
    }
  }

  /**
   * 获取连接状态
   */
  isConnected(): boolean {
    return this.connected;
  }

  /**
   * 获取心跳状态
   */
  getStatus(): HeartbeatStatus {
    return {
      running: this.running,
      connected: this.connected,
      lastWrite: this.lastWrite,
      lastRead: this.lastRead,
    };
  }

  /**
   * 写入控制命令
   */
  async writeControl(command: "enable" | "disable"): Promise<boolean> {
    try {
      await fs.writeFile(join(this.syncDir, "control.txt"), command.toUpperCase(), "utf-8");
      console.log(`[Heartbeat] Wrote control command: ${command}`);
      return true;
    } catch (error) {
      console.error("[Heartbeat] Failed to write control command:", error);
      return false;
    }
  }
}
