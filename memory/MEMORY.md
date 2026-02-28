# DST AI Player - 项目记忆

## API 资源和学习资料

### 官方/权威文档

1. **DST API Docs (Fandom Wiki)**
   - URL: https://dst-api-docs.fandom.com/wiki/Home
   - 内容：完整的组件列表（500+条目）、ThePlayer/TheWorld API参考
   - 用途：查找实体组件、方法签名

2. **DST API Web Docs (GitHub)**
   - URL: https://github.com/vietnd69/dst-api-webdocs
   - 源码：https://github.com/vietnd69/dst-scripts（清理后的游戏脚本）
   - 内容：教程、示例、API用法验证

3. **Klei 官方论坛**
   - URL: https://forums.kleientertainment.com/forums/forum/79-dont-starve-together-mods-and-tools/
   - 子版块：Tutorials and Guides
   - 精华帖：Don't Starve Together Mods FAQ (98回复，41万浏览)

## 关键技术要点

### DST Lua 环境限制

- **不可用**: `os` 全局表、`_G`、`GetTimeRealMS()`
- **可用**: `io.open()`, `math.*`, `string.*`, `print()`
- **路径**: 必须硬编码绝对路径，不能使用 `os.getenv()`

### 常用 API

```lua
-- 玩家状态
inst.components.health:GetPercent()      -- 生命值 (0-1)
inst.components.hunger:GetPercent()      -- 饥饿值 (0-1)
inst.components.sanity:GetPercent()      -- 理智值 (0-1)
inst:GetPosition()                       -- 返回 x, y, z
inst:GetDisplayName()                    -- 玩家名称

-- 实体查找
TheSim:FindEntities(x, y, z, radius)     -- 范围内实体

-- 世界状态
TheWorld.state.cycles                    -- 天数
TheWorld.state.time                      -- 时间 (0-1)
TheWorld.state.isday / .isnight / .isdusk

-- 钩子函数
AddPlayerPostInit(function(inst) end)    -- 玩家初始化
AddUpdateFunction(function(dt) end)      -- 每帧更新
```

### Mod 目录结构

- **开发目录**: `dst-ai-mod/`
- **实际安装位置**: `C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\dst-ai-mod\`
- **强制启用**: 在 `mods/modsettings.lua` 中添加 `ForceEnableMod("dst-ai-mod")`

### modinfo.lua 最小配置

```lua
name = "DST AI Player"
description = "AI controls your DST character through MCP."
author = "AI Assistant"
version = "1.0.0"
api_version = 10
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true
```

## 通信协议

### state.txt (游戏 → AI)
```json
{"v":1,"hp":0.8,"hu":0.6,"sa":0.9,"x":100,"z":-200,"day":5}
```

### 同步目录
`C:\Users\Administrator\dst-ai-sync\`

## 重启脚本

使用 PowerShell 关闭进程：
```powershell
Stop-Process -Name "dontstarve*" -Force
Stop-Process -Name "node" -Force
```

## 调试命令 (游戏内控制台)

- `ai_status()` - 显示AI状态
- `print()` - 输出到日志
- `ThePlayer` - 当前玩家实例

## 已知问题及解决

| 问题 | 解决方案 |
|------|----------|
| Mod 不显示在列表 | 复制到游戏mods目录 + ForceEnableMod |
| `os` 全局不存在 | 硬编码路径 |
| `_G` 全局不存在 | 使用 `function xxx()` 而非 `_G.xxx = function` |
| 假数据 | 检查state.txt时间戳是否过期 |

## 相关记忆文件

- **[dst-api-reference.md](dst-api-reference.md)** - 详细API快速参考手册

