# SimpleVPN 2.0 - 完整的 SOCKS5 代理解决方案

简单易用的 SOCKS5 代理套件，包含 Chrome 浏览器扩展和 Python SOCKS5 服务器。为 Ubuntu/Debian 部署优化。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/)
[![Chrome](https://img.shields.io/badge/chrome-90+-green.svg)](https://www.google.com/chrome/)

## 📁 项目结构

```
Python-VPN/
├── client/                          # Chrome 扩展
│   ├── background.js               # 后台服务
│   ├── manifest.json              # 扩展清单
│   ├── popup.html                 # 用户界面
│   ├── popup.js                   # 交互逻辑
│   ├── icon.png                   # 扩展图标
│   └── README.md                  # 扩展文档
│
├── server/                          # SOCKS5 服务器
│   ├── socks5_server.py           # 服务器主程序
│   ├── config.py                  # 配置文件
│   ├── requirements.txt           # 依赖
│   ├── README.md                  # 服务器文档
│   ├── logs/                      # 日志目录
│   └── scripts/
│       ├── start.sh               # 启动脚本
│       ├── stop.sh                # 停止脚本
│       ├── restart.sh             # 重启脚本
│       ├── status.sh              # 状态检查
│       ├── install.sh             # Ubuntu 安装脚本
│       ├── socks5.service         # systemd 服务文件
│       └── socks5.conf            # supervisor 配置
│
├── test_socks5_client.py           # SOCKS5 测试工具
├── create_icons.py                # 图标生成工具
├── start_server.ps1               # Windows 启动脚本
├── README.md                      # 本文件
├── QUICKSTART.md                  # 快速开始指南
└── IMPROVEMENTS.md                # 改进详单
```

## ✨ 核心特性

### 🖥️ 服务器（server/）
- ✅ 完整的 SOCKS5 协议实现 (RFC 1928/1929)
- ✅ 用户名/密码认证支持
- ✅ 多线程并发连接处理（最多 100 个）
- ✅ 连接超时和资源管理
- ✅ 结构化日志记录（文件 + 控制台）
- ✅ SystemD 集成（Ubuntu/Debian）
- ✅ Supervisor 支持
- ✅ 配置管理和启动脚本

### 🔌 扩展（client/）
- ✅ Chrome 原生集成
- ✅ 现代化用户界面
- ✅ 配置自动保存
- ✅ 错误提示和诊断
- ✅ 实时连接状态显示
- ✅ 多标签页自动同步

## 🚀 快速开始

### 一、安装服务器（Ubuntu/Debian）

**自动安装（推荐）：**
```bash
sudo server/scripts/install.sh
```

**或手动启动：**
```bash
cd server
python3 socks5_server.py
```

### 二、安装 Chrome 扩展

1. 打开 Chrome，访问 `chrome://extensions/`
2. 启用右上角 **"开发者模式"**
3. 点击 **"加载已解压的扩展程序"**
4. 选择 `client` 文件夹

### 三、配置和连接

1. 点击 Chrome 扩展图标
2. 填写服务器信息：
   - Server IP: `127.0.0.1` 或服务器 IP
   - Port: `9999`
   - Username: `admin`
   - Password: `123456`
3. 点击 **"CONNECT"**

### ✓ 完成！浏览器流量现已通过 SOCKS5 代理转发

## 📖 详细文档

- [服务器文档](server/README.md) - 服务器安装、配置、管理
- [扩展文档](client/README.md) - 扩展使用和故障排除
- [快速开始指南](QUICKSTART.md) - 5分钟快速开始
- [改进详单](IMPROVEMENTS.md) - 所有改进和增强功能

## ⚙️ 配置

### 服务器配置 (`server/config.py`)

```python
# 监听地址
HOST = '0.0.0.0'          # 所有网卡

# 监听端口
PORT = 9999

# 认证
USERNAME = "admin"
PASSWORD = "123456"

# 并发连接
MAX_CONNECTIONS = 100

# 超时
SOCKET_TIMEOUT = 30
```

### 系统管理（systemd）

```bash
# 启动
sudo systemctl start socks5

# 停止
sudo systemctl stop socks5

# 重启
sudo systemctl restart socks5

# 查看状态
sudo systemctl status socks5

# 查看日志
sudo journalctl -u socks5 -f
```

## 🧪 测试

### 使用测试客户端

```bash
python3 test_socks5_client.py localhost 9999 google.com 443 -u admin -p 123456
```

**预期输出：**
```
[✓] Connected to proxy
[✓] Authentication successful
[✓] SUCCESS
[✓] Test completed successfully!
```

## 📊 部署指南

### Ubuntu/Debian 生产部署

```bash
# 1. 克隆或下载项目
git clone <repo-url> ~/simplevpn
cd ~/simplevpn

# 2. 运行安装脚本
sudo server/scripts/install.sh

# 3. 编辑配置
sudo nano /opt/simplevpn/server/config.py

# 4. 启动服务
sudo systemctl start socks5
sudo systemctl enable socks5

# 5. 验证运行
sudo systemctl status socks5
sudo journalctl -u socks5 -f
```

### Docker（可选）

```bash
# 构建镜像
docker build -f server/Dockerfile -t simplevpn-socks5 .

# 运行容器
docker run -d \
  -p 9999:9999 \
  -v $(pwd)/server/logs:/opt/simplevpn/server/logs \
  --name socks5 \
  simplevpn-socks5
```

## 🔒 安全建议

1. **修改默认凭证**
   ```bash
   sudo nano /opt/simplevpn/server/config.py
   # 修改 USERNAME 和 PASSWORD
   sudo systemctl restart socks5
   ```

2. **限制访问**
   ```bash
   # 仅允许特定 IP 访问
   sudo ufw allow from 192.168.1.0/24 to any port 9999
   sudo ufw allow from 203.0.113.0/24 to any port 9999
   ```

3. **使用防火墙**
   ```bash
   sudo ufw enable
   sudo ufw status
   ```

4. **监控日志**
   ```bash
   sudo journalctl -u socks5 -f
   ```

5. **定期更新**
   ```bash
   sudo apt-get update && sudo apt-get upgrade
   ```

## 📋 常见问题

### Q: 如何在 Ubuntu 上安装？

**A:** 使用提供的安装脚本：
```bash
sudo server/scripts/install.sh
```

### Q: 如何修改监听端口？

**A:** 编辑 `config.py` 修改 `PORT` 值，然后重启：
```bash
sudo nano /opt/simplevpn/server/config.py
sudo systemctl restart socks5
```

### Q: 如何查看实时日志？

**A:** 使用 systemd 日志查看器：
```bash
sudo journalctl -u socks5 -f
```

### Q: 如何禁用认证？

**A:** 编辑 `config.py`：
```python
USERNAME = None
PASSWORD = None
```

### Q: 如何卸载？

**A:**
```bash
sudo systemctl stop socks5
sudo systemctl disable socks5
sudo rm /etc/systemd/system/socks5.service
sudo systemctl daemon-reload
sudo rm -rf /opt/simplevpn
```

### Q: 连接失败怎么办？

**A:** 检查以下几点：
1. 服务器运行状态：`sudo systemctl status socks5`
2. 端口监听：`sudo netstat -tlnp | grep 9999`
3. 防火墙规则：`sudo ufw status`
4. 日志信息：`sudo journalctl -u socks5 -n 50`

## 🛠️ 脚本参考

### 服务器脚本

| 脚本 | 功能 |
|------|------|
| `start.sh` | 启动服务器 |
| `stop.sh` | 停止服务器 |
| `restart.sh` | 重启服务器 |
| `status.sh` | 检查状态 |
| `install.sh` | Ubuntu/Debian 自动安装 |

### 使用示例

```bash
cd server/scripts

# 启动服务器（后台运行）
./start.sh --daemon

# 检查运行状态
./status.sh

# 停止服务器
./stop.sh

# 重启服务器
./restart.sh
```

## 📊 性能指标

| 指标 | 详情 |
|------|------|
| **最大并发连接** | 100（可配置） |
| **连接超时** | 30 秒（可配置） |
| **支持协议** | SOCKS5 v5 |
| **认证方式** | 用户名/密码 (RFC 1929) |
| **转发方式** | I/O 多路复用 (select) |

## 📚 技术栈

- **服务器**: Python 3.7+
- **扩展**: Chrome Manifest v3
- **协议**: SOCKS5 (RFC 1928/1929)
- **系统集成**: Systemd, Supervisor
- **日志**: Python logging 模块

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License - 可自由使用和修改

## 📞 支持

- 📖 [详细文档](server/README.md)
- 🐛 [提交 Issue](#)
- 💬 [讨论](discussions)

---

## 快速命令参考

```bash
# 启动服务器
sudo systemctl start socks5

# 停止服务器
sudo systemctl stop socks5

# 重启服务器
sudo systemctl restart socks5

# 查看状态
sudo systemctl status socks5

# 查看日志
sudo journalctl -u socks5 -f

# 测试连接
python3 test_socks5_client.py localhost 9999 google.com 443

# 卸载
sudo systemctl disable socks5 && sudo rm /etc/systemd/system/socks5.service
```

---

**版本**: 2.0 (完整重组版)  
**最后更新**: 2026年1月5日  
**维护者**: SimpleVPN Team
