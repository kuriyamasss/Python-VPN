# 设置项目名称
$projectName = "SimpleVPN"
$currentPath = Get-Location
$targetPath = Join-Path $currentPath $projectName

# 创建项目目录
if (-not (Test-Path $targetPath)) {
    New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
    Write-Host "[+] Created directory: $targetPath" -ForegroundColor Green
} else {
    Write-Host "[!] Directory exists: $targetPath (Files will be overwritten)" -ForegroundColor Yellow
}

# ---------------------------------------------------------
# 1. 生成 server.py (SOCKS5 代理服务器)
# ---------------------------------------------------------
$serverPyContent = @'
import socket
import threading
import select
import struct

# ================= 配置区域 =================
# 监听地址 (0.0.0.0 表示允许外网访问)
HOST = '0.0.0.0'
# 监听端口
PORT = 9999
# 认证配置 (留空则无需认证，但强烈建议设置)
USERNAME = "admin"
PASSWORD = "123456"
# ===========================================

class Socks5Server:
    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server.bind((self.host, self.port))
        self.server.listen(100)
        print(f"[*] SOCKS5 Server listening on {self.host}:{self.port}")

    def run(self):
        while True:
            try:
                client, addr = self.server.accept()
                # 为每个连接启动一个线程
                t = threading.Thread(target=self.handle_client, args=(client, addr))
                t.daemon = True
                t.start()
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"[!] Error accepting connection: {e}")

    def handle_client(self, client, addr):
        try:
            # 1. 握手阶段
            # 客户端发送: 版本号(1 byte) + 方法数量(1 byte) + 方法列表(n bytes)
            header = client.recv(2)
            if not header: return
            version, nmethods = struct.unpack("!BB", header)
            
            # 读取方法列表
            methods = client.recv(nmethods)
            
            # 认证逻辑
            if USERNAME and PASSWORD:
                # 0x02 代表用户名/密码认证
                if 2 not in methods: 
                    # 客户端不支持认证，拒绝
                    client.sendall(struct.pack("!BB", 5, 0xFF))
                    client.close()
                    return
                # 告诉客户端我们要用用户名密码认证
                client.sendall(struct.pack("!BB", 5, 2))
                
                # 验证用户名密码
                # 格式: 版本(1) + 用户名长度(1) + 用户名 + 密码长度(1) + 密码
                auth_version = ord(client.recv(1))
                usr_len = ord(client.recv(1))
                usr = client.recv(usr_len).decode()
                pwd_len = ord(client.recv(1))
                pwd = client.recv(pwd_len).decode()
                
                if usr == USERNAME and pwd == PASSWORD:
                    # 认证成功: 版本(1) + 状态(0=成功)
                    client.sendall(struct.pack("!BB", 1, 0))
                else:
                    # 认证失败
                    client.sendall(struct.pack("!BB", 1, 1))
                    client.close()
                    return
            else:
                # 无需认证: 0x00
                client.sendall(struct.pack("!BB", 5, 0))

            # 2. 请求阶段
            # 格式: Ver(1) + Cmd(1) + Rsv(1) + Atyp(1) + DstAddr(...) + DstPort(2)
            version, cmd, _, address_type = struct.unpack("!BBBB", client.recv(4))
            
            if address_type == 1:  # IPv4
                address = socket.inet_ntoa(client.recv(4))
            elif address_type == 3:  # Domain name
                domain_length = ord(client.recv(1))
                address = client.recv(domain_length).decode()
            elif address_type == 4:  # IPv6 (暂未完全实现，简单跳过)
                address = socket.inet_ntop(socket.AF_INET6, client.recv(16))
            
            port = struct.unpack('!H', client.recv(2))[0]

            # 3. 连接目标服务器
            try:
                if cmd == 1:  # CONNECT
                    remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    remote.connect((address, port))
                    bind_address = remote.getsockname()
                    bind_port = bind_address[1]
                    
                    # 响应 IPv4 地址
                    addr_ip = struct.unpack("!I", socket.inet_aton(bind_address[0]))[0]
                    
                    # 回复客户端连接成功: Ver(5) + Rep(0) + Rsv(0) + Atyp(1) + BndAddr(4) + BndPort(2)
                    reply = struct.pack("!BBBBIH", 5, 0, 0, 1, addr_ip, bind_port)
                    client.sendall(reply)
                    
                    # 4. 数据转发阶段
                    self.exchange_loop(client, remote)
                else:
                    # 暂不支持 BIND 或 UDP ASSOCIATE
                    client.close()
            except Exception as e:
                # 连接失败回复
                # print(f"Connect error: {e}")
                client.sendall(struct.pack("!BBBBIH", 5, 5, 0, 1, 0, 0))
                client.close()

        except Exception as e:
            # print(f"Handler error: {e}")
            pass
        finally:
            client.close()

    def exchange_loop(self, client, remote):
        while True:
            # 使用 select 监听两个 socket 谁有数据
            r, w, e = select.select([client, remote], [], [])
            if client in r:
                data = client.recv(4096)
                if remote.send(data) <= 0: break
            if remote in r:
                data = remote.recv(4096)
                if client.send(data) <= 0: break

if __name__ == "__main__":
    server = Socks5Server(HOST, PORT)
    server.run()
'@
$serverPyContent | Set-Content -Path (Join-Path $targetPath "server.py") -Encoding UTF8
Write-Host "[+] Generated server.py" -ForegroundColor Cyan

# ---------------------------------------------------------
# 2. 生成 manifest.json
# ---------------------------------------------------------
$manifestContent = @'
{
  "manifest_version": 3,
  "name": "My Simple Python VPN",
  "version": "1.0",
  "description": "Connects to my private Python SOCKS5 Server",
  "permissions": [
    "proxy",
    "storage",
    "webRequest",
    "webRequestAuthProvider"
  ],
  "host_permissions": [
    "<all_urls>"
  ],
  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icon.png", 
      "48": "icon.png",
      "128": "icon.png"
    }
  },
  "background": {
    "service_worker": "background.js"
  },
  "icons": {
    "16": "icon.png",
    "48": "icon.png",
    "128": "icon.png"
  }
}
'@
$manifestContent | Set-Content -Path (Join-Path $targetPath "manifest.json") -Encoding UTF8
Write-Host "[+] Generated manifest.json" -ForegroundColor Cyan

# ---------------------------------------------------------
# 3. 生成 background.js
# ---------------------------------------------------------
$backgroundJsContent = @'
// 初始化状态
let proxyConfig = {
  mode: "direct"
};

// 监听来自 popup 的消息
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.type === 'UPDATE_PROXY') {
    handleProxyUpdate(request.data);
    sendResponse({status: 'success'});
  } else if (request.type === 'GET_STATUS') {
    chrome.storage.local.get(['isConnected', 'host', 'port', 'username'], (result) => {
      sendResponse(result);
    });
    return true; // 异步响应
  }
});

function handleProxyUpdate(data) {
  const { isConnected, host, port, username, password } = data;

  if (isConnected) {
    // 设置 Chrome 代理配置
    const config = {
      mode: "fixed_servers",
      rules: {
        singleProxy: {
          scheme: "socks5",
          host: host,
          port: parseInt(port)
        },
        bypassList: ["localhost", "127.0.0.1", "::1"]
      }
    };

    chrome.proxy.settings.set({ value: config, scope: "regular" }, () => {
      console.log("Proxy enabled:", host, port);
    });

    // 存储凭证以便身份验证使用
    chrome.storage.local.set({ 
      isConnected: true, 
      host, 
      port, 
      username, 
      password 
    });

  } else {
    // 关闭代理
    chrome.proxy.settings.set({ value: { mode: "direct" }, scope: "regular" }, () => {
      console.log("Proxy disabled");
    });
    
    chrome.storage.local.set({ isConnected: false });
  }
}

// 处理身份验证请求 (SOCKS5 Auth)
chrome.webRequest.onAuthRequired.addListener(
  (details) => {
    return new Promise((resolve) => {
      chrome.storage.local.get(['username', 'password', 'isConnected'], (data) => {
        if (data.isConnected && details.isProxy) {
          resolve({
            authCredentials: {
              username: data.username,
              password: data.password
            }
          });
        } else {
          resolve({});
        }
      });
    });
  },
  { urls: ["<all_urls>"] },
  ["blocking"]
);
'@
$backgroundJsContent | Set-Content -Path (Join-Path $targetPath "background.js") -Encoding UTF8
Write-Host "[+] Generated background.js" -ForegroundColor Cyan

# ---------------------------------------------------------
# 4. 生成 popup.html
# ---------------------------------------------------------
$popupHtmlContent = @'
<!DOCTYPE html>
<html>
<head>
  <style>
    body { width: 250px; padding: 15px; font-family: sans-serif; background: #f4f4f9; }
    h2 { margin-top: 0; color: #333; text-align: center;}
    .input-group { margin-bottom: 10px; }
    label { display: block; font-size: 12px; color: #666; margin-bottom: 3px; }
    input { width: 100%; padding: 8px; box-sizing: border-box; border: 1px solid #ddd; border-radius: 4px; }
    button { width: 100%; padding: 10px; border: none; border-radius: 4px; cursor: pointer; font-weight: bold; transition: 0.3s; }
    .btn-connect { background-color: #4CAF50; color: white; }
    .btn-connect:hover { background-color: #45a049; }
    .btn-disconnect { background-color: #f44336; color: white; display: none; }
    .btn-disconnect:hover { background-color: #d32f2f; }
    .status { text-align: center; font-size: 12px; margin-top: 10px; color: #888; }
    .dot { height: 10px; width: 10px; background-color: #bbb; border-radius: 50%; display: inline-block; margin-right: 5px; }
    .dot.active { background-color: #4CAF50; }
  </style>
</head>
<body>
  <h2>Server Config</h2>
  
  <div id="config-form">
    <div class="input-group">
      <label>Server IP</label>
      <input type="text" id="host" placeholder="e.g. 1.2.3.4">
    </div>
    <div class="input-group">
      <label>Port</label>
      <input type="number" id="port" placeholder="9999" value="9999">
    </div>
    <div class="input-group">
      <label>Username</label>
      <input type="text" id="username" placeholder="Optional" value="admin">
    </div>
    <div class="input-group">
      <label>Password</label>
      <input type="password" id="password" placeholder="Optional" value="123456">
    </div>
  </div>

  <button id="connectBtn" class="btn-connect">CONNECT</button>
  <button id="disconnectBtn" class="btn-disconnect">DISCONNECT</button>

  <div class="status">
    <span id="statusDot" class="dot"></span>
    <span id="statusText">Disconnected</span>
  </div>

  <script src="popup.js"></script>
</body>
</html>
'@
$popupHtmlContent | Set-Content -Path (Join-Path $targetPath "popup.html") -Encoding UTF8
Write-Host "[+] Generated popup.html" -ForegroundColor Cyan

# ---------------------------------------------------------
# 5. 生成 popup.js
# ---------------------------------------------------------
$popupJsContent = @'
document.addEventListener('DOMContentLoaded', () => {
  const hostInput = document.getElementById('host');
  const portInput = document.getElementById('port');
  const userInput = document.getElementById('username');
  const passInput = document.getElementById('password');
  const connectBtn = document.getElementById('connectBtn');
  const disconnectBtn = document.getElementById('disconnectBtn');
  const configForm = document.getElementById('config-form');
  const statusText = document.getElementById('statusText');
  const statusDot = document.getElementById('statusDot');

  // 初始化：获取当前状态
  chrome.runtime.sendMessage({ type: 'GET_STATUS' }, (response) => {
    if (response && response.isConnected) {
      showConnectedState();
      // 填充已保存的数据
      hostInput.value = response.host || '';
      portInput.value = response.port || '';
      userInput.value = response.username || '';
    } else {
      // 尝试恢复上次的输入但不改变连接状态
      if (response) {
        hostInput.value = response.host || '';
        portInput.value = response.port || '';
        userInput.value = response.username || '';
      }
      showDisconnectedState();
    }
  });

  connectBtn.addEventListener('click', () => {
    const host = hostInput.value.trim();
    const port = portInput.value.trim();
    const username = userInput.value.trim();
    const password = passInput.value.trim();

    if (!host || !port) {
      alert("Please enter Host and Port");
      return;
    }

    // 发送消息给 background
    chrome.runtime.sendMessage({
      type: 'UPDATE_PROXY',
      data: { isConnected: true, host, port, username, password }
    }, () => {
      showConnectedState();
    });
  });

  disconnectBtn.addEventListener('click', () => {
    chrome.runtime.sendMessage({
      type: 'UPDATE_PROXY',
      data: { isConnected: false }
    }, () => {
      showDisconnectedState();
    });
  });

  function showConnectedState() {
    connectBtn.style.display = 'none';
    disconnectBtn.style.display = 'block';
    configForm.style.opacity = '0.5';
    configForm.style.pointerEvents = 'none'; // 禁用输入
    statusText.innerText = "Connected";
    statusDot.classList.add('active');
  }

  function showDisconnectedState() {
    connectBtn.style.display = 'block';
    disconnectBtn.style.display = 'none';
    configForm.style.opacity = '1';
    configForm.style.pointerEvents = 'auto';
    statusText.innerText = "Disconnected";
    statusDot.classList.remove('active');
  }
});
'@
$popupJsContent | Set-Content -Path (Join-Path $targetPath "popup.js") -Encoding UTF8
Write-Host "[+] Generated popup.js" -ForegroundColor Cyan

# ---------------------------------------------------------
# 6. 生成图标 (icon.png)
# ---------------------------------------------------------
# 这是一个简单的 1x1 像素透明 PNG 的 Base64，防止插件报错
$iconBase64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVRYhe3OQQ0AIBDAsIv8a0iDPyQc7UBCba/zXvNM01G/AAAAAAAAAAAAAAAAAAAAAPg0F2YAAc3pP+UAAAAASUVORK5CYII="
$iconBytes = [System.Convert]::FromBase64String($iconBase64)
[System.IO.File]::WriteAllBytes((Join-Path $targetPath "icon.png"), $iconBytes)
Write-Host "[+] Generated icon.png (Placeholder)" -ForegroundColor Cyan

# ---------------------------------------------------------
# 完成
# ---------------------------------------------------------
Write-Host "`nAll files generated successfully in folder: $targetPath" -ForegroundColor Green
Write-Host "1. Upload 'server.py' to your VPS."
Write-Host "2. Load 'SimpleVPN' folder in Chrome (Developer Mode -> Load unpacked)."
Read-Host "Press Enter to exit..."