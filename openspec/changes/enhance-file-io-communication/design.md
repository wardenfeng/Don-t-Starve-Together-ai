## Context

当前系统使用混合通信方式：
1. 游戏通过日志输出状态 (`[DST_AI] STATE`)
2. MCP 服务器解析日志获取状态
3. MCP 服务器通过 `cmd.txt` 发送命令
4. 游戏从 `cmd.txt` 读取命令

这种混合方式增加了复杂度：
- 日志解析依赖文件轮询，延迟不可控
- 需要维护两套状态获取逻辑
- 日志格式变化会影响解析

**约束条件**：
- DST Lua 环境不支持 os 全局表和 HTTP 库
- 必须使用纯 Lua 文件 I/O (io.open)
- 客户端 Mod，不能使用服务器专用 API

## Goals / Non-Goals

**Goals:**
- 简化通信架构，统一使用 File I/O
- 移除日志解析相关代码
- 保持现有 MCP 工具接口不变
- 支持可选的 RAM disk 优化

**Non-Goals:**
- 不修改 DST 核心脚本 (dst_scripts)
- 不引入新的通信协议 (HTTP/WebSocket)
- 不改变 MCP 工具的输入输出格式

## Decisions

### 1. 保持纯 File I/O 通信

**选择**：使用文件作为唯一通信方式

**理由**：
- DST Lua 环境限制，无 HTTP 库支持
- 文件 I/O 简单可靠，易于调试
- 不依赖外部依赖

**替代方案**：日志 + 控制台命令
- 被拒绝：控制台命令需要输入模拟，延迟更高

### 2. 同步目录位置

**选择**：默认 `C:\dst-ai-sync\`，支持环境变量配置

**理由**：
- 固定路径便于开发和测试
- 环境变量支持生产环境定制
- 可选 RAM disk 支持性能优化

**RAM disk 路径**：`R:\dst-ai-sync\` (Windows ImDisk)

### 3. 文件格式

**状态文件 (state.txt)**：
```json
{"v":1,"hp":0.8,"hu":0.6,"sa":0.9,"x":100,"z":-200,"day":5,"time":0.5}
```
- 单行 JSON，便于解析
- 缩短字段名减少文件大小

**命令文件 (cmd.txt)**：
```json
{"v":1,"actions":[{"type":"move","target":{"x":105,"y":0,"z":-198}}]}
```
- 保持现有格式不变

### 4. 更新频率

**选择**：每 5 帧更新一次 (~80ms)

**理由**：
- DST 运行在 60fps，5 帧约 80ms
- 平衡实时性和性能
- 避免 CPU 过载

### 5. 代码组织

**Mod 结构**：
```
dst-ai-mod/
├── modmain.lua          # 主入口，AI 控制器
└── modinfo.lua          # Mod 元数据
```

**内联实现**：AI 控制器直接在 modmain.lua 中实现
- 简单逻辑无需额外文件
- 减少模块加载开销

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| 文件 I/O 被杀毒软件拦截 | 添加白名单说明 |
| 同步目录不存在 | 启动时自动创建 |
| 文件写入失败 | 错误日志，不中断游戏 |
| 并发读写冲突 | 使用原子写入（临时文件+重命名） |
| RAM disk 不可用 | 回退到普通磁盘路径 |

## Migration Plan

### Phase 1: Mod 修改
1. 简化 `modmain.lua` 为纯 File I/O 实现
2. 移除日志输出代码
3. 测试文件读写

### Phase 2: MCP 服务器修改
1. 简化 `game-state.ts`，移除日志解析
2. 保持 `file-watcher.ts` 作为主要数据源
3. 更新 `log-parser.ts` 为可选备份

### Phase 3: 测试验证
1. 单元测试：文件读写
2. 集成测试：Mod ↔ MCP 通信
3. 性能测试：延迟测量

### Rollback
- 保留 git 历史，可随时回退
- 日志解析器保留为备份选项

## Open Questions

1. **是否需要二进制格式优化？**
   - 当前 JSON 格式已足够快 (<10ms)
   - 二进制格式增加复杂度，暂不实现

2. **是否需要增量更新？**
   - 当前全量更新足够高效
   - 增量增加同步复杂度，暂不实现

3. **RAM disk 支持方式？**
   - 通过环境变量 `DST_SYNC_DIR` 配置
   - 文档说明如何设置 RAM disk
