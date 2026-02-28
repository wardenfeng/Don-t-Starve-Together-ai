// 状态缓存管理 - 缓存游戏状态

import type { GameState } from "../types/game.js";

/**
 * 缓存配置
 */
export interface StateCacheOptions {
  /** 缓存过期时间（毫秒），默认5000ms */
  ttl?: number;
}

/**
 * 带时间戳的缓存项
 */
interface CachedState {
  state: GameState;
  timestamp: number;
  raw: string;  // 原始JSON字符串
}

/**
 * 状态缓存类
 */
export class StateCache {
  private cache: CachedState | null = null;
  private ttl: number;

  constructor(options: StateCacheOptions = {}) {
    this.ttl = options.ttl || 5000;
  }

  /**
   * 更新缓存
   */
  set(rawJson: string, state: GameState): void {
    this.cache = {
      state,
      timestamp: Date.now(),
      raw: rawJson,
    };
  }

  /**
   * 获取缓存的状态
   */
  get(): GameState | null {
    if (!this.cache) {
      return null;
    }

    if (this.isExpired()) {
      this.cache = null;
      return null;
    }

    return this.cache.state;
  }

  /**
   * 获取缓存的状态（如果过期也不删除）
   */
  getAllowExpired(): GameState | null {
    return this.cache?.state || null;
  }

  /**
   * 获取原始JSON字符串
   */
  getRaw(): string | null {
    if (!this.cache) {
      return null;
    }

    if (this.isExpired()) {
      this.cache = null;
      return null;
    }

    return this.cache.raw;
  }

  /**
   * 检查缓存是否过期
   */
  isExpired(): boolean {
    if (!this.cache) {
      return true;
    }

    const age = Date.now() - this.cache.timestamp;
    return age > this.ttl;
  }

  /**
   * 获取缓存年龄（毫秒）
   */
  getAge(): number {
    if (!this.cache) {
      return Infinity;
    }
    return Date.now() - this.cache.timestamp;
  }

  /**
   * 清空缓存
   */
  clear(): void {
    this.cache = null;
  }

  /**
   * 获取缓存时间戳
   */
  getTimestamp(): number | null {
    return this.cache?.timestamp || null;
  }
}
