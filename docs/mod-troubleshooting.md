# DST Mod 开发故障排除

本文档记录 DST Mod 开发中遇到的常见问题和解决方案。

---

## Mod 不显示在列表中

### 症状
```
Error: modinfo was not available for mod dst-ai-mod
```

### 原因
1. **引号类型** - 必须使用**双引号** `"` 而不是单引号 `'`
2. **文件编码** - 需要使用 **CRLF** 行尾格式（Windows 标准）
3. **安装位置错误** - 本地模组应安装在游戏目录

### 解决方案
- `modinfo.lua` 字符串必须使用**双引号** `"`
- 文件行尾使用 **CRLF** (`\r\n`) 格式
- 本地模组安装在游戏 `mods\` 目录（与 workshop 相同位置）

### 正确格式
```lua
name = "DST AI Player"
description = "AI controls your DST character through MCP protocol."
author = "AI Assistant"
version = "1.0.0"

forumthread = ""
api_version = 10

dst_compatible = true
all_clients_require_mod = false
client_only_mod = true
server_filter_tags = {}
```

### 格式要求总结
| 项目 | 要求 |
|------|------|
| 字符串引号 | **双引号** `"` |
| 行尾格式 | **CRLF** (`\r\n`) |
| 文件编码 | UTF-8 |
| modinfo.lua | 必须纯英文 |
| 文件名 | 小写：`modinfo.lua`, `modmain.lua` |

---

## Lua 运行时错误

### 症状
```
attempt to call global 'rawget' (a nil value)
attempt to call global 'pcall' (a nil value)
attempt to index global 'io' (a nil value)
```

### 原因
DST Mod 运行在**沙盒环境**中，许多 Lua 全局函数不可用

### 不可用的全局变量
| 函数 | 可用性 |
|------|--------|
| `rawget()` | ❌ 不可用 |
| `pcall()` | ❌ 不可用 |
| `_G` | ❌ 不可用或受限 |
| `io` | ❌ 服务器端不可用 |
| `os` | ❌ 大部分不可用 |
| `GetTimeRealMS()` | ❌ 不可用 |

### 解决方案
- 设置 `client_only_mod = true` 使用客户端环境（限制较少）
- 避免使用沙盒限制的函数
- 直接使用可用的 API，不要用 pcall 包装

---

## Mod 目录和安装位置

### 本地 Mod 安装位置
**游戏目录**（与 workshop 模组相同）：
```
C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\dst-ai-mod\
```

**⚠️ 注意**：
- ~~用户目录 `Documents\Klei\DoNotStarveTogether\Mods\`~~ - **不用于本地模组**
- 本地模组必须放在游戏 `mods\` 目录才能被扫描

### 目录结构
```
Don't Starve Together\mods\
├── workshop-1608191708\    # Steam 创意工坊模组
├── workshop-362175979\     # Steam 创意工坊模组
├── dst-ai-mod\             # 本地模组（开发中）
│   ├── modinfo.lua         # 模组元数据（必需）
│   └── modmain.lua         # 模组入口（必需）
└── modsettings.lua         # 开发配置（ForceEnableMod）
```

### 清除缓存
```
删除：Documents\Klei\DoNotStarveTogether\<cluster>\client_save\modindex
删除：Documents\Klei\DoNotStarveTogether\<cluster>\client_save\boot_modindex
```

---

## 开发时强制启用 Mod

### 位置
`Don't Starve Together\mods\modsettings.lua`

### 配置
```lua
ForceEnableMod("dst-ai-mod")
EnableModDebugPrint()        -- 显示调试信息
DisableLocalModWarning()     -- 禁用本地 Mod 警告
```

### 注意
⚠️ 正式发布时应该移除 `ForceEnableMod`，让用户手动启用

---

## 客户端 vs 服务器端 Mod

### 客户端 Mod (`client_only_mod = true`)
- ✅ 沙盒限制较少
- ✅ 可以使用更多 Lua API
- ✅ 适合 UI、显示类功能
- ❌ 无法直接操作游戏逻辑
- ❌ 无法与其他玩家同步

### 服务器端 Mod (`all_clients_require_mod = true`)
- ✅ 可以操作游戏世界逻辑
- ✅ 所有玩家同步
- ❌ 严格的沙盒环境
- ❌ 许多 Lua 函数不可用
- ❌ 需要所有玩家安装

---

## Mod 卸载和清理

### 卸载时需要清理的内容
1. **模组文件** - 游戏目录 `mods\dst-ai-mod\`
2. **同步目录** - `%USERPROFILE%\dst-ai-sync\`
3. **ForceEnableMod** - `mods\modsettings.lua` 中的配置
4. **modoverrides.lua** - 存档目录中的模组配置
5. **modindex 缓存** - 让游戏重新扫描模组

### 为什么游戏崩溃后无法启动
如果 `modsettings.lua` 中有 `ForceEnableMod("dst-ai-mod")`，但模组文件已被删除：
```
WARNING: Force-enabling mod 'dst-ai-mod' from modsettings.lua!
Error: mod isn't known dst-ai-mod
[scripts/mods.lua]:518: attempt to index field 'modinfo' (a nil value)
```

**解决方案**：卸载时必须清理 `ForceEnableMod` 配置

---

## 常用 API

### 玩家状态
```lua
inst.components.health:GetPercent()      -- 生命值 0-1
inst.components.hunger:GetPercent()      -- 饥饿值 0-1
inst.components.sanity:GetPercent()      -- 理智值 0-1
inst:GetPosition()                       -- x, y, z
```

### 世界状态
```lua
TheWorld.state.cycles                    -- 天数
TheWorld.state.isday                     -- 是否白天
TheWorld.state.isnight                   -- 是否夜晚
```

### 实体查找
```lua
TheSim:FindEntities(x, y, z, radius)     -- 查找范围内实体
```

---

## 调试技巧

### 启用调试输出
```lua
print("[MOD_NAME] Debug message")
```

### 日志位置
- 客户端: `%USERPROFILE%\Documents\Klei\DoNotStarveTogether\client_log.txt`
- 服务器: `Master/server_log.txt`

### 常见日志信息
```
[00:00:03]: WARNING: Force-enabling mod 'dst-ai-mod' from modsettings.lua!
[00:00:03]: ModIndex: Beginning normal load sequence.
[00:00:03]: Error: mod isn't known dst-ai-mod
```

---

## 开发检查清单

- [ ] `modinfo.lua` 使用双引号
- [ ] `modinfo.lua` 使用 CRLF 行尾
- [ ] 模组安装在游戏 `mods\` 目录
- [ ] `modmain.lua` 小写文件名
- [ ] 避免使用沙盒限制的函数（`rawget`, `pcall`, `io`等）
- [ ] 确认客户端或服务器端环境
- [ ] 清除缓存后测试
- [ ] 检查游戏日志确认加载状态
- [ ] 卸载时清理 `ForceEnableMod` 配置
