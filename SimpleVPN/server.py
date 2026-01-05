import socket
import threading
import select
import struct

# ================= 配置区域 =================
# 监听地址 (0.0.0.0 表示允许外网访问)
HOST = '0.0.0.0'
# 监听端口
PORT = 9999
# 认证配置 (建议修改此处密码)
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