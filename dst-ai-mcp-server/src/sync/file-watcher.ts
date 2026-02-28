// 文件监听器 - 使用chokidar监听同步目录的文件变化

import chokidar from "chokidar";
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
 * 文件监听器类
 */
export class FileWatcher {
  private watcher: chokidar.FSWatcher | null = null;
  private syncDir: string;
  private options: FileWatcherOptions;
  private fileContents: Map<string, string> = new Map();

  constructor(options: FileWatcherOptions) {
    this.syncDir = options.syncDir;
    this.options = options;
  }

  /**
   * 启动文件监听
   */
  async start(): Promise<void> {
    // 确保同步目录存在
    await this.ensureSyncDirectory();

    // 创建监听器
    this.watcher = chokidar.watch(join(this.syncDir, "*.txt"), {
      persistent: true,
      ignoreInitial: true,
      awaitWriteFinish: {
        stabilityThreshold: 50,
        pollInterval: 10,
      },
    });

    // 监听变化事件
    this.watcher.on("change", (filePath) => this.onFileChange(filePath));
    this.watcher.on("add", (filePath) => this.onFileChange(filePath));
    this.watcher.on("error", (error) => this.onError(error));

    console.log(`[FileWatcher] Watching directory: ${this.syncDir}`);
  }

  /**
   * 停止文件监听
   */
  async stop(): Promise<void> {
    if (this.watcher) {
      await this.watcher.close();
      this.watcher = null;
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
   * 文件变化处理
   */
  private async onFileChange(filePath: string): Promise<void> {
    const fileName = filePath.split(/[/\\]/).pop() || "";
    const fileType = this.getFileType(fileName);

    try {
      const content = await fs.readFile(filePath, "utf-8");
      const oldContent = this.fileContents.get(fileName);

      // 只在内容实际变化时触发回调
      if (content !== oldContent) {
        this.fileContents.set(fileName, content);
        this.handleFileChange(fileType, content);
      }
    } catch (error) {
      console.error(`[FileWatcher] Error reading file ${fileName}:`, error);
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
   * 错误处理
   */
  private onError(error: Error): void {
    console.error("[FileWatcher] Watcher error:", error);
  }

  /**
   * 读取文件内容
   */
  async readFile(fileName: string): Promise<string | null> {
    try {
      const filePath = join(this.syncDir, fileName);
      return await fs.readFile(filePath, "utf-8");
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
      this.fileContents.set(fileName, content);
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
