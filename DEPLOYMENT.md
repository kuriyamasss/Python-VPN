# SimpleVPN 部署指南

完整的 Ubuntu/Debian 服务器部署和管理指南。

## 📋 目录

1. [预置要求](#预置要求)
2. [自动安装](#自动安装)
3. [手动安装](#手动安装)
4. [配置](#配置)
5. [系统管理](#系统管理)
6. [监控和日志](#监控和日志)
7. [备份和恢复](#备份和恢复)
8. [故障排除](#故障排除)

---

## 预置要求

### 系统要求

- **操作系统**: Ubuntu 18.04+ 或 Debian 10+
- **Python**: 3.7 或更新
- **内存**: 最少 512MB
- **磁盘**: 最少 1GB 可用空间
- **网络**: 需要外网连接（用于安装）

### 网络要求

- 开放 SOCKS5 端口（默认 9999）
- 可选：使用防火墙限制访问

### 用户权限

- 需要 sudo 权限进行安装
- 服务以 `socks5` 用户运行（自动创建）

---

## 自动安装

### 推荐方式

```bash
# 1. 下载项目
git clone <repo-url> ~/simplevpn
cd ~/simplevpn

# 2. 运行安装脚本（需要 sudo）
sudo server/scripts/install.sh

# 3. 验证安装
sudo systemctl status socks5
```

### 自动安装脚本做什么

✅ 检查/安装 Python 3  
✅ 创建 `socks5` 系统用户  
✅ 复制文件到 `/opt/simplevpn/server`  
✅ 安装 systemd 服务  
✅ 创建日志目录  
✅ 设置文件权限  

### 安装输出示例

```
========================================
SOCKS5 Server Installation
========================================

✓ Python 3 already installed
✓ socks5 user already exists
✓ Files copied to /opt/simplevpn/server
✓ Systemd service installed
✓ Logs directory created

========================================
Installation Complete!
========================================

Next steps:
1. Configure the server
   sudo nano /opt/simplevpn/server/config.py

2. Start the service
   sudo systemctl start socks5

3. Enable auto-start
   sudo systemctl enable socks5
```

---

## 手动安装

### 步骤 1: 安装依赖

```bash
# 更新软件包列表
sudo apt-get update

# 安装 Python 3 和 pip
sudo apt-get install -y python3 python3-pip
```

### 步骤 2: 创建用户

```bash
# 创建服务用户（无登录权限）
sudo useradd -r -s /bin/false -d /var/lib/socks5 socks5
```

### 步骤 3: 创建目录

```bash
# 创建安装目录
sudo mkdir -p /opt/simplevpn/server
sudo mkdir -p /opt/simplevpn/server/logs

# 设置权限
sudo chown -R socks5:socks5 /opt/simplevpn
sudo chmod 755 /opt/simplevpn/server
```

### 步骤 4: 复制文件

```bash
# 假设项目已下载到 ~/simplevpn
sudo cp ~/simplevpn/server/* /opt/simplevpn/server/
sudo cp ~/simplevpn/server/scripts/* /opt/simplevpn/server/scripts/

# 设置脚本可执行权限
sudo chmod +x /opt/simplevpn/server/scripts/*.sh
```

### 步骤 5: 安装 systemd 服务

```bash
# 复制 systemd 单元文件
sudo cp /opt/simplevpn/server/scripts/socks5.service /etc/systemd/system/

# 重新加载 systemd
sudo systemctl daemon-reload

# 验证服务
sudo systemctl list-unit-files | grep socks5
```

### 步骤 6: 启动服务

```bash
# 启动服务
sudo systemctl start socks5

# 启用开机自启
sudo systemctl enable socks5

# 验证运行
sudo systemctl status socks5
```

---

## 配置

### 配置文件位置

```
/opt/simplevpn/server/config.py
```

### 编辑配置

```bash
# 编辑配置文件
sudo nano /opt/simplevpn/server/config.py

# 修改完成后重启服务
sudo systemctl restart socks5
```

### 配置选项

```python
# 服务器地址和端口
HOST = '0.0.0.0'              # 监听所有网卡
PORT = 9999                   # SOCKS5 端口

# 认证凭证
USERNAME = "admin"            # 用户名
PASSWORD = "123456"           # 密码

# 连接限制
MAX_CONNECTIONS = 100         # 最大并发连接
SOCKET_TIMEOUT = 30           # 连接超时（秒）

# 日志配置
LOG_FILE = 'logs/socks5_server.log'    # 日志文件
LOG_LEVEL = 'INFO'                    # DEBUG/INFO/WARNING/ERROR
MAX_LOG_SIZE = 10 * 1024 * 1024       # 10MB
LOG_BACKUP_COUNT = 5                  # 保留 5 个备份
```

### 应用配置

任何配置修改后需要重启服务：

```bash
sudo systemctl restart socks5
```

---

## 系统管理

### 基本命令

```bash
# 启动服务
sudo systemctl start socks5

# 停止服务
sudo systemctl stop socks5

# 重启服务
sudo systemctl restart socks5

# 重新加载配置（不中断连接）
sudo systemctl reload socks5

# 查看服务状态
sudo systemctl status socks5

# 启用开机自启
sudo systemctl enable socks5

# 禁用开机自启
sudo systemctl disable socks5
```

### 检查服务

```bash
# 检查服务是否运行
sudo systemctl is-active socks5

# 检查服务是否启用
sudo systemctl is-enabled socks5

# 查看服务属性
sudo systemctl show socks5
```

### 查看监听端口

```bash
# 查看 9999 端口是否监听
sudo netstat -tlnp | grep 9999

# 或使用 ss 命令
sudo ss -tlnp | grep 9999
```

---

## 监控和日志

### 查看实时日志

```bash
# 实时查看日志（最常用）
sudo journalctl -u socks5 -f

# 显示最后 100 行
sudo journalctl -u socks5 -n 100

# 显示特定时间范围
sudo journalctl -u socks5 --since "2 hours ago"

# 显示今天的日志
sudo journalctl -u socks5 --since today
```

### 应用日志文件

```bash
# 查看日志文件
sudo tail -f /opt/simplevpn/server/logs/socks5_server.log

# 或
tail -f /opt/simplevpn/server/logs/socks5_server.log
```

### 日志分析

```bash
# 统计连接数
sudo journalctl -u socks5 | grep "Client connected" | wc -l

# 查找认证失败
sudo journalctl -u socks5 | grep "Auth failed"

# 查找连接错误
sudo journalctl -u socks5 | grep "ERROR"
```

### 设置日志级别

在 `config.py` 中修改：

```python
LOG_LEVEL = 'DEBUG'  # 更详细的日志
# 或
LOG_LEVEL = 'ERROR'  # 仅错误
```

---

## 备份和恢复

### 备份配置

```bash
# 备份配置目录
sudo cp -r /opt/simplevpn/server/config.py ~/simplevpn-config-backup.py

# 或完整备份
sudo tar -czf ~/simplevpn-backup-$(date +%Y%m%d).tar.gz \
  /opt/simplevpn/server/config.py \
  /opt/simplevpn/server/logs/
```

### 恢复配置

```bash
# 恢复单个配置文件
sudo cp ~/simplevpn-config-backup.py /opt/simplevpn/server/config.py
sudo chown socks5:socks5 /opt/simplevpn/server/config.py

# 重启服务
sudo systemctl restart socks5
```

### 定期备份脚本

创建 `/usr/local/bin/backup-simplevpn.sh`：

```bash
#!/bin/bash

BACKUP_DIR="/home/backups/simplevpn"
mkdir -p "$BACKUP_DIR"

# 备份配置和日志
sudo tar -czf "$BACKUP_DIR/backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
  /opt/simplevpn/server/config.py \
  /opt/simplevpn/server/logs/

# 保留最近 30 天的备份
find "$BACKUP_DIR" -name "backup-*.tar.gz" -mtime +30 -delete

echo "Backup completed"
```

### 添加 Crontab 计划

```bash
# 每天凌晨 2 点执行备份
sudo crontab -e

# 添加以下行：
0 2 * * * /usr/local/bin/backup-simplevpn.sh
```

---

## 故障排除

### 问题 1: 服务无法启动

```bash
# 1. 检查状态
sudo systemctl status socks5

# 2. 查看错误日志
sudo journalctl -u socks5 -n 50

# 3. 检查文件权限
sudo ls -l /opt/simplevpn/server/

# 4. 手动运行测试
sudo -u socks5 python3 /opt/simplevpn/server/socks5_server.py
```

### 问题 2: 端口已被占用

```bash
# 查找占用端口的进程
sudo netstat -tlnp | grep 9999
# 或
sudo lsof -i :9999

# 杀死占用进程
sudo kill -9 <PID>

# 或修改配置文件中的端口
```

### 问题 3: 权限问题

```bash
# 检查文件所有者
sudo ls -l /opt/simplevpn/server/

# 修复权限
sudo chown -R socks5:socks5 /opt/simplevpn/server/
sudo chmod 755 /opt/simplevpn/server/scripts/*.sh
```

### 问题 4: 日志目录错误

```bash
# 创建日志目录
sudo mkdir -p /opt/simplevpn/server/logs

# 设置权限
sudo chown socks5:socks5 /opt/simplevpn/server/logs
sudo chmod 755 /opt/simplevpn/server/logs
```

### 问题 5: Python 模块缺失

```bash
# 检查 Python 版本
python3 --version

# 确保 Python 3.7+
# 标准库中没有额外依赖

# 如需升级
sudo apt-get install python3.10
```

### 问题 6: 内存不足

```bash
# 检查内存使用
sudo systemctl show socks5 -p MemoryCurrent

# 减少最大连接数
sudo nano /opt/simplevpn/server/config.py
# 修改 MAX_CONNECTIONS = 50

sudo systemctl restart socks5
```

---

## 性能优化

### 增加最大并发连接

```bash
# 编辑配置
sudo nano /opt/simplevpn/server/config.py

# 修改
MAX_CONNECTIONS = 200

# 重启
sudo systemctl restart socks5
```

### 调整缓冲区大小

```python
# config.py 中
BUFFER_SIZE = 8192  # 增加缓冲区（需要内存支持）
```

### 监控性能

```bash
# 实时监控
top

# 查找 socks5 进程
ps aux | grep socks5_server

# 查看端口统计
netstat -an | grep 9999
```

---

## 升级和维护

### 升级到新版本

```bash
# 备份当前配置
sudo cp /opt/simplevpn/server/config.py \
  /opt/simplevpn/server/config.py.backup

# 下载新版本
cd ~/simplevpn
git pull

# 停止服务
sudo systemctl stop socks5

# 复制新文件
sudo cp server/* /opt/simplevpn/server/

# 检查配置是否兼容
# 对比 config.py.backup 和新的 config.py

# 启动服务
sudo systemctl start socks5
```

### 定期维护

```bash
# 月度维护计划
# 1. 检查日志大小
du -sh /opt/simplevpn/server/logs/

# 2. 清理旧日志（若需要）
sudo find /opt/simplevpn/server/logs/ -name "*.log" -mtime +30 -delete

# 3. 检查系统更新
sudo apt-get update
sudo apt-get upgrade

# 4. 验证服务状态
sudo systemctl status socks5
```

---

## 卸载

### 完全卸载

```bash
# 1. 停止服务
sudo systemctl stop socks5

# 2. 禁用开机自启
sudo systemctl disable socks5

# 3. 删除 systemd 服务文件
sudo rm /etc/systemd/system/socks5.service

# 4. 重新加载 systemd
sudo systemctl daemon-reload

# 5. 删除安装目录
sudo rm -rf /opt/simplevpn

# 6. 删除用户（可选）
sudo userdel socks5
```

---

## 快速命令参考

```bash
# 启动/停止/重启
sudo systemctl start socks5
sudo systemctl stop socks5
sudo systemctl restart socks5

# 查看状态
sudo systemctl status socks5
sudo netstat -tlnp | grep 9999

# 查看日志
sudo journalctl -u socks5 -f
tail -f /opt/simplevpn/server/logs/socks5_server.log

# 配置
sudo nano /opt/simplevpn/server/config.py

# 脚本管理
sudo /opt/simplevpn/server/scripts/start.sh --daemon
sudo /opt/simplevpn/server/scripts/stop.sh
sudo /opt/simplevpn/server/scripts/status.sh
```

---

**需要帮助？** 查看 [README.md](README.md) 或 [QUICKSTART.md](QUICKSTART.md)
