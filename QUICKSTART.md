# SimpleVPN 快速开始指南

## ⚡ 5分钟快速开始

### 方案 1: Ubuntu/Debian（推荐）

#### 步骤 1: 自动安装服务器

```bash
# 克隆或下载项目
cd ~/simplevpn

# 运行安装脚本（需要 sudo）
sudo server/scripts/install.sh
```

#### 步骤 2: 启动服务

```bash
# 启动服务
sudo systemctl start socks5

# 设置开机自启
sudo systemctl enable socks5

# 验证运行
sudo systemctl status socks5
```

#### 步骤 3: 安装 Chrome 扩展

1. 打开 Chrome，访问 `chrome://extensions/`
2. 启用右上角 **"开发者模式"**
3. 点击 **"加载已解压的扩展程序"**
4. 选择 `client` 文件夹

#### 步骤 4: 连接

1. 点击 Chrome 扩展图标
2. 填写服务器地址和端口
3. 点击 **"CONNECT"**

### 方案 2: 本地测试（Windows/macOS/Linux）

#### 启动服务器

**Windows:**
```powershell
.\start_server.ps1
```

**macOS/Linux:**
```bash
cd server
python3 socks5_server.py
```

#### 安装扩展

同方案 1 步骤 3-4

### 方案 3: 手动启动（Linux）

```bash
cd server
python3 socks5_server.py
```

---

## 🧪 测试连接

```bash
python3 test_socks5_client.py localhost 9999 google.com 443 -u admin -p 123456
```

**成功标志：** 看到 `[✓] SUCCESS`

---

## 🔧 常用命令

### 服务器管理（systemd）

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

# 卸载
sudo systemctl disable socks5
sudo rm /etc/systemd/system/socks5.service
```

### 脚本直接控制（Linux/macOS）

```bash
cd server/scripts

./start.sh --daemon    # 后台启动
./stop.sh              # 停止
./restart.sh           # 重启
./status.sh            # 查看状态
```

---

## ⚙️ 配置修改

编辑 `server/config.py` 修改：

```python
HOST = '0.0.0.0'           # 监听地址
PORT = 9999                # 监听端口
USERNAME = "admin"         # 用户名
PASSWORD = "123456"        # 密码
MAX_CONNECTIONS = 100      # 最大连接数
SOCKET_TIMEOUT = 30        # 超时时间
```

修改后重启服务器：
```bash
sudo systemctl restart socks5
```

---

## 🔒 安全设置

### 修改默认密码

```bash
sudo nano /opt/simplevpn/server/config.py
# 修改 USERNAME 和 PASSWORD
sudo systemctl restart socks5
```

### 限制访问

```bash
# 仅允许特定网段访问
sudo ufw allow from 192.168.1.0/24 to any port 9999
```

---

## 📋 故障排除

**问题**: 连接失败

```bash
# 1. 检查服务状态
sudo systemctl status socks5

# 2. 检查端口
sudo netstat -tlnp | grep 9999

# 3. 查看日志
sudo journalctl -u socks5 -n 50

# 4. 测试连接
python3 test_socks5_client.py localhost 9999 google.com 443
```

**问题**: 权限不足

```bash
# 需要 sudo 运行安装脚本
sudo server/scripts/install.sh
```

**问题**: Python 未安装

```bash
# 安装 Python 3
sudo apt-get install python3
```

---

## 📚 更多信息

- [完整文档](README.md)
- [服务器文档](server/README.md)
- [扩展文档](client/README.md)
- [改进详单](IMPROVEMENTS.md)

---

## 💡 提示

- 首次运行时会创建日志目录
- 配置自动保存到 Chrome 存储
- 支持多个 Chrome 配置文件
- 可以同时连接多个代理

---

**需要帮助？** 查看 [README.md](README.md) 的完整故障排除部分。
