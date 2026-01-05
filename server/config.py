"""
SOCKS5 Server Configuration
"""

# ================= Server Configuration =================

# Server address (0.0.0.0 = listen on all interfaces)
HOST = '0.0.0.0'

# Server port
PORT = 9999

# Authentication credentials
# Set USERNAME and PASSWORD to None to disable authentication
USERNAME = "admin"
PASSWORD = "123456"

# ================= Network Configuration =================

# Socket timeout in seconds (prevents dead connections)
SOCKET_TIMEOUT = 30

# Maximum concurrent connections
MAX_CONNECTIONS = 100

# ================= Logging Configuration =================

# Log file path (relative to server directory)
LOG_FILE = 'logs/socks5_server.log'

# Log level: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_LEVEL = 'INFO'

# Maximum log file size in bytes (10 MB)
MAX_LOG_SIZE = 10 * 1024 * 1024

# Number of backup log files to keep
LOG_BACKUP_COUNT = 5

# ================= Advanced Configuration =================

# Buffer size for data transfer (in bytes)
BUFFER_SIZE = 4096

# Enable detailed connection logging
VERBOSE = True

# PID file location (for systemd/supervisor integration)
PID_FILE = 'socks5.pid'
