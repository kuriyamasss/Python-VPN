# SimpleVPN SOCKS5 Server

完整的 SOCKS5 代理服务器实现，支持多并发连接、用户认证、IPv4/IPv6/域名等功能。

## 📋 功能特性

- ✅ 完整的 SOCKS5 协议实现（RFC 1928）
- ✅ 用户名/密码认证
- ✅ 支持 IPv4、IPv6、域名连接
- ✅ 多线程并发连接处理
- ✅ 完整的日志记录系统
- ✅ 可配置的服务器参数
- ✅ 自动错误恢复和日志目录创建
- ✅ 无第三方依赖（仅使用 Python 标准库）

## 🚀 快速开始

### 系统要求

- **操作系统**: Linux/Unix/macOS（支持 systemd）
- **Python 版本**: >= 3.7
- **网络**: 需要开放指定端口（默认 9999）

### 方式一：直接运行（开发模式）

```bash
# 1. 进入服务器目录
cd server

# 2. 编辑配置（可选）
nano config.py

# 3. 直接运行
python3 socks5_server.py
```

### 方式二：安装为系统服务（生产环境）

```bash
# 进入服务器目录
cd server

# 使用管理脚本安装
sudo ./manage.sh

# 选择菜单 "1) 安装 SimpleVPN"
```

## ⚙️ 配置说明

编辑 `config.py` 文件来自定义服务器参数：

### 基本配置

```python
# 监听地址
HOST = '0.0.0.0'  # 0.0.0.0 = 允许外网访问，127.0.0.1 = 仅本地

# 监听端口
PORT = 9999

# 认证用户名和密码
USERNAME = "admin"
PASSWORD = "123456"
```

### 网络配置

```python
# 连接超时时间（秒）
SOCKET_TIMEOUT = 30

# 最大并发连接数
MAX_CONNECTIONS = 100
```

### 日志配置

```python
# 日志文件路径
LOG_FILE = 'logs/socks5_server.log'

# 日志级别: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL = 'INFO'

# 日志缓冲大小（字节）
BUFFER_SIZE = 4096
```

## 🛠️ 常见问题

### ❌ 错误: Address already in use (地址已被占用)

**原因**: 端口被旧进程占用

**解决方案**:

```bash
# 查看占用端口的进程
lsof -i :9999

# 或使用 netstat
netstat -tlnp | grep 9999

# 杀死占用的进程
pkill -9 -f "socks5_server.py"

# 如果使用 systemd，停止服务
sudo systemctl stop socks5

# 清空 TIME_WAIT 状态的连接（可选）
sudo sysctl -w net.ipv4.tcp_fin_timeout=20
```

### ❌ 认证失败

**检查事项**:

1. 确认客户端用户名密码正确
2. 查看服务器日志找到失败原因
3. 验证配置文件中的凭证

```bash
# 查看认证日志
tail -f logs/socks5_server.log | grep "Auth"
```

### ❌ 连接超时

**检查事项**:

1. 确认防火墙未阻止端口
2. 验证目标主机可访问
3. 检查网络连接

```bash
# 测试端口是否监听
telnet 127.0.0.1 9999

# 查看系统日志
sudo tail -f /var/log/syslog | grep python3
```

## 🧪 测试连接

使用提供的测试工具验证服务器：

```bash
# 进入项目根目录
cd ..

# 测试连接（不需要认证）
python3 test_socks5_client.py localhost 9999 google.com 443

# 测试连接（需要认证）
python3 test_socks5_client.py localhost 9999 google.com 443 -u admin -p 123456

# 测试连接到其他服务
python3 test_socks5_client.py localhost 9999 8.8.8.8 53 -u admin -p 123456
```

## 📊 服务管理

### 使用 manage.sh 脚本

```bash
sudo ./manage.sh

# 菜单选项:
# 1) 安装 SimpleVPN
# 2) 启动服务
# 3) 停止服务
# 4) 重启服务
# 5) 查看服务状态
# 6) 实时查看日志
# 7) 查看最近日志
# 8) 编辑配置文件
# 9) 查看当前配置
# 10) 启用开机启动
# 11) 禁用开机启动
# 12) 系统诊断
# 13) 清空日志
# 14) 清空占用的端口
# 15) 完全重置
```

### 使用 systemctl 命令

```bash
# 启动服务
sudo systemctl start socks5

# 停止服务
sudo systemctl stop socks5

# 重启服务
sudo systemctl restart socks5

# 查看状态
sudo systemctl status socks5

# 查看日志
sudo journalctl -u socks5 -f

# 启用开机启动
sudo systemctl enable socks5

# 禁用开机启动
sudo systemctl disable socks5
```

## 📝 日志说明

### 日志位置

- **文件日志**: `logs/socks5_server.log`
- **系统日志**: `sudo journalctl -u socks5`

### 日志级别

| 级别 | 说明 | 示例 |
|------|------|------|
| DEBUG | 调试信息 | 协议细节、缓冲数据 |
| INFO | 一般信息 | 连接成功、认证成功 |
| WARNING | 警告信息 | 连接失败、认证失败、超时 |
| ERROR | 错误信息 | 套接字错误、连接错误 |
| CRITICAL | 严重错误 | 启动失败、致命错误 |

### 查看日志示例

```bash
# 查看最近 100 行日志
tail -100 logs/socks5_server.log

# 实时查看日志
tail -f logs/socks5_server.log

# 过滤认证日志
grep "Auth" logs/socks5_server.log

# 查看错误日志
grep "ERROR\|CRITICAL" logs/socks5_server.log
```

## 🔐 安全建议

1. **修改默认密码**
   ```python
   USERNAME = "your_username"
   PASSWORD = "your_strong_password"
   ```

2. **限制监听地址**
   ```python
   HOST = "192.168.1.100"  # 仅特定网卡
   ```

3. **使用防火墙**
   ```bash
   # 仅允许特定 IP 访问
   sudo ufw allow from 192.168.1.0/24 to any port 9999
   ```

4. **定期更新日志**
   ```bash
   # 设置日志轮换
   logrotate -f /etc/logrotate.d/socks5
   ```

5. **监控连接**
   ```bash
   # 查看活跃连接
   netstat -an | grep :9999
   ```

## 📈 性能优化

### 调整系统参数

```bash
# 增加最大文件描述符数
ulimit -n 65535

# 调整 TCP 参数
sudo sysctl -w net.core.somaxconn=4096
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=4096
```

### 配置文件优化

```python
# 增加最大连接数
MAX_CONNECTIONS = 1000

# 减少超时时间（加快连接释放）
SOCKET_TIMEOUT = 15

# 增加缓冲大小（提高吞吐量）
BUFFER_SIZE = 8192
```

## 🐛 故障排除

### 诊断命令

```bash
# 完整系统诊断
sudo ./manage.sh  # 选择 "12) 系统诊断"

# 检查端口监听
ss -tlnp | grep python3

# 检查进程状态
ps aux | grep socks5_server

# 检查内存使用
top -p $(pgrep -f socks5_server)

# 实时网络监控
watch -n 1 'netstat -an | grep :9999 | wc -l'
```

### 常见错误代码

| 错误码 | 说明 | 解决方案 |
|--------|------|--------|
| 98 | Address already in use | 杀死占用进程或修改端口 |
| 13 | Permission denied | 使用 sudo 或检查文件权限 |
| 111 | Connection refused | 检查服务是否运行 |
| 110 | Connection timeout | 检查防火墙和网络 |
| 104 | Connection reset | 客户端主动断开连接 |

## 📞 技术支持

### 获取帮助

1. 查看日志了解具体错误
2. 运行系统诊断
3. 测试连接是否正常
4. 检查防火墙和网络配置

### 常用命令速查

```bash
# 快速启动测试
cd server && python3 socks5_server.py

# 检查配置
grep "^[A-Z]" config.py | grep -v "^#"

# 查看实时连接数
watch -n 1 'netstat -an | grep :9999 | wc -l'

# 优雅关闭服务
sudo systemctl stop socks5

# 清理僵尸进程
sudo pkill -9 -f "socks5_server.py"
```

## 📄 许可证

开源项目，可自由使用和修改。

## 🔗 相关资源

- [SOCKS5 RFC 1928](https://tools.ietf.org/html/rfc1928)
- [Python Socket 文档](https://docs.python.org/3/library/socket.html)
- [Chrome 客户端说明](../client/README.md)
