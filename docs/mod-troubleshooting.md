# DST Mod 开发故障排除

本文档记录 DST Mod 开发中遇到的常见问题和解决方案。

---

## Mod 不显示在列表中

### 症状
```
Error: modinfo was not available for mod dst-ai-mod
```

### 原因
1. **中文字符** - `modinfo.lua` 包含中文导致 DST 无法解析
2. **引号类型** - 使用双引号 `"` 而不是单引号 `'`
3. **文件编码** - UTF-8 BOM 或其他编码问题

### 解决方案
- `modinfo.lua` 必须使用**纯英文**
- 字符串使用**单引号** `'`
- 确保文件是 ASCII 或 UTF-8 without BOM

### 正确格式
```lua
name = 'DST AI Player'
description = 'AI controls your DST character through MCP protocol.'
author = 'AI Assistant'
version = '1.0.0'

forumthread = ''
api_version = 10

dst_compatible = true
all_clients_require_mod = false
client_only_mod = true
server_filter_tags = {}
```

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

## Mod 目录扫描问题

### 症状
Mod 文件在正确目录但游戏看不到

### Mod 目录位置（优先级）
1. `%USERPROFILE%\Documents\Klei\DoNotStarveTogether\Mods\` （用户目录）
2. 游戏安装目录 `mods\` （备用）

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
⚠️ 正式发布时应该移除 `ForceEnableMod`

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

## 文件命名规范

- **必须使用小写**: `modinfo.lua`, `modmain.lua`
- 大小写敏感: `ModMain.lua` ≠ `modmain.lua`

---

## 调试技巧

### 启用调试输出
```lua
print("[MOD_NAME] Debug message")
```

### 日志位置
- 客户端: `%USERPROFILE%\Documents\Klei\DoNotStarveTogether\client_log.txt`
- 服务器: `Master/server_log.txt`

---

## 开发检查清单

- [ ] `modinfo.lua` 纯英文，使用单引号
- [ ] `modmain.lua` 小写文件名
- [ ] 避免使用沙盒限制的函数（`rawget`, `pcall`, `io`等）
- [ ] 确认客户端或服务器端环境
- [ ] 清除缓存后测试
- [ ] 检查游戏日志确认加载状态
