# SimpleVPN 项目重组完成

## 📦 新的项目结构

项目已成功重组，分离了客户端（Chrome 扩展）和服务器（Python SOCKS5）：

### 目录树

```
Python-VPN/
│
├── 📁 client/                          # Chrome 浏览器扩展
│   ├── background.js                  # 后台服务 Worker
│   ├── manifest.json                  # 扩展清单 (Manifest v3)
│   ├── popup.html                     # 用户界面
│   ├── popup.js                       # 交互逻辑
│   ├── icon.png                       # 扩展图标 (多尺寸)
│   └── README.md                      # 扩展文档
│
├── 📁 server/                          # SOCKS5 服务器 (适合 Ubuntu/Debian)
│   ├── socks5_server.py               # 主服务器程序 (11.4 KB)
│   ├── config.py                      # 配置文件
│   ├── requirements.txt               # 依赖声明 (无外部依赖)
│   ├── README.md                      # 服务器文档
│   │
│   ├── 📁 logs/                       # 日志目录
│   │
│   └── 📁 scripts/                    # 管理脚本 (Linux/macOS)
│       ├── start.sh                   # 启动服务器
│       ├── stop.sh                    # 停止服务器
│       ├── restart.sh                 # 重启服务器
│       ├── status.sh                  # 检查状态
│       ├── install.sh                 # Ubuntu 自动安装脚本
│       ├── socks5.service             # Systemd 服务文件
│       └── socks5.conf                # Supervisor 配置
│
├── 📄 test_socks5_client.py            # SOCKS5 测试工具
├── 📄 create_icons.py                 # 图标生成工具
├── 📄 start_server.ps1                # Windows 启动脚本
│
├── 📄 README.md                       # 主文档
├── 📄 QUICKSTART.md                   # 5分钟快速开始
├── 📄 DEPLOYMENT.md                   # Ubuntu/Debian 部署指南
├── 📄 IMPROVEMENTS.md                 # 改进详单
└── 📄 PROJECT_REORGANIZATION.md       # 本文件

┌─ 已保留（向后兼容）───────────────┐
└─ SimpleVPN/                        ←  原始文件夹 (保留备份)
  ├── background.js
  ├── manifest.json
  ├── popup.html
  ├── popup.js
  ├── server.py
  └── icon.png
```

## ✨ 改进内容

### 分离优势

| 方面 | 改进 |
|------|------|
| **组织结构** | 🔷 清晰分离客户端和服务器 |
| **可维护性** | 🔷 模块化，易于维护和更新 |
| **部署** | 🔷 适配 Ubuntu/Debian 服务器部署 |
| **管理** | 🔷 完整的启动/停止/重启脚本 |
| **系统集成** | 🔷 Systemd 和 Supervisor 支持 |
| **自动化** | 🔷 一键安装脚本 |
| **文档** | 🔷 详细的部署指南 |
| **生产就绪** | 🔷 适合生产环境部署 |

### 新增文件

#### 1. 服务器管理脚本 (server/scripts/)

```bash
start.sh          # 启动服务器（支持 --daemon 后台运行）
stop.sh           # 优雅停止（支持 SIGTERM 和 SIGKILL）
restart.sh        # 停止后启动
status.sh         # 检查运行状态
install.sh        # Ubuntu/Debian 自动安装脚本
```

**特点**：
- ✅ 支持前台和后台运行
- ✅ 自动 PID 管理
- ✅ 优雅关闭处理
- ✅ 详细的状态报告

#### 2. 系统集成文件

```
socks5.service    # Systemd 单元文件（推荐）
socks5.conf       # Supervisor 配置（备选）
```

**功能**：
- ✅ 开机自启
- ✅ 自动重启崩溃
- ✅ 日志转发
- ✅ 进程管理

#### 3. 配置文件 (server/config.py)

从代码中提取配置，支持：
- 服务器地址和端口
- 认证凭证
- 连接限制
- 日志配置
- 缓冲区大小

#### 4. 文档

```
server/README.md          # 服务器使用文档
client/README.md          # 扩展使用文档
DEPLOYMENT.md             # 详细部署指南（52 KB）
QUICKSTART.md             # 快速开始指南
IMPROVEMENTS.md           # 改进详单
```

## 🚀 使用指南

### Ubuntu/Debian 部署（推荐）

```bash
# 1. 克隆项目
git clone <repo-url> ~/simplevpn
cd ~/simplevpn

# 2. 运行自动安装
sudo server/scripts/install.sh

# 3. 启动服务
sudo systemctl start socks5

# 4. 启用开机自启
sudo systemctl enable socks5

# 5. 验证
sudo systemctl status socks5
```

### 本地开发测试

```bash
# 启动服务器
cd server
python3 socks5_server.py

# 或在另一个终端测试
python3 test_socks5_client.py localhost 9999 google.com 443
```

### 扩展安装

1. 打开 Chrome，访问 `chrome://extensions/`
2. 启用开发者模式
3. 加载 `client` 文件夹

## 📊 文件统计

| 分类 | 文件数 | 总大小 |
|------|--------|--------|
| **client/** | 6 | ~13 KB |
| **server/** | 10 | ~25 KB |
| **scripts/** | 7 | ~8 KB |
| **tools/** | 3 | ~12 KB |
| **docs/** | 4 | ~35 KB |
| **total** | 30+ | ~93 KB |

## 🔄 迁移清单

✅ **已完成**：

- [x] 创建 `client/` 和 `server/` 目录
- [x] 复制扩展文件到 `client/`
- [x] 复制服务器文件到 `server/`
- [x] 创建 `server/scripts/` 管理脚本
- [x] 创建 `server/config.py` 配置文件
- [x] 创建 systemd 和 supervisor 配置
- [x] 编写 Ubuntu 自动安装脚本
- [x] 创建 `server/README.md` 文档
- [x] 创建 `client/README.md` 文档
- [x] 更新主 `README.md`
- [x] 创建 `DEPLOYMENT.md` 部署指南
- [x] 更新 `QUICKSTART.md`
- [x] 保留原始 `SimpleVPN/` 文件夹（向后兼容）

## 💡 推荐操作

### 1. 配置文件管理

```bash
# 编辑配置
sudo nano /opt/simplevpn/server/config.py

# 修改以下内容：
# - USERNAME 和 PASSWORD （必需）
# - PORT （可选）
# - MAX_CONNECTIONS （可选）
```

### 2. 防火墙设置

```bash
# 允许特定 IP 访问
sudo ufw allow from 192.168.1.0/24 to any port 9999

# 或仅允许本地
sudo ufw allow from 127.0.0.1 to any port 9999
```

### 3. 日志监控

```bash
# 实时查看日志
sudo journalctl -u socks5 -f

# 或查看文件
tail -f /opt/simplevpn/server/logs/socks5_server.log
```

### 4. 性能调优

根据硬件调整 `config.py` 中的 `MAX_CONNECTIONS` 和 `SOCKET_TIMEOUT`。

## 🔄 恢复原始结构

如需使用原始结构，可从 `SimpleVPN/` 文件夹使用原始文件。

## 📞 支持

- 📖 [README](README.md) - 项目概述
- 🚀 [QUICKSTART](QUICKSTART.md) - 5分钟开始
- 📦 [DEPLOYMENT](DEPLOYMENT.md) - 部署指南
- 🔧 [server/README](server/README.md) - 服务器文档
- 🔌 [client/README](client/README.md) - 扩展文档

## 📝 变更日志

### v2.1 (重组版本)

**新增**：
- ✨ 完整的项目结构重组
- ✨ 分离客户端和服务器代码
- ✨ Ubuntu/Debian 部署优化
- ✨ 完整的管理脚本
- ✨ Systemd 集成
- ✨ 详细的部署指南

**改进**：
- 🔷 更清晰的文件组织
- 🔷 更容易的部署和维护
- 🔷 更好的文档结构

**兼容性**：
- ✅ 向后兼容（原始文件保留）
- ✅ 新旧结构可并存

---

**重组完成时间**: 2026 年 1 月 5 日  
**项目版本**: 2.1  
**结构**: 分离的客户端/服务器架构
