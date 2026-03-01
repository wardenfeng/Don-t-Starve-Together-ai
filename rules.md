# 项目规则

## 自动测试规则

**重要**: 能自动执行的一律自动执行，不要等待用户反馈。

### 测试流程
```bash
# 打包部署后必须自动测试
npm run pack-and-deploy

# 启动游戏
npm run start-game

# 等待并检查日志
sleep 20
tail -30 "/c/Users/Administrator/Documents/Klei/DoNotStarveTogether/client_log.txt"

# 验证结果
grep -i "LOADING LUA SUCCESS" client_log.txt
```

### 关键验证点
- `LOADING LUA SUCCESS` - Lua 加载成功
- 无 Lua ERROR - 脚本无错误
- `AddPlayerPostInit` 等函数需延迟调用
- `GLOBAL` 需用 `_G` 代替（strict mode）
- DST Lua 不支持: `os.getenv()`, `_G`, `string:trim()`

## 重启规则

**始终使用 `npm run restart` 进行重启游戏**
- 路径: `c:\Users\Administrator\Desktop\Don't Starve Together ai`
- 不要直接用 powershell Stop-Process

## AI 模块使用方式

1. 启动游戏进入世界
2. 打开控制台 (~) 输入命令:
   - `ai_init()` - 初始化 AI 控制器
   - `ai_enable()` - 启用 AI 控制
   - `ai_disable()` - 禁用 AI 控制
   - `ai_status()` - 查看状态
