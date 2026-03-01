## Why

当前通信架构混合使用日志输出和文件 I/O，导致：
1. MCP 服务器需要同时解析日志和监听文件，复杂度高
2. 日志解析延迟不可控，依赖文件轮询
3. 代码分散在多个通信方式中，难以维护

简化为纯 File I/O 方案，降低复杂度，提高可靠性。

## What Changes

- **移除日志输出状态机制**：删除 `direct_controller.lua` 中的日志输出代码
- **简化 MCP 服务器**：移除日志解析器，专注文件监听
- **优化 File I/O 实现**：
  - 使用 RAM disk 目录（可选）降低延迟
  - 二进制格式替代 JSON（可选）
  - 增量更新替代全量写入（可选）

## Capabilities

### New Capabilities

- `file-io-communication`: 游戏与 MCP 服务器之间的文件通信协议
  - 状态文件格式：`state.txt`
  - 命令文件格式：`cmd.txt`
  - 控制文件格式：`control.txt`

### Modified Capabilities

无（这是新系统的初始定义）

## Impact

**Mod 代码**：
- `dst-ai-mod/modmain.lua` - 简化为纯 File I/O 实现
- 删除 `dst-ai-mod/scripts/ai/core/direct_controller.lua`（如果存在）

**MCP 服务器**：
- `dst-ai-mcp-server/src/sync/log-parser.ts` - 可移除或保留作为备份
- `dst-ai-mcp-server/src/sync/file-watcher.ts` - 保持作为主要通信方式
- `dst-ai-mcp-server/src/tools/game-state.ts` - 简化，移除日志解析逻辑

**同步目录**：
- `C:\dst-ai-sync\` 或 RAM disk 路径
