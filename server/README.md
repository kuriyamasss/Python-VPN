# SOCKS5 Server

Python 实现的高效 SOCKS5 代理服务器，适合 Ubuntu/Debian Linux 部署。

## 📋 特性

- ✅ 完整的 SOCKS5 协议实现 (RFC 1928/1929)
- ✅ 用户名/密码认证
- ✅ 多线程并发连接处理
- ✅ 连接超时和资源管理
- ✅ 结构化日志记录
- ✅ SystemD 集成
- ✅ Supervisor 进程管理支持
- ✅ 易于部署和维护

## 🚀 快速开始

### 开发模式 (本地测试)

```bash
cd server
python3 socks5_server.py
```

### 后台运行

```bash
cd server/scripts
./start.sh --daemon
```

### 检查状态

```bash
cd server/scripts
./status.sh
```

## 📦 安装到 Ubuntu/Debian

### 自动安装 (推荐)

```bash
sudo server/scripts/install.sh
```

这会：
- 检查/安装 Python 3
- 创建 `socks5` 服务用户
- 复制文件到 `/opt/simplevpn/server`
- 安装 systemd 服务
- 创建日志目录

### 手动安装

```bash
# 安装 Python 3
sudo apt-get install python3

# 创建目录
sudo mkdir -p /opt/simplevpn/server
sudo chown -R $USER:$USER /opt/simplevpn

# 复制文件
cp -r . /opt/simplevpn/server/

# 安装 systemd 服务
sudo cp /opt/simplevpn/server/scripts/socks5.service /etc/systemd/system/
sudo systemctl daemon-reload
```

## ⚙️ 配置

编辑 `config.py` 修改配置：

```python
# 监听地址
HOST = '0.0.0.0'  # 所有接口

# 监听端口
PORT = 9999

# 认证信息
USERNAME = "admin"
PASSWORD = "123456"

# 最大并发连接
MAX_CONNECTIONS = 100

# 超时时间 (秒)
SOCKET_TIMEOUT = 30
```

## 🎮 系统管理 (SystemD)

### 基本命令

```bash
# 启动服务
sudo systemctl start socks5

# 停止服务
sudo systemctl stop socks5

# 重启服务
sudo systemctl restart socks5

# 查看状态
sudo systemctl status socks5

# 启用开机自启
sudo systemctl enable socks5

# 禁用开机自启
sudo systemctl disable socks5
```

### 查看日志

```bash
# 实时查看日志
sudo journalctl -u socks5 -f

# 查看最后 100 行
sudo journalctl -u socks5 -n 100

# 查看特定时间范围的日志
sudo journalctl -u socks5 --since "2 hours ago"
```

## 🛠️ 脚本管理

在 `scripts/` 目录下有可用脚本（Linux/macOS）：

```bash
# 启动服务器（后台）
./scripts/start.sh --daemon

# 停止服务器
./scripts/stop.sh

# 重启服务器
./scripts/restart.sh

# 检查状态
./scripts/status.sh
```

## 📊 日志

日志位置：
- **应用日志**: `logs/socks5_server.log`
- **SystemD 日志**: 通过 `journalctl -u socks5` 查看
- **启动日志**: `logs/startup.log`（仅后台模式）

### 日志级别

在 `config.py` 中配置：
```python
LOG_LEVEL = 'INFO'  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

## 🧪 测试连接

使用提供的测试工具：

```bash
cd ..
python3 test_socks5_client.py localhost 9999 google.com 443 -u admin -p 123456
```

**预期输出**：
```
[✓] Connected to proxy
[✓] Authentication successful
[✓] SUCCESS
```

## 📝 使用示例

### 作为系统服务

```bash
# 安装
sudo server/scripts/install.sh

# 启动
sudo systemctl start socks5

# 查看日志
sudo journalctl -u socks5 -f
```

### 在现有应用中集成

其他应用可以配置 SOCKS5 代理连接到：
- 地址: 服务器 IP
- 端口: 9999
- 用户名: admin
- 密码: 123456

## 🔒 安全建议

1. **修改默认凭证** - 编辑 `config.py` 更改用户名和密码
2. **限制访问** - 使用防火墙限制允许的 IP：
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 9999
   ```
3. **使用非 root 用户** - 服务自动以 `socks5` 用户运行
4. **监控日志** - 定期检查异常连接
5. **限制并发** - 根据硬件调整 `MAX_CONNECTIONS`

## ❓ 常见问题

### Q: 如何验证服务器是否运行？

```bash
sudo systemctl status socks5
# 或
sudo netstat -tlnp | grep 9999
```

### Q: 如何查看实时日志？

```bash
sudo journalctl -u socks5 -f
```

### Q: 如何修改监听端口？

编辑 `config.py` 修改 `PORT` 值，然后重启：
```bash
sudo systemctl restart socks5
```

### Q: 如何禁用认证？

编辑 `config.py`：
```python
USERNAME = None
PASSWORD = None
```

### Q: 如何卸载服务？

```bash
sudo systemctl stop socks5
sudo systemctl disable socks5
sudo rm /etc/systemd/system/socks5.service
sudo systemctl daemon-reload
sudo rm -rf /opt/simplevpn
```

## 📦 Supervisor 替代方案

如果不想使用 systemd，可以使用 Supervisor：

```bash
# 安装 supervisor
sudo apt-get install supervisor

# 复制配置
sudo cp scripts/socks5.conf /etc/supervisor/conf.d/

# 重新加载
sudo supervisorctl reread
sudo supervisorctl update

# 管理
sudo supervisorctl start socks5
sudo supervisorctl stop socks5
sudo supervisorctl restart socks5
```

## 🐳 Docker 支持（可选）

构建 Docker 镜像：
```bash
docker build -t simplevpn-socks5 .
docker run -d -p 9999:9999 simplevpn-socks5
```

## 📚 更多信息

- [SOCKS5 RFC 1928](https://tools.ietf.org/html/rfc1928)
- [Username/Password Authentication RFC 1929](https://tools.ietf.org/html/rfc1929)
- [SystemD 文档](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

## 📄 许可证

开源项目，可自由使用和修改。
