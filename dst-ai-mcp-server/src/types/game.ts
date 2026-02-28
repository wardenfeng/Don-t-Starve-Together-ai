// 游戏状态相关类型定义

/**
 * 玩家位置
 */
export interface Position {
  x: number;
  y: number;
  z: number;
}

/**
 * 玩家状态
 */
export interface PlayerState {
  /** 生命值比例 (0-1) */
  health: number;
  /** 饥饿值比例 (0-1) */
  hunger: number;
  /** 理智值比例 (0-1) */
  sanity: number;
  /** 玩家位置 */
  position: Position;
  /** 是否幽灵状态 */
  isGhost?: boolean;
}

/**
 * 世界状态
 */
export interface WorldState {
  /** 游戏天数 */
  day: number;
  /** 时间进度 (0-1) */
  time: number;
  /** 季节 */
  season: string;
  /** 是否白天 */
  isday: boolean;
  /** 是否夜晚 */
  isnight?: boolean;
  /** 是否黄昏 */
  isdusk?: boolean;
  /** 月相 */
  moonphase?: string;
  /** 是否下雨 */
  israining?: boolean;
  /** 季节剩余天数 */
  seasonremaining?: number;
}

/**
 * 实体信息
 */
export interface EntityState {
  /** 实体prefab名称 */
  prefab: string;
  /** 实体位置 */
  position: Position;
  /** 与玩家距离 */
  distance: number;
  /** 可采集 */
  pickable?: boolean;
  /** 可以采集 */
  canpick?: boolean;
  /** 可砍 */
  chopable?: boolean;
  /** 可挖 */
  mineable?: boolean;
  /** 可挖掘 */
  diggable?: boolean;
  /** 是否敌对 */
  hostile?: boolean;
  /** 可拾取 */
  pickup_item?: boolean;
}

/**
 * 背包物品
 */
export interface InventoryItem {
  /** prefab名称 */
  prefab: string;
  /** 数量 */
  count: number;
  /** 装备位置 */
  equipped?: string;
}

/**
 * 完整游戏状态
 */
export interface GameState {
  /** 玩家状态 */
  player: PlayerState;
  /** 世界状态 */
  world: WorldState;
  /** 附近实体 */
  entities: EntityState[];
  /** 背包物品 */
  inventory: InventoryItem[];
}

/**
 * 动作类型
 */
export type ActionType =
  | "move"
  | "pickup"
  | "chop"
  | "mine"
  | "dig"
  | "attack"
  | "eat"
  | "equip"
  | "unequip"
  | "craft"
  | "build"
  | "wait"
  | "follow"
  | "revive";

/**
 * 动作指令
 */
export interface Action {
  /** 动作类型 */
  type: ActionType;
  /** 目标位置 (move用) */
  target?: Position;
  /** 实体引用 */
  entity?: string;
  /** 位置引用 (查找实体用) */
  position?: Position;
  /** 物品名称 (equip/craft用) */
  item?: string;
  /** 装备槽位 (equip用) */
  slot?: string;
  /** 等待时长 (wait用) */
  duration?: number;
}

/**
 * 命令结构 (从MCP服务器发送到游戏)
 */
export interface Command {
  /** 协议版本 */
  v: number;
  /** 时间戳 */
  t: number;
  /** 序列号 */
  seq: number;
  /** 动作列表 (简写 a) */
  a?: Action[];
  actions?: Action[];
}

/**
 * 状态文件结构 (从游戏发送到MCP服务器)
 */
export interface StateFile {
  /** 协议版本 */
  v: number;
  /** 时间戳 */
  t: number;
  /** 玩家状态 (简写 p) */
  p?: {
    hp: number;
    hu: number;
    sa: number;
    pos: [number, number, number];
  };
  player?: PlayerState;
  /** 世界状态 (简写 w) */
  w?: {
    day: number;
    time: number;
    season: string;
    isDay: boolean;
    moon?: string;
  };
  world?: WorldState;
  /** 实体列表 (简写 e) */
  e?: Array<{
    p: string;
    pos: [number, number, number];
    d: number;
  }>;
  entities?: EntityState[];
  /** 背包物品 (简写 i) */
  i?: Array<{
    p: string;
    n: number;
  }>;
  inventory?: InventoryItem[];
}

/**
 * AI统计信息
 */
export interface AIStats {
  /** 是否启用 */
  enabled: boolean;
  /** 循环次数 */
  cycles: number;
  /** 执行动作数 */
  actions: number;
  /** 错误数 */
  errors: number;
  /** 时间戳 */
  timestamp: number;
}

/**
 * MCP工具结果
 */
export interface ToolResult {
  success: boolean;
  data?: unknown;
  error?: string;
  message?: string;
}
