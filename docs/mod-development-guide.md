# DST Mod 开发指南

本文档介绍 Don't Starve Together Mod 开发的基础知识和最佳实践。

---

## 目录

1. [开发环境设置](#开发环境设置)
2. [Mod 基本结构](#mod-基本结构)
3. [modinfo.lua 配置](#modinfolua-配置)
4. [modmain.lua 入口](#modmainlua-入口)
5. [常用钩子](#常用钩子)
6. [组件系统](#组件系统)
7. [开发工作流](#开发工作流)
8. [发布 Mod](#发布-mod)

---

## 开发环境设置

### 必需工具

- **Don't Starve Together** - 游戏本体
- **代码编辑器** - VS Code 推荐（安装 Lua 扩展）
- **文本编辑器** - 支持换行符转换（Notepad++ 等）

### 目录结构

```
Don't Starve Together/
├── mods/                      # Mod 安装目录
│   ├── dst-ai-mod/           # 你的 Mod
│   │   ├── modinfo.lua       # Mod 元数据（必需）
│   │   └── modmain.lua       # Mod 入口（必需）
│   └── modsettings.lua       # 开发配置

Documents/Klei/
└── DoNotStarveTogether/
    └── client_log.txt        # 客户端日志
```

### 开发配置

在 `mods/modsettings.lua` 中添加：

```lua
ForceEnableMod("dst-ai-mod")        -- 强制启用 Mod
EnableModDebugPrint()               -- 启用调试输出
DisableLocalModWarning()            -- 禁用本地 Mod 警告
```

---

## Mod 基本结构

### 最小 Mod

```
your-mod/
├── modinfo.lua       # Mod 信息（必需）
└── modmain.lua       # 主逻辑（必需）
```

### 完整 Mod 结构

```
your-mod/
├── modinfo.lua           # Mod 信息
├── modmain.lua           # 入口文件
├── scripts/              # Lua 脚本
│   ├── main/
│   │   └── functions.lua
│   └── components/       # 自定义组件
├── images/               # 图片资源
│   └── inventoryimages/
├── anim/                 # 动画资源
└── modexport.lua         # 导出配置
```

---

## modinfo.lua 配置

### 必需字段

```lua
name = "Your Mod Name"           -- Mod 名称
description = "Mod description"  -- 描述
author = "Your Name"             -- 作者
version = "1.0.0"                -- 版本号
```

### 格式要求

| 项目 | 要求 |
|------|------|
| 字符串引号 | **必须使用双引号** `"` |
| 行尾格式 | **CRLF** (`\r\n`) |
| 文件编码 | UTF-8 |
| 字符内容 | 纯英文（中文字符会导致解析失败） |
| 文件名 | 小写 `modinfo.lua` |

### 完整示例

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

icon_atlas = "modicon.xml"
icon = "modicon.tex"

configuration_options = {}
```

### 关键配置说明

| 配置 | 说明 |
|------|------|
| `api_version` | DST API 版本，当前为 10 |
| `dst_compatible` | 是否兼容联机版 |
| `all_clients_require_mod` | 是否所有玩家都需要安装 |
| `client_only_mod` | 是否仅客户端运行 |
| `icon_atlas/icon` | Mod 图标 |

---

## modmain.lua 入口

### 基本结构

```lua
-- dst-ai-mod/modmain.lua

-- 使用局部命名空间，避免污染全局
local ModName = "DST AI Player"

-- 简单输出，证明 Mod 已加载
print("[" .. ModName .. "] Mod loaded!")
```

### 常用初始化模式

```lua
-- 1. 修改玩家
AddPlayerPostInit(function(inst)
    -- 在玩家初始化后执行
    print("Player initialized:", inst:GetDisplayName())

    -- 添加组件
    if not inst.components.mycomponent then
        inst:AddComponent("mycomponent")
    end
end)

-- 2. 修改世界
AddWorldPostInit(function(inst)
    -- 在世界初始化后执行
    print("World initialized")
end)

-- 3. 修改特定 Prefab
AddPrefabPostInit("berrybush", function(inst)
    -- 修改浆果丛
    print("Berrybush modified")
end)

-- 4. 添加自定义 Prefab
Prefab("my_prefab", function()
    -- 创建自定义实体
end)
```

---

## 常用钩子

### 玩家钩子

```lua
-- 玩家初始化后
AddPlayerPostInit(function(inst)
    -- 添加标签
    inst:AddTag("my_tag")

    -- 监听事件
    inst:ListenForEvent("onhitother", function(inst, data)
        print("Hit something!")
    end)
end)
```

### 世界钩子

```lua
-- 世界初始化后
AddWorldPostInit(function(inst)
    -- 添加组件
    inst:AddComponent("world_component")
end)
```

### 更新钩子

```lua
-- 每帧更新
AddUpdateFunction(function(dt)
    -- dt: 帧间隔时间（秒）
    -- 注意：谨慎使用，影响性能
end)
```

### 组件钩子

```lua
-- 组件初始化后
AddComponentPostInit("health", function(cmp)
    -- 包装原有方法
    local OldSetPercent = cmp.SetPercent
    cmp.SetPercent = function(self, percent, cause)
        print("Health set to:", percent)
        OldSetPercent(self, percent, cause)
    end
end)
```

---

## 组件系统

DST 使用组件-实体系统 (ECS)，实体通过组合组件获得功能。

### 常用玩家组件

```lua
inst.components.health      -- 生命值
inst.components.hunger      -- 饥饿值
inst.components.sanity      -- 理智值
inst.components.locomotor   -- 移动
inst.components.inventory   -- 背包
inst.components.combat      -- 战斗
inst.components.eater       -- 进食
inst.components.builder     -- 建造
inst.components.sanity      -- 理智
```

### 检查组件存在

```lua
if inst.components.health then
    local hp = inst.components.health:GetPercent()
end
```

### 自定义组件

```lua
-- scripts/components/mycomponent.lua

local MyComponent = Class(function(self, inst)
    self.inst = inst
    self.data = 0
end)

function MyComponent:OnSave()
    return {data = self.data}
end

function MyComponent:OnLoad(data)
    if data then
        self.data = data.data
    end
end

function MyComponent:SetData(value)
    self.data = value
end

function MyComponent:GetData()
    return self.data
end

return MyComponent
```

---

## 开发工作流

### 1. 修改代码

编辑 `modmain.lua` 或相关文件

### 2. 安装到游戏目录

```bash
npm run install-mod
```

或手动复制到：
```
C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\
```

### 3. 清除缓存

删除以下文件：
```
Documents\Klei\DoNotStarveTogether\<cluster>\client_save\modindex
Documents\Klei\DoNotStarveTogether\<cluster>\client_save\boot_modindex
```

### 4. 启动游戏测试

```bash
npm run start-game
```

### 5. 查看日志

```
Documents\Klei\DoNotStarveTogether\client_log.txt
```

---

## 调试技巧

### 使用 print

```lua
print("[MOD_NAME] Debug message:", variable)
```

### 使用控制台

游戏内按 `~` 打开控制台：

```lua
-- 显示玩家位置
print(ThePlayer:GetPosition())

-- 显示附近实体
TheSim:FindEntities(ThePlayer:GetPosition():Get())

-- 执行 Mod 函数（需要暴露到全局）
ai_status()
```

### 查找实体

```lua
-- 查找最近的树
local x, y, z = ThePlayer:GetPosition():Get()
local trees = TheSim:FindEntities(x, y, z, 20, nil, nil, {"tree"})
for i, ent in ipairs(trees) do
    print("Tree at:", ent:GetPosition())
end
```

---

## 发布 Mod

### Steam 创意工坊

1. 使用 SteamDK 工具上传
2. 或使用 Steam 创意工坊网站
3. 准备好 Mod 图标 (512x512)
4. 编写详细描述和使用说明

### 本地发布

直接分发 Mod 文件夹，用户安装到 `mods/` 目录。

---

## 最佳实践

1. **使用命名空间** - 避免全局变量污染
2. **检查组件存在** - 使用前检查 `if inst.components.xxx then`
3. **谨慎使用更新钩子** - 每帧执行影响性能
4. **提供配置选项** - 使用 `configuration_options`
5. **编写清晰注释** - 便于后续维护
6. **测试多人环境** - 确保 Mod 在服务器上正常工作
7. **版本号管理** - 遵循语义化版本

---

## 相关资源

- **[API 快速参考](mod-api-reference.md)** - 速查手册
- **[故障排除](mod-troubleshooting.md)** - 常见问题解决
- **[DST API Docs](https://dst-api-docs.fandom.com/wiki/Home)** - 官方 API 文档
- **[Klei Modding Forum](https://forums.kleientertainment.com/forums/forum/79-dont-starve-together-mods-and-tools/)** - 官方论坛
