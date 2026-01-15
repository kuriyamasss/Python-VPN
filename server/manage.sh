#!/bin/bash

################################################################################
# SimpleVPN Server Management Script - 交互式菜单版
# 在 server 目录中运行此脚本
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目配置（基于 server 目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/simplevpn"
CONFIG_FILE="$INSTALL_DIR/config.py"
LOG_FILE="$INSTALL_DIR/logs/socks5_server.log"
SERVICE_NAME="socks5"
SERVICE_FILE="/etc/systemd/system/socks5.service"

################################################################################
# 工具函数
################################################################################

print_header() {
    clear
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此命令需要 root 权限"
        echo "请使用 'sudo ./manage.sh' 运行"
        exit 1
    fi
}

check_installation() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_error "SimpleVPN 未安装在 $INSTALL_DIR"
        return 1
    fi
    return 0
}

press_enter() {
    echo ""
    read -p "按 Enter 继续..."
}

################################################################################
# 安装功能
################################################################################

install() {
    check_root
    
    print_header "开始安装 SimpleVPN"
    
    # 1. 检查 Python
    print_info "检查 Python..."
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 未安装"
        echo "请运行: sudo apt-get update && sudo apt-get install -y python3"
        press_enter
        return
    fi
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    print_success "Python $PYTHON_VERSION 已安装"
    
    # 2. 创建用户
    print_info "检查 socks5 用户..."
    if ! id -u socks5 &>/dev/null 2>&1; then
        print_info "创建 socks5 用户..."
        useradd -r -s /bin/false -d $INSTALL_DIR -m socks5 2>/dev/null || true
        print_success "socks5 用户已创建"
    else
        print_success "socks5 用户已存在"
    fi
    
    # 3. 创建目录结构
    print_info "创建目录结构..."
    mkdir -p "$INSTALL_DIR"/{logs,scripts}
    print_success "目录已创建"
    
    # 4. 复制文件
    print_info "复制文件..."
    cp "$SCRIPT_DIR/socks5_server.py" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/config.py" "$INSTALL_DIR/"
    cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/" 2>/dev/null || true
    print_success "文件已复制"
    
    # 5. 设置权限
    print_info "设置权限..."
    chown -R socks5:socks5 "$INSTALL_DIR"
    chmod 750 "$INSTALL_DIR"
    chmod 750 "$INSTALL_DIR/logs"
    chmod 640 "$INSTALL_DIR/config.py"
    chmod 750 "$INSTALL_DIR/socks5_server.py"
    print_success "权限已设置"
    
    # 6. 创建 systemd 服务
    print_info "创建 systemd 服务..."
    cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=SimpleVPN SOCKS5 Server
After=network.target

[Service]
Type=simple
User=socks5
WorkingDirectory=/opt/simplevpn
ExecStart=/usr/bin/python3 /opt/simplevpn/socks5_server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    chmod 644 "$SERVICE_FILE"
    systemctl daemon-reload
    print_success "Systemd 服务已创建"
    
    print_success "安装完成！"
    press_enter
}

################################################################################
# 启动/停止功能
################################################################################

start_service() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "启动 SOCKS5 服务"
    
    # 检查端口是否被占用
    PORT=$(grep "^PORT" "$CONFIG_FILE" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
    print_info "检查端口 $PORT..."
    
    # 更积极地清理端口
    if ss -tlnp 2>/dev/null | grep -q ":$PORT"; then
        print_warning "端口 $PORT 已被占用，开始清理..."
        
        # 第一步：尝试正常杀死进程
        print_info "第一步：杀死 SOCKS5 服务进程..."
        systemctl stop $SERVICE_NAME 2>/dev/null || true
        sleep 1
        
        # 第二步：强制杀死所有 Python SOCKS5 进程
        print_info "第二步：强制杀死 Python 进程..."
        pkill -9 -f "socks5_server.py" 2>/dev/null || true
        sleep 2
        
        # 第三步：使用 fuser 杀死占用端口的所有进程
        if command -v fuser &> /dev/null; then
            print_info "第三步：使用 fuser 清理端口..."
            fuser -k $PORT/tcp 2>/dev/null || true
            sleep 2
        fi
        
        # 第四步：调整 TCP 参数加快端口释放
        print_info "第四步：调整 TCP 参数..."
        sysctl -w net.ipv4.tcp_fin_timeout=10 2>/dev/null || true
        sleep 1
        
        # 检查是否清空成功
        if ss -tlnp 2>/dev/null | grep -q ":$PORT"; then
            print_error "无法清空端口，可能需要手动处理"
            echo ""
            print_info "占用进程信息："
            lsof -i :$PORT 2>/dev/null || netstat -tlnp 2>/dev/null | grep $PORT || echo "无法获取信息"
            echo ""
            print_info "尝试运行以下命令清理："
            echo "  sudo fuser -k $PORT/tcp"
            echo "  sudo lsof -i :$PORT | awk 'NR>1 {print \$2}' | xargs kill -9"
            press_enter
            return
        fi
        print_success "端口已清空"
    fi
    
    print_info "启动服务..."
    systemctl start $SERVICE_NAME
    sleep 3
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "服务已启动"
        sleep 1
        status_service
    else
        print_error "服务启动失败"
        print_info "查看日志以了解详细信息..."
        sleep 2
        logs_realtime
    fi
}

stop_service() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "停止 SOCKS5 服务"
    print_info "停止服务..."
    systemctl stop $SERVICE_NAME
    sleep 1
    print_success "服务已停止"
    press_enter
}

restart_service() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "重启 SOCKS5 服务"
    print_info "重启服务..."
    systemctl restart $SERVICE_NAME
    sleep 2
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "服务已重启"
        sleep 1
        status_service
    else
        print_error "服务重启失败"
        press_enter
    fi
}

################################################################################
# 状态功能
################################################################################

status_service() {
    print_header "服务状态"
    
    if systemctl is-active --quiet $SERVICE_NAME; then
        print_success "服务运行中"
    else
        print_error "服务未运行"
    fi
    
    echo ""
    systemctl status $SERVICE_NAME --no-pager 2>/dev/null | head -20 || echo "无法获取服务状态"
    
    echo ""
    print_info "网络连接:"
    PORT=$(grep "^PORT" "$CONFIG_FILE" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
    
    # 更可靠的端口检查方法
    if ss -tlnp 2>/dev/null | grep -E "python.*socks5|:$PORT\s" | grep -q "LISTEN"; then
        print_success "SOCKS5 在监听端口 $PORT"
    elif ss -tlnp 2>/dev/null | grep -q "python3.*socks5_server.py"; then
        # 如果能找到 python3 进程但端口检查失败，说明服务在运行但可能是其他原因
        ACTUAL_PORT=$(ss -tlnp 2>/dev/null | grep "python3.*socks5_server.py" | awk '{print $4}' | awk -F: '{print $NF}' | head -1)
        if [ -n "$ACTUAL_PORT" ]; then
            print_success "SOCKS5 在监听端口 $ACTUAL_PORT"
        else
            # 尝试从日志读取
            ACTUAL_PORT=$(sudo journalctl -u $SERVICE_NAME -n 50 --no-pager 2>/dev/null | grep "listening on" | tail -1 | grep -oP ':\K[0-9]+' | tail -1)
            if [ -n "$ACTUAL_PORT" ]; then
                print_success "SOCKS5 在监听端口 $ACTUAL_PORT"
            else
                print_warning "SOCKS5 未能检测到监听端口"
            fi
        fi
    else
        print_warning "SOCKS5 未运行"
    fi
    
    press_enter
}

################################################################################
# 配置功能
################################################################################

edit_config() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "编辑配置文件"
    print_info "打开配置文件进行编辑..."
    nano "$CONFIG_FILE"
    
    print_info "重启服务以应用变更..."
    systemctl restart $SERVICE_NAME
    print_success "配置已更新，服务已重启"
    press_enter
}

view_config() {
    if ! check_installation; then press_enter; return; fi
    
    print_header "当前配置"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo ""
        grep -E "^(HOST|PORT|USERNAME|PASSWORD|MAX_CONNECTIONS|SOCKET_TIMEOUT|LOG_LEVEL)" "$CONFIG_FILE" 2>/dev/null || print_error "无法读取配置"
    else
        print_error "配置文件不存在"
    fi
    
    press_enter
}

################################################################################
# 日志功能
################################################################################

logs_realtime() {
    if ! check_installation; then press_enter; return; fi
    
    print_header "实时日志（按 Ctrl+C 停止）"
    echo ""
    
    if command -v journalctl &> /dev/null; then
        journalctl -u $SERVICE_NAME -f 2>/dev/null || true
    elif [[ -f "$LOG_FILE" ]]; then
        tail -f "$LOG_FILE"
    else
        print_error "无法访问日志"
    fi
    
    echo ""
    press_enter
}

logs_tail() {
    if ! check_installation; then press_enter; return; fi
    
    print_header "最近日志 (100 行)"
    echo ""
    
    if command -v journalctl &> /dev/null; then
        journalctl -u $SERVICE_NAME -n 100 --no-pager 2>/dev/null || echo "无法获取日志"
    elif [[ -f "$LOG_FILE" ]]; then
        tail -100 "$LOG_FILE"
    else
        print_error "日志文件不存在"
    fi
    
    press_enter
}

clear_logs() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "清空日志"
    
    read -p "确实要清空日志吗？ (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "清空日志..."
        > "$LOG_FILE" 2>/dev/null || true
        print_success "日志已清空"
    else
        print_info "已取消"
    fi
    
    press_enter
}

################################################################################
# 诊断功能
################################################################################

diagnose() {
    print_header "系统诊断"
    
    echo ""
    print_info "系统信息:"
    grep "^NAME\|^VERSION" /etc/os-release 2>/dev/null | head -2 || echo "无法获取"
    
    echo ""
    print_info "Python 版本:"
    python3 --version 2>&1 || echo "未安装"
    
    echo ""
    print_info "安装状态:"
    if [[ -d "$INSTALL_DIR" ]]; then
        print_success "SimpleVPN 已安装在 $INSTALL_DIR"
        du -sh "$INSTALL_DIR" 2>/dev/null || echo "无法获取大小"
    else
        print_error "SimpleVPN 未安装"
    fi
    
    echo ""
    print_info "服务状态:"
    systemctl is-active $SERVICE_NAME &>/dev/null && print_success "运行中" || print_error "未运行"
    
    echo ""
    print_info "用户检查:"
    id socks5 &>/dev/null && print_success "socks5 用户存在" || print_error "socks5 用户不存在"
    
    echo ""
    print_info "端口监听:"
    PORT=$(grep "^PORT" "$CONFIG_FILE" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
    if ss -tlnp 2>/dev/null | grep -q python3; then
        print_success "SOCKS5 服务正在监听"
    else
        print_warning "SOCKS5 未监听"
    fi
    
    echo ""
    print_info "配置文件:"
    if [[ -f "$CONFIG_FILE" ]]; then
        print_success "配置文件存在"
        grep "^PORT" "$CONFIG_FILE" 2>/dev/null || echo "PORT 配置未找到"
    else
        print_error "配置文件不存在"
    fi
    
    press_enter
}

################################################################################
# 开机启动功能
################################################################################

enable_service() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "启用开机启动"
    print_info "启用开机启动..."
    systemctl enable $SERVICE_NAME
    print_success "已启用开机启动"
    press_enter
}

disable_service() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "禁用开机启动"
    print_info "禁用开机启动..."
    systemctl disable $SERVICE_NAME
    print_success "已禁用开机启动"
    press_enter
}

################################################################################
# 端口管理
################################################################################

clear_port() {
    check_root
    if ! check_installation; then press_enter; return; fi
    
    print_header "清空占用的端口"
    
    PORT=$(grep "^PORT" "$CONFIG_FILE" 2>/dev/null | awk -F'=' '{print $2}' | tr -d ' ')
    print_info "检查端口 $PORT..."
    
    if ss -tlnp 2>/dev/null | grep -q ":$PORT"; then
        print_warning "端口 $PORT 已被占用"
        echo ""
        ss -tlnp 2>/dev/null | grep ":$PORT"
        echo ""
        
        print_info "杀死占用进程..."
        pkill -9 -f "socks5_server.py" 2>/dev/null || true
        sleep 1
        
        if ss -tlnp 2>/dev/null | grep -q ":$PORT"; then
            print_error "无法清空端口"
        else
            print_success "端口已清空"
        fi
    else
        print_success "端口 $PORT 未被占用"
    fi
    
    press_enter
}

################################################################################
# 重置功能
################################################################################

reset_service() {
    check_root
    
    print_header "完全重置"
    print_warning "此操作将删除所有数据！"
    echo ""
    read -p "确实要继续吗？输入 'yes' 确认: " -r
    
    if [[ $REPLY != "yes" ]]; then
        print_info "已取消"
        press_enter
        return
    fi
    
    print_info "停止服务..."
    systemctl stop $SERVICE_NAME 2>/dev/null || true
    
    print_info "删除 systemd 服务..."
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    
    print_info "删除安装目录..."
    rm -rf "$INSTALL_DIR"
    
    print_info "删除用户..."
    userdel socks5 2>/dev/null || true
    
    print_success "重置完成"
    press_enter
}

################################################################################
# 主菜单
################################################################################

show_menu() {
    print_header "SimpleVPN 服务器管理工具"
    
    echo -e "${CYAN}════ 服务管理 ════${NC}"
    echo "  1) 安装 SimpleVPN"
    echo "  2) 启动服务"
    echo "  3) 停止服务"
    echo "  4) 重启服务"
    echo ""
    
    echo -e "${CYAN}════ 查看信息 ════${NC}"
    echo "  5) 查看服务状态"
    echo "  6) 实时查看日志"
    echo "  7) 查看最近日志"
    echo ""
    
    echo -e "${CYAN}════ 配置管理 ════${NC}"
    echo "  8) 编辑配置文件"
    echo "  9) 查看当前配置"
    echo ""
    
    echo -e "${CYAN}════ 系统管理 ════${NC}"
    echo " 10) 启用开机启动"
    echo " 11) 禁用开机启动"
    echo " 12) 系统诊断"
    echo " 13) 清空日志"
    echo " 14) 清空占用的端口"
    echo " 15) 完全重置"
    echo ""
    
    echo -e "${CYAN}════ 其他 ════${NC}"
    echo "  0) 退出"
    echo ""
    
    read -p "请选择操作 [0-15]: " choice
    echo ""
    
    case $choice in
        1) install ;;
        2) start_service ;;
        3) stop_service ;;
        4) restart_service ;;
        5) status_service ;;
        6) logs_realtime ;;
        7) logs_tail ;;
        8) edit_config ;;
        9) view_config ;;
        10) enable_service ;;
        11) disable_service ;;
        12) diagnose ;;
        13) clear_logs ;;
        14) clear_port ;;
        15) reset_service ;;
        0) 
            print_info "再见！"
            exit 0
            ;;
        *)
            print_error "无效的选择"
            sleep 2
            ;;
    esac
}

################################################################################
# 主程序
################################################################################

main() {
    # 检查是否在 server 目录
    if [[ ! -f "socks5_server.py" ]]; then
        print_error "请在 server 目录中运行此脚本"
        exit 1
    fi
    
    while true; do
        show_menu
    done
}

main "$@"
