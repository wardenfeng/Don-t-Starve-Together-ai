# DST AI Player - 文档索引

本目录包含 DST AI Player 项目的所有文档。

---

## 快速开始

- **[项目概述](../CLAUDE.md)** - 系统架构、目录结构、通信协议

---

## Mod 开发文档

### 核心 API 文档

| 文档 | 说明 |
|------|------|
| **[API 快速参考](mod-api-reference.md)** | DST Mod API 速查手册（玩家/世界/实体） |
| **[客户端 API 完全参考](client-api-reference.md)** | 客户端 vs 服务器端 API 可用性详解 |
| **[文件 I/O 指南](client-file-io-guide.md)** | 文件读写完全指南（含 dst_scripts 源码证据） |

### 开发指南

| 文档 | 说明 |
|------|------|
| **[Mod 开发指南](mod-development-guide.md)** | Mod 开发完整教程 |
| **[故障排除](mod-troubleshooting.md)** | 常见问题和解决方案 |

### 架构和通信

| 文档 | 说明 |
|------|------|
| **[系统架构](mod-architecture.md)** | 文件通信架构详解（含技术选择依据） |
| **[通信协议](communication-protocol.md)** | 游戏与 AI 服务器的数据格式 |
| **[官方脚本参考](dst-scripts-reference.md)** | dst_scripts 完全分析 |

### 工具和脚本

| 文档 | 说明 |
|------|------|
| **[脚本说明](scripts.md)** | 所有 npm 脚本的功能和用法 |

---

## 重要提示

### 客户端 Mod 文件 I/O

| 环境 | `io` 可用性 | `ThePlayer` |
|------|------------|-------------|
| **客户端** | ✅ 可用 | ✅ 可用 |
| **服务器端** | ⚠️ 需验证 | ❌ nil |

**证据来源**:
- [dst_scripts/class.lua:136](../dst_scripts/class.lua#L136) - `io.open()` 官方使用
- [dst_scripts/createstringspo.lua:258](../dst_scripts/createstringspo.lua#L258) - 文件写入官方使用

**关键规则**: `AddPlayerPostInit` 在客户端和服务器端都会执行，必须检查环境后再使用 `io`！

```lua
local function IsClient()
    return ThePlayer ~= nil or (TheNet and not TheNet:GetIsServer())
end

AddPlayerPostInit(function(player)
    if not IsClient() then return end  -- 重要！

    local file = io.open("C:\\dst-ai-sync\\state.txt", "w")
    -- ...
end)
```

---

## 外部资源

### 官方文档

- **[DST API Docs (Fandom)](https://dst-api-docs.fandom.com/wiki/Home)** - 完整的组件列表和 API 参考
- **[DST API Web Docs (GitHub)](https://github.com/vietnd69/dst-api-webdocs)** - 教程和示例
- **[Klei Modding Forum](https://forums.kleientertainment.com/forums/forum/79-dont-star-together-mods-and-tools/)** - 官方 Modding 论坛

---

## 学习路径

1. **系统理解**: 阅读 [CLAUDE.md](../CLAUDE.md) 了解系统架构
2. **API 基础**: 阅读 [API 快速参考](mod-api-reference.md)
3. **环境差异**: 阅读 [客户端 API 完全参考](client-api-reference.md)
4. **文件操作**: 阅读 [文件 I/O 指南](client-file-io-guide.md)
5. **官方脚本**: 阅读 [官方脚本参考](dst-scripts-reference.md)
6. **开发实践**: 阅读 [Mod 开发指南](mod-development-guide.md)
7. **问题解决**: 遇到问题时查看 [故障排除](mod-troubleshooting.md)

---

## 文档结构

```
docs/
├── index.md                      # 本文件 - 文档导航
├── mod-api-reference.md          # API 快速参考
├── client-api-reference.md       # 客户端 API 完全参考
├── client-file-io-guide.md       # 文件 I/O 指南（已更新）
├── mod-troubleshooting.md        # 故障排除
├── mod-development-guide.md      # 开发指南
├── communication-protocol.md     # 通信协议（已更新）
├── mod-architecture.md           # 系统架构（已更新）
├── dst-scripts-reference.md      # 官方脚本参考（新增）
└── scripts.md                    # 脚本说明
```

---

## 更新日志

| 日期 | 文档 | 更新内容 |
|------|------|----------|
| 2025-03-01 | dst-scripts-reference.md | **新增**: 官方脚本完全分析 |
| 2025-03-01 | client-file-io-guide.md | 更新: 添加 dst_scripts 源码证据 |
| 2025-03-01 | mod-architecture.md | 更新: 添加通信方式选择的技术依据 |
| 2025-03-01 | communication-protocol.md | 更新: 添加技术依据和证据链接 |
| 2025-03-01 | 全部 | 清除推测信息，所有结论均有源码支持 |
