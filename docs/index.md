# DST AI Player - 文档索引

本目录包含 DST AI Player 项目的所有文档。

---

## 快速开始

- **[项目概述](../CLAUDE.md)** - 系统架构、目录结构、通信协议
- **[API 快速参考](mod-api-reference.md)** - 常用 API 手册

---

## Mod 开发文档

### 核心文档

| 文档 | 说明 |
|------|------|
| **[API 快速参考](mod-api-reference.md)** | DST Mod API 速查手册（玩家/世界/实体） |
| **[故障排除](mod-troubleshooting.md)** | 常见问题和解决方案 |
| **[开发指南](mod-development-guide.md)** | Mod 开发完整教程 |
| **[通信协议](communication-protocol.md)** | 游戏与 AI 服务器的数据格式 |
| **[系统架构](mod-architecture.md)** | 文件通信架构详解 |

### 脚本和工具

| 文档 | 说明 |
|------|------|
| **[脚本说明](scripts.md)** | 所有 npm 脚本的功能和用法 |

---

## 外部资源

### 官方文档

- **[DST API Docs (Fandom)](https://dst-api-docs.fandom.com/wiki/Home)** - 完整的组件列表和 API 参考
- **[DST API Web Docs (GitHub)](https://github.com/vietnd69/dst-api-webdocs)** - 教程和示例
- **[Klei Modding Forum](https://forums.kleientertainment.com/forums/forum/79-dont-starve-together-mods-and-tools/)** - 官方 Modding 论坛

### 学习路径

1. 阅读本项目的 [CLAUDE.md](../CLAUDE.md) 了解系统架构
2. 阅读 [开发指南](mod-development-guide.md) 学习 Mod 开发基础
3. 使用 [API 快速参考](mod-api-reference.md) 查阅函数
4. 遇到问题时查看 [故障排除](mod-troubleshooting.md)

---

## 文档结构

```
docs/
├── index.md                      # 本文件 - 文档导航
├── mod-api-reference.md          # API 快速参考
├── mod-troubleshooting.md        # 故障排除
├── mod-development-guide.md      # 开发指南
├── communication-protocol.md     # 通信协议
├── mod-architecture.md           # 系统架构
└── scripts.md                    # 脚本说明
```

---

## 更新日志

| 日期 | 文档 | 更新内容 |
|------|------|----------|
| 2025-03-01 | 全部 | 创建完整文档结构 |
