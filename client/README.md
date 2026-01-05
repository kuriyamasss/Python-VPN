# Chrome SOCKS5 Proxy Extension

Chrome 浏览器扩展，用于连接到 SOCKS5 代理服务器。

## 📋 特性

- ✅ 简洁的用户界面
- ✅ SOCKS5 代理配置管理
- ✅ 自动保存配置
- ✅ 错误提示和诊断
- ✅ 实时连接状态显示
- ✅ 支持用户名/密码认证

## 📁 文件结构

```
client/
├── manifest.json      # 扩展清单
├── background.js      # 后台服务 Worker
├── popup.html         # 用户界面
├── popup.js          # 界面交互逻辑
└── icon.png          # 扩展图标
```

## 🚀 安装

### 方式一：开发者模式安装（推荐用于开发）

1. 打开 Chrome，访问 `chrome://extensions/`
2. 启用右上角的 **"开发者模式"**
3. 点击 **"加载已解压的扩展程序"**
4. 选择此 `client` 文件夹
5. 扩展会立即加载到浏览器

### 方式二：打包为 CRX（用于分发）

1. 打开 `chrome://extensions/`
2. 找到已加载的扩展
3. 点击右下角的"打包扩展程序"
4. 选择此文件夹
5. Chrome 会生成 `.crx` 和 `.pem` 文件

## 🎮 使用方法

### 连接到代理

1. 在浏览器右上角找到 SimpleVPN 图标
2. 点击打开扩展弹窗
3. 填写代理服务器信息：
   - **Server IP**: SOCKS5 服务器地址
   - **Port**: SOCKS5 服务器端口（默认 9999）
   - **Username**: 认证用户名（可选）
   - **Password**: 认证密码（可选）
4. 点击 **"CONNECT"** 按钮
5. 连接状态指示器变绿表示成功

### 断开连接

1. 打开扩展弹窗
2. 点击 **"DISCONNECT"** 按钮
3. 或点击 **"Clear"** 清除所有保存的配置

## 🔧 配置

所有配置通过 UI 保存，自动存储在 Chrome 本地存储中。

### 配置项

| 项目 | 说明 | 示例 |
|------|------|------|
| Server IP | SOCKS5 服务器地址 | 127.0.0.1 或 1.2.3.4 |
| Port | SOCKS5 服务器端口 | 9999 |
| Username | 认证用户名（可选） | admin |
| Password | 认证密码（可选） | 123456 |

## 🔍 故障排除

### 问题：连接失败，显示"Connection Error"

**可能原因和解决方案：**

1. **服务器未运行**
   - 检查服务器是否启动
   - 在服务器主机上运行 `systemctl status socks5`

2. **IP/端口配置错误**
   - 验证填写的 IP 和端口是否正确
   - 使用 `netstat` 检查端口是否监听

3. **用户名/密码错误**
   - 检查凭证是否匹配服务器配置
   - 查看服务器日志找到认证失败信息

4. **防火墙阻止**
   - 检查防火墙规则
   - 确保端口未被阻止

5. **网络连接问题**
   - 检查网络连接
   - 验证能否 ping 通服务器

### 调试方法

**查看扩展日志：**

1. 打开 `chrome://extensions/`
2. 找到 SimpleVPN 扩展
3. 点击 **"背景页"** 或 **"Service Worker"**
4. 打开开发者工具 (F12)
5. 查看控制台日志

**查看服务器日志：**

```bash
# 如果使用 systemd
sudo journalctl -u socks5 -f

# 或查看日志文件
tail -f server/logs/socks5_server.log
```

## 📝 技术细节

### 工作原理

1. **UI 层** (`popup.html`, `popup.js`)
   - 提供用户界面
   - 收集用户配置
   - 显示连接状态和错误

2. **后台服务** (`background.js`)
   - 管理 Chrome 代理设置
   - 处理 SOCKS5 认证
   - 存储和恢复配置

3. **Chrome API 使用**
   - `chrome.proxy.settings` - 设置代理
   - `chrome.storage.local` - 本地存储
   - `chrome.webRequest.onAuthRequired` - 处理认证
   - `chrome.runtime.sendMessage` - 进程间通信

### 消息格式

扩展和后台之间的通信格式：

```javascript
// UPDATE_PROXY - 更新代理设置
{
  type: 'UPDATE_PROXY',
  data: {
    isConnected: true,
    host: '127.0.0.1',
    port: 9999,
    username: 'admin',
    password: '123456'
  }
}

// GET_STATUS - 获取当前状态
{
  type: 'GET_STATUS'
}

// CLEAR_ERROR - 清除错误信息
{
  type: 'CLEAR_ERROR'
}
```

## 🔐 安全考虑

1. **密码存储**
   - 密码存储在 Chrome 本地存储中
   - 只能被此扩展访问
   - 不会上传到云端

2. **代理连接**
   - 所有浏览流量通过代理
   - 基于 SOCKS5 协议的安全性
   - 建议使用强密码

3. **隐私**
   - 此扩展不收集任何用户数据
   - 不包含跟踪代码
   - 完全开源

## 📚 相关文档

- [Chrome 扩展开发文档](https://developer.chrome.com/docs/extensions/)
- [SOCKS5 协议 RFC 1928](https://tools.ietf.org/html/rfc1928)
- [服务器配置](../server/README.md)

## 🐛 报告问题

如发现 bug 或有功能建议，请：

1. 查看服务器和扩展日志
2. 测试通信是否正常 (`test_socks5_client.py`)
3. 提交 issue 或 PR

## 📄 许可证

开源项目，可自由使用和修改。
