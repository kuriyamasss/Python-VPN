#!/usr/bin/env python3
"""
Simple SOCKS5 client test tool
Tests SOCKS5 proxy connection and authentication
"""

import socket
import struct
import sys
import argparse


class Socks5Client:
    def __init__(self, proxy_host, proxy_port, target_host, target_port, username=None, password=None):
        self.proxy_host = proxy_host
        self.proxy_port = proxy_port
        self.target_host = target_host
        self.target_port = target_port
        self.username = username
        self.password = password
        self.sock = None

    def connect(self):
        """Connect to SOCKS5 proxy"""
        try:
            print(f"[*] Connecting to SOCKS5 proxy: {self.proxy_host}:{self.proxy_port}")
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.connect((self.proxy_host, self.proxy_port))
            print("[✓] Connected to proxy")
        except Exception as e:
            print(f"[✗] Failed to connect: {e}")
            return False
        return True

    def handshake(self):
        """Perform SOCKS5 handshake"""
        try:
            # Client greeting
            # VER (1) + NMETHODS (1) + METHODS (n)
            methods = [0]  # No auth
            if self.username and self.password:
                methods.append(2)  # Username/password auth
            
            greeting = struct.pack("!BB", 5, len(methods)) + bytes(methods)
            print(f"[*] Sending greeting with {len(methods)} authentication method(s)")
            self.sock.sendall(greeting)
            
            # Server response
            # VER (1) + METHOD (1)
            response = self.sock.recv(2)
            if len(response) < 2:
                print("[✗] Invalid server response")
                return False
            
            version, method = struct.unpack("!BB", response)
            print(f"[*] Server response: version={version}, method={method}")
            
            if method == 0xFF:
                print("[✗] No acceptable method")
                return False
            
            # Authentication if required
            if method == 2:
                return self.authenticate()
            elif method == 0:
                print("[✓] No authentication required")
                return True
            else:
                print(f"[!] Unsupported method: {method}")
                return False
                
        except Exception as e:
            print(f"[✗] Handshake error: {e}")
            return False

    def authenticate(self):
        """Authenticate using username/password"""
        try:
            if not self.username or not self.password:
                print("[✗] Authentication required but no credentials provided")
                return False
            
            print(f"[*] Authenticating with username: {self.username}")
            
            # Auth request
            # VER (1) + ULEN (1) + UNAME + PLEN (1) + PASSWD
            auth_request = struct.pack("!BB", 1, len(self.username))
            auth_request += self.username.encode('utf-8')
            auth_request += struct.pack("!B", len(self.password))
            auth_request += self.password.encode('utf-8')
            
            self.sock.sendall(auth_request)
            
            # Auth response
            # VER (1) + STATUS (1)
            response = self.sock.recv(2)
            if len(response) < 2:
                print("[✗] Invalid auth response")
                return False
            
            version, status = struct.unpack("!BB", response)
            if status == 0:
                print("[✓] Authentication successful")
                return True
            else:
                print("[✗] Authentication failed")
                return False
                
        except Exception as e:
            print(f"[✗] Authentication error: {e}")
            return False

    def request_connection(self):
        """Request CONNECT to target server"""
        try:
            print(f"[*] Requesting CONNECT to {self.target_host}:{self.target_port}")
            
            # CONNECT request
            # VER (1) + CMD (1) + RSV (1) + ATYP (1) + DST.ADDR + DST.PORT
            request = struct.pack("!BBB", 5, 1, 0)  # VER=5, CMD=CONNECT, RSV=0
            
            # Address type: 1 = IPv4
            try:
                # Try as IPv4
                import socket as sock_module
                ipv4_bytes = sock_module.inet_aton(self.target_host)
                request += struct.pack("!B", 1)  # ATYP = IPv4
                request += ipv4_bytes
            except:
                # Use as domain name (ATYP = 3)
                domain_bytes = self.target_host.encode('utf-8')
                request += struct.pack("!BB", 3, len(domain_bytes))
                request += domain_bytes
            
            request += struct.pack("!H", self.target_port)
            self.sock.sendall(request)
            
            # Server response
            # VER (1) + REP (1) + RSV (1) + ATYP (1) + BND.ADDR + BND.PORT
            response = self.sock.recv(4)
            if len(response) < 4:
                print("[✗] Invalid connection response")
                return False
            
            version, rep, rsv, atyp = struct.unpack("!BBBB", response)
            
            # Parse rest of response based on address type
            if atyp == 1:  # IPv4
                addr_data = self.sock.recv(4)
                port_data = self.sock.recv(2)
                addr = socket.inet_ntoa(addr_data)
                port = struct.unpack("!H", port_data)[0]
                print(f"[*] Bound address: {addr}:{port}")
            elif atyp == 3:  # Domain
                domain_len = ord(self.sock.recv(1))
                domain = self.sock.recv(domain_len).decode('utf-8')
                port_data = self.sock.recv(2)
                port = struct.unpack("!H", port_data)[0]
                print(f"[*] Bound address: {domain}:{port}")
            
            # Check response status
            error_messages = {
                0: "SUCCESS",
                1: "General failure",
                2: "Connection not allowed by ruleset",
                3: "Network unreachable",
                4: "Host unreachable",
                5: "Connection refused",
                6: "TTL expired",
                7: "Command not supported",
                8: "Address type not supported"
            }
            
            status_msg = error_messages.get(rep, f"Unknown error ({rep})")
            if rep == 0:
                print(f"[✓] {status_msg}")
                return True
            else:
                print(f"[✗] Connection failed: {status_msg}")
                return False
                
        except Exception as e:
            print(f"[✗] Connection request error: {e}")
            return False

    def close(self):
        """Close connection"""
        if self.sock:
            try:
                self.sock.close()
            except:
                pass

    def test(self):
        """Run full test"""
        try:
            if not self.connect():
                return False
            if not self.handshake():
                return False
            if not self.request_connection():
                return False
            print("[✓] Test completed successfully!")
            return True
        finally:
            self.close()


def main():
    parser = argparse.ArgumentParser(
        description='Simple SOCKS5 client test tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Test local SOCKS5 server (no auth)
  python test_socks5_client.py localhost 9999 google.com 443
  
  # Test with authentication
  python test_socks5_client.py localhost 9999 google.com 443 -u admin -p 123456
  
  # Test connecting through proxy to another server
  python test_socks5_client.py 192.168.1.100 9999 8.8.8.8 53 -u user -p pass
        """
    )
    
    parser.add_argument('proxy_host', help='SOCKS5 proxy host/IP')
    parser.add_argument('proxy_port', type=int, help='SOCKS5 proxy port')
    parser.add_argument('target_host', help='Target host to connect to')
    parser.add_argument('target_port', type=int, help='Target port')
    parser.add_argument('-u', '--username', help='Username for authentication')
    parser.add_argument('-p', '--password', help='Password for authentication')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("SOCKS5 Client Test Tool")
    print("=" * 60)
    print()
    
    client = Socks5Client(
        args.proxy_host,
        args.proxy_port,
        args.target_host,
        args.target_port,
        args.username,
        args.password
    )
    
    success = client.test()
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
