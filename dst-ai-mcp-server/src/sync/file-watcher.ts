// 文件监听器 - 使用轮询方式监听同步目录的文件变化

import { promises as fs } from "fs";
import { join } from "path";

/**
 * 文件事件类型
 */
export type FileEventType = "state" | "command" | "status" | "stats" | "control";

/**
 * 文件变化事件回调
 */
export type FileChangeCallback = (eventType: FileEventType, filePath: string) => void;

/**
 * 文件监听器配置
 */
export interface FileWatcherOptions {
  /** 同步目录路径 */
  syncDir: string;
  /** 轮询间隔(毫秒) */
  pollInterval?: number;
  /** 状态变化回调 */
  onStateChange?: (content: string) => void;
  /** 命令确认回调 (命令被游戏读取) */
  onCommandAck?: () => void;
  /** 状态文件变化回调 */
  onStatusChange?: (connected: boolean) => void;
  /** 统计信息变化回调 */
  onStatsChange?: (stats: unknown) => void;
  /** 控制命令回调 */
  onControlCommand?: (command: "enable" | "disable") => void;
}

/**
 * 文件状态缓存
 */
interface FileCache {
  content: string;
  mtime: number;
}

/**
 * 文件监听器类 - 使用轮询方式
 */
export class FileWatcher {
  private syncDir: string;
  private options: FileWatcherOptions;
  private fileContents: Map<string, FileCache> = new Map();
  private pollInterval: NodeJS.Timeout | null = null;
  private pollMs: number;

  constructor(options: FileWatcherOptions) {
    this.syncDir = options.syncDir;
    this.options = options;
    this.pollMs = options.pollInterval || 100;
  }

  /**
   * 启动文件轮询
   */
  async start(): Promise<void> {
    // 确保同步目录存在
    await this.ensureSyncDirectory();

    // 初始化文件缓存
    await this.initFileCache();

    // 启动轮询
    this.pollInterval = setInterval(async () => {
      await this.checkFiles();
    }, this.pollMs);

    console.log(`[FileWatcher] Polling directory every ${this.pollMs}ms: ${this.syncDir}`);
  }

  /**
   * 初始化文件缓存
   */
  private async initFileCache(): Promise<void> {
    const files = ["state.txt", "cmd.txt", "status.txt", "stats.txt", "control.txt"];

    for (const fileName of files) {
      try {
        const filePath = join(this.syncDir, fileName);
        const content = await fs.readFile(filePath, "utf-8");
        const stats = await fs.stat(filePath);
        this.fileContents.set(fileName, {
          content,
          mtime: stats.mtimeMs,
        });
      } catch {
        // 文件不存在，初始化为空
        this.fileContents.set(fileName, {
          content: "",
          mtime: 0,
        });
      }
    }
  }

  /**
   * 停止文件轮询
   */
  async stop(): Promise<void> {
    if (this.pollInterval) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
      console.log("[FileWatcher] Stopped");
    }
  }

  /**
   * 确保同步目录存在
   */
  private async ensureSyncDirectory(): Promise<void> {
    try {
      await fs.access(this.syncDir);
    } catch {
      await fs.mkdir(this.syncDir, { recursive: true });
      console.log(`[FileWatcher] Created sync directory: ${this.syncDir}`);
    }
  }

  /**
   * 检查文件变化
   */
  private async checkFiles(): Promise<void> {
    const files = ["state.txt", "cmd.txt", "status.txt", "stats.txt", "control.txt"];

    for (const fileName of files) {
      try {
        const filePath = join(this.syncDir, fileName);
        const stats = await fs.stat(filePath);
        const cached = this.fileContents.get(fileName);

        // 文件被修改过
        if (!cached || stats.mtimeMs > cached.mtime) {
          const content = await fs.readFile(filePath, "utf-8");
          const fileType = this.getFileType(fileName);

          // 更新缓存
          this.fileContents.set(fileName, {
            content,
            mtime: stats.mtimeMs,
          });

          // 触发回调
          this.handleFileChange(fileType, content);
        }
      } catch {
        // 文件不存在或无法访问，忽略
      }
    }
  }

  /**
   * 根据文件类型分发事件
   */
  private handleFileChange(fileType: FileEventType, content: string): void {
    switch (fileType) {
      case "state":
        if (this.options.onStateChange) {
          this.options.onStateChange(content);
        }
        break;

      case "status":
        if (this.options.onStatusChange) {
          this.options.onStatusChange(content === "CONNECTED");
        }
        break;

      case "stats":
        if (this.options.onStatsChange) {
          try {
            const stats = JSON.parse(content);
            this.options.onStatsChange(stats);
          } catch (error) {
            console.error("[FileWatcher] Failed to parse stats:", error);
          }
        }
        break;

      case "control":
        if (this.options.onControlCommand) {
          const command = content.trim().toUpperCase();
          if (command === "ENABLE") {
            this.options.onControlCommand("enable");
          } else if (command === "DISABLE") {
            this.options.onControlCommand("disable");
          }
        }
        break;

      case "command":
        // cmd.txt 被清空表示游戏已读取命令
        if (content.trim() === "" && this.options.onCommandAck) {
          this.options.onCommandAck();
        }
        break;
    }
  }

  /**
   * 根据文件名确定文件类型
   */
  private getFileType(fileName: string): FileEventType {
    const typeMap: Record<string, FileEventType> = {
      "state.txt": "state",
      "cmd.txt": "command",
      "status.txt": "status",
      "stats.txt": "stats",
      "control.txt": "control",
    };
    return typeMap[fileName] || "status";
  }

  /**
   * 读取文件内容
   */
  async readFile(fileName: string): Promise<string | null> {
    try {
      const filePath = join(this.syncDir, fileName);
      const content = await fs.readFile(filePath, "utf-8");
      const stats = await fs.stat(filePath);

      // 更新缓存
      this.fileContents.set(fileName, {
        content,
        mtime: stats.mtimeMs,
      });

      return content;
    } catch {
      return null;
    }
  }

  /**
   * 写入文件内容
   */
  async writeFile(fileName: string, content: string): Promise<boolean> {
    try {
      const filePath = join(this.syncDir, fileName);
      await fs.writeFile(filePath, content, "utf-8");
      const stats = await fs.stat(filePath);

      // 更新缓存
      this.fileContents.set(fileName, {
        content,
        mtime: stats.mtimeMs,
      });
      return true;
    } catch (error) {
      console.error(`[FileWatcher] Error writing file ${fileName}:`, error);
      return false;
    }
  }

  /**
   * 删除文件
   */
  async deleteFile(fileName: string): Promise<boolean> {
    try {
      const filePath = join(this.syncDir, fileName);
      await fs.unlink(filePath);
      this.fileContents.delete(fileName);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * 获取同步目录路径
   */
  getSyncDir(): string {
    return this.syncDir;
  }
}
