## 1. Mod 修改

- [ ] 1.1 简化 modmain.lua 为纯 File I/O 实现
- [ ] 1.2 实现 AIController 类（状态写入、命令读取、动作执行）
- [ ] 1.3 添加全局控制台函数 (ai_enable, ai_disable, ai_status)
- [ ] 1.4 移除日志输出相关代码
- [ ] 1.5 测试文件读写功能

## 2. MCP 服务器简化

- [ ] 2.1 更新 game-state.ts，移除日志解析逻辑
- [ ] 2.2 确保 file-watcher.ts 作为主要数据源
- [ ] 2.3 保留 log-parser.ts 作为可选备份（标记为 deprecated）
- [ ] 2.4 更新 build 和测试脚本

## 3. 文档更新

- [ ] 3.1 更新 CLAUDE.md 说明新架构
- [ ] 3.2 添加 RAM disk 配置说明
- [ ] 3.3 更新 README.md 通信方式描述
- [ ] 3.4 创建 migration guide（如果需要）

## 4. 测试验证

- [ ] 4.1 单元测试：Mod 文件写入
- [ ] 4.2 单元测试：Mod 文件读取
- [ ] 4.3 集成测试：Mod → MCP 状态传递
- [ ] 4.4 集成测试：MCP → Mod 命令传递
- [ ] 4.5 性能测试：文件 I/O 延迟测量
- [ ] 4.6 端到端测试：游戏内 AI 控制

## 5. 清理工作

- [ ] 5.1 删除不再使用的 direct_controller.lua
- [ ] 5.2 清理 dst_scripts 中的测试文件
- [ ] 5.3 更新 gitignore 排除临时文件
