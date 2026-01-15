import socket
import threading
import select
import struct
import logging
import time
import sys
import os
from datetime import datetime

# ================= 配置导入 =================
try:
    # 尝试从 config.py 导入配置
    sys.path.insert(0, os.path.dirname(__file__))
    from config import (
        HOST, PORT, USERNAME, PASSWORD, 
        SOCKET_TIMEOUT, MAX_CONNECTIONS,
        LOG_FILE, LOG_LEVEL, BUFFER_SIZE, VERBOSE
    )
except ImportError:
    # 如果 config.py 不存在，使用默认配置
    HOST = '0.0.0.0'
    PORT = 9999
    USERNAME = "admin"
    PASSWORD = "123456"
    SOCKET_TIMEOUT = 30
    MAX_CONNECTIONS = 100
    LOG_FILE = 'logs/socks5_server.log'
    LOG_LEVEL = 'INFO'
    BUFFER_SIZE = 4096
    VERBOSE = True

# ================= 日志配置 =================
# 确保日志目录存在
log_dir = os.path.dirname(LOG_FILE)
if log_dir and not os.path.exists(log_dir):
    os.makedirs(log_dir, exist_ok=True)

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class Socks5Server:
    def __init__(self, host, port, retry_count=5, retry_delay=3):
        self.host = host
        self.port = port
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
        # 设置多个 socket 选项以支持快速重启
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        
        # 在支持的系统上，也设置 SO_REUSEPORT
        try:
            self.server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
        except (AttributeError, OSError):
            pass  # SO_REUSEPORT 不可用
        
        # 设置 TCP 保活选项
        self.server.setsockopt(socket.SOL_SOCKET, socket.SO_KEEPALIVE, 1)
        
        # 尝试绑定，支持重试机制和指数退避
        for attempt in range(1, retry_count + 1):
            try:
                self.server.bind((self.host, self.port))
                logger.info(f"Successfully bound to {self.host}:{self.port}")
                break
            except OSError as e:
                if attempt < retry_count:
                    wait_time = retry_delay * (2 ** (attempt - 1))  # 指数退避
                    logger.warning(f"Bind failed (attempt {attempt}/{retry_count}): {e}")
                    logger.info(f"Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
                else:
                    logger.error(f"Failed to bind after {retry_count} attempts")
                    logger.error(f"Port {self.port} is still in use. Please try one of:")
                    logger.error(f"  1. sudo fuser -k {self.port}/tcp")
                    logger.error(f"  2. sudo pkill -9 -f socks5_server.py")
                    logger.error(f"  3. Wait a few minutes for TIME_WAIT sockets to clear")
                    raise
        
        self.server.listen(100)
        self.active_connections = 0
        self.connection_lock = threading.Lock()
        logger.info(f"SOCKS5 Server listening on {self.host}:{self.port}")
        logger.info(f"Max connections: {MAX_CONNECTIONS}, Socket timeout: {SOCKET_TIMEOUT}s")

    def run(self):
        try:
            while True:
                try:
                    client, addr = self.server.accept()
                    
                    # 检查并发连接数
                    with self.connection_lock:
                        if self.active_connections >= MAX_CONNECTIONS:
                            logger.warning(f"Max connections reached. Rejecting {addr[0]}:{addr[1]}")
                            client.close()
                            continue
                        self.active_connections += 1
                    
                    # 为每个连接启动一个线程
                    t = threading.Thread(target=self.handle_client, args=(client, addr))
                    t.daemon = True
                    t.start()
                except KeyboardInterrupt:
                    break
                except Exception as e:
                    logger.error(f"Error accepting connection: {e}", exc_info=True)
        finally:
            logger.info("Shutting down server...")
            self.server.close()

    def handle_client(self, client, addr):
        client_ip, client_port = addr
        try:
            client.settimeout(SOCKET_TIMEOUT)
            logger.info(f"Client connected: {client_ip}:{client_port}")
            
            # 1. 握手阶段
            # 客户端发送: 版本号(1 byte) + 方法数量(1 byte) + 方法列表(n bytes)
            header = client.recv(2)
            if not header:
                logger.warning(f"Client {client_ip}:{client_port} sent empty header")
                return
            
            version, nmethods = struct.unpack("!BB", header)
            if version != 5:
                logger.warning(f"Invalid SOCKS version {version} from {client_ip}:{client_port}")
                return
            
            # 读取方法列表
            methods = client.recv(nmethods)
            
            # 认证逻辑
            if USERNAME and PASSWORD:
                # 0x02 代表用户名/密码认证
                if 2 not in methods: 
                    # 客户端不支持认证，拒绝
                    logger.warning(f"Client {client_ip}:{client_port} does not support auth method")
                    client.sendall(struct.pack("!BB", 5, 0xFF))
                    return
                # 告诉客户端我们要用用户名密码认证
                client.sendall(struct.pack("!BB", 5, 2))
                
                # 验证用户名密码
                # 格式: 版本(1) + 用户名长度(1) + 用户名 + 密码长度(1) + 密码
                auth_version = ord(client.recv(1))
                usr_len = ord(client.recv(1))
                usr = client.recv(usr_len).decode('utf-8', errors='ignore')
                pwd_len = ord(client.recv(1))
                pwd = client.recv(pwd_len).decode('utf-8', errors='ignore')
                
                if usr == USERNAME and pwd == PASSWORD:
                    # 认证成功: 版本(1) + 状态(0=成功)
                    logger.info(f"Auth successful for {client_ip}:{client_port}")
                    client.sendall(struct.pack("!BB", 1, 0))
                else:
                    # 认证失败
                    logger.warning(f"Auth failed for {client_ip}:{client_port} (user: {usr})")
                    client.sendall(struct.pack("!BB", 1, 1))
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
                address = client.recv(domain_length).decode('utf-8', errors='ignore')
            elif address_type == 4:  # IPv6
                address = socket.inet_ntop(socket.AF_INET6, client.recv(16))
            else:
                logger.warning(f"Unsupported address type {address_type} from {client_ip}:{client_port}")
                client.sendall(struct.pack("!BBBBIH", 5, 8, 0, 1, 0, 0))  # Address type not supported
                return
            
            port = struct.unpack('!H', client.recv(2))[0]

            # 3. 连接目标服务器
            try:
                if cmd == 1:  # CONNECT
                    logger.info(f"CONNECT request from {client_ip}:{client_port} to {address}:{port}")
                    remote = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                    remote.settimeout(SOCKET_TIMEOUT)
                    remote.connect((address, port))
                    bind_address = remote.getsockname()
                    bind_port = bind_address[1]
                    
                    # 响应 IPv4 地址
                    addr_ip = struct.unpack("!I", socket.inet_aton(bind_address[0]))[0]
                    
                    # 回复客户端连接成功: Ver(5) + Rep(0) + Rsv(0) + Atyp(1) + BndAddr(4) + BndPort(2)
                    reply = struct.pack("!BBBBIH", 5, 0, 0, 1, addr_ip, bind_port)
                    client.sendall(reply)
                    
                    logger.info(f"Connected to {address}:{port} for {client_ip}:{client_port}")
                    
                    # 4. 数据转发阶段
                    self.exchange_loop(client, remote, client_ip, client_port, address, port)
                else:
                    # 暂不支持 BIND 或 UDP ASSOCIATE
                    logger.warning(f"Unsupported command {cmd} from {client_ip}:{client_port}")
                    client.sendall(struct.pack("!BBBBIH", 5, 7, 0, 1, 0, 0))  # Command not supported
                    
            except socket.timeout:
                logger.warning(f"Connection timeout to {address}:{port} for {client_ip}:{client_port}")
                client.sendall(struct.pack("!BBBBIH", 5, 1, 0, 1, 0, 0))  # General failure
            except ConnectionRefusedError:
                logger.warning(f"Connection refused to {address}:{port} from {client_ip}:{client_port}")
                client.sendall(struct.pack("!BBBBIH", 5, 5, 0, 1, 0, 0))  # Connection refused
            except Exception as e:
                logger.error(f"Error connecting to {address}:{port}: {e}", exc_info=True)
                try:
                    client.sendall(struct.pack("!BBBBIH", 5, 1, 0, 1, 0, 0))  # General failure
                except:
                    pass

        except socket.timeout:
            logger.warning(f"Socket timeout for {client_ip}:{client_port}")
        except Exception as e:
            logger.error(f"Handler error for {client_ip}:{client_port}: {e}", exc_info=True)
        finally:
            try:
                client.close()
            except:
                pass
            with self.connection_lock:
                self.active_connections -= 1
            logger.info(f"Client disconnected: {client_ip}:{client_port} (active: {self.active_connections})")

    def exchange_loop(self, client, remote, client_ip, client_port, target_addr, target_port):
        """在客户端和远程服务器之间转发数据"""
        bytes_sent = 0
        bytes_received = 0
        try:
            while True:
                # 使用 select 监听两个 socket 谁有数据
                r, w, e = select.select([client, remote], [], [], SOCKET_TIMEOUT)
                
                if not r:  # 超时无数据
                    logger.warning(f"Data transfer timeout for {client_ip}:{client_port} -> {target_addr}:{target_port}")
                    break
                
                if client in r:
                    data = client.recv(4096)
                    if not data:
                        break
                    try:
                        remote.sendall(data)
                        bytes_sent += len(data)
                    except BrokenPipeError:
                        logger.info(f"Remote closed connection for {client_ip}:{client_port}")
                        break
                
                if remote in r:
                    data = remote.recv(4096)
                    if not data:
                        break
                    try:
                        client.sendall(data)
                        bytes_received += len(data)
                    except BrokenPipeError:
                        logger.info(f"Client closed connection for {client_ip}:{client_port}")
                        break
        except Exception as e:
            logger.error(f"Data exchange error for {client_ip}:{client_port}: {e}", exc_info=False)
        finally:
            try:
                remote.close()
            except:
                pass
            logger.info(f"Connection closed: {client_ip}:{client_port} -> {target_addr}:{target_port} "
                       f"(sent: {bytes_sent} bytes, received: {bytes_received} bytes)")

if __name__ == "__main__":
    try:
        server = Socks5Server(HOST, PORT)
        logger.info("=" * 60)
        logger.info("SOCKS5 Server started successfully")
        logger.info(f"Host: {HOST}, Port: {PORT}")
        logger.info(f"Authentication: {'Enabled (' + USERNAME + ')' if USERNAME else 'Disabled'}")
        logger.info("=" * 60)
        server.run()
    except KeyboardInterrupt:
        logger.info("Server interrupted by user")
    except Exception as e:
        logger.critical(f"Fatal error: {e}", exc_info=True)
