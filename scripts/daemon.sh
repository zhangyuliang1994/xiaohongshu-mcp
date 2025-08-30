#!/bin/bash

# xiaohongshu-mcp 守护进程管理脚本
# 使用方法: ./scripts/daemon.sh {start|stop|restart|status} [cookies_path]

# 配置
PID_FILE="/var/run/xiaohongshu-mcp.pid"
LOG_FILE="/var/log/xiaohongshu-mcp.log"
BINARY_NAME="xiaohongshu-mcp"
WORK_DIR=$(cd "$(dirname "$0")/.." && pwd)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARN:${NC} $1"
}

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要root权限运行"
        error "请使用: sudo $0 $*"
        exit 1
    fi
}

# 检查Go命令是否可用
check_go() {
    if ! command -v go &> /dev/null; then
        error "Go命令未找到"
        error "请安装Go语言环境: https://golang.org/doc/install"
        error "或确保Go已添加到PATH环境变量中"
        exit 1
    fi
}

# 构建二进制文件
build_binary() {
    check_go
    log "构建二进制文件..."
    cd "$WORK_DIR"
    go build -o "$BINARY_NAME" .
    if [ $? -ne 0 ]; then
        error "构建失败"
        exit 1
    fi
    log "构建完成: $WORK_DIR/$BINARY_NAME"
}

# 启动服务
start() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            warn "服务已在运行中 (PID: $pid)"
            return 0
        else
            log "删除过期的PID文件"
            rm -f "$PID_FILE"
        fi
    fi

    # 检查并构建二进制文件
    if [ ! -f "$WORK_DIR/$BINARY_NAME" ]; then
        build_binary
    fi

    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 设置环境变量
    if [ -n "$1" ]; then
        export XIAOHONGSHU_COOKIES_PATH="$1"
        log "使用指定的cookies路径: $1"
    fi

    log "启动 xiaohongshu-mcp 服务..."
    cd "$WORK_DIR"
    
    # 使用nohup后台运行
    nohup "./$BINARY_NAME" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    
    # 等待一下确保启动成功
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
        echo "$pid" > "$PID_FILE"
        log "服务启动成功 (PID: $pid)"
        log "日志文件: $LOG_FILE"
        log "PID文件: $PID_FILE"
    else
        error "服务启动失败"
        error "请检查日志: $LOG_FILE"
        exit 1
    fi
}

# 停止服务
stop() {
    if [ ! -f "$PID_FILE" ]; then
        warn "PID文件不存在，服务可能未运行"
        return 0
    fi

    local pid=$(cat "$PID_FILE")
    log "停止服务 (PID: $pid)..."
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid"
        
        # 等待进程结束
        local count=0
        while kill -0 "$pid" 2>/dev/null && [ $count -lt 10 ]; do
            sleep 1
            count=$((count + 1))
        done
        
        if kill -0 "$pid" 2>/dev/null; then
            warn "进程未响应SIGTERM，使用SIGKILL强制终止"
            kill -9 "$pid"
            sleep 1
        fi
        
        if ! kill -0 "$pid" 2>/dev/null; then
            log "服务已停止"
            rm -f "$PID_FILE"
        else
            error "无法停止服务"
            exit 1
        fi
    else
        warn "进程不存在，清理PID文件"
        rm -f "$PID_FILE"
    fi
}

# 重启服务
restart() {
    log "重启服务..."
    stop
    sleep 1
    start "$1"
}

# 查看状态
status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "服务正在运行 (PID: $pid)"
            
            # 显示进程信息
            echo "进程信息:"
            ps aux | grep "$pid" | grep -v grep
            
            # 显示网络监听
            echo ""
            echo "网络监听:"
            netstat -tlnp 2>/dev/null | grep ":18060" || ss -tlnp | grep ":18060"
            
            # 显示最近日志
            if [ -f "$LOG_FILE" ]; then
                echo ""
                echo "最近日志 (最后10行):"
                tail -10 "$LOG_FILE"
            fi
        else
            warn "PID文件存在但进程未运行，清理PID文件"
            rm -f "$PID_FILE"
            error "服务未运行"
            exit 1
        fi
    else
        error "服务未运行"
        exit 1
    fi
}

# 显示日志
logs() {
    if [ -f "$LOG_FILE" ]; then
        if [ "$1" = "-f" ]; then
            tail -f "$LOG_FILE"
        else
            tail -50 "$LOG_FILE"
        fi
    else
        error "日志文件不存在: $LOG_FILE"
        exit 1
    fi
}

# 显示帮助
usage() {
    echo "xiaohongshu-mcp 守护进程管理脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 start [cookies_path]    启动服务"
    echo "  $0 stop                    停止服务"
    echo "  $0 restart [cookies_path]  重启服务"
    echo "  $0 status                  查看状态"
    echo "  $0 logs [-f]               查看日志 (-f 实时跟踪)"
    echo "  $0 build                   构建二进制文件"
    echo ""
    echo "参数:"
    echo "  cookies_path              cookies文件路径 (可选)"
    echo ""
    echo "示例:"
    echo "  sudo $0 start /home/user/cookies.json"
    echo "  sudo $0 restart"
    echo "  sudo $0 status"
    echo "  sudo $0 logs -f"
}

# 主逻辑
case "$1" in
    start)
        check_root
        start "$2"
        ;;
    stop)
        check_root
        stop
        ;;
    restart)
        check_root
        restart "$2"
        ;;
    status)
        status
        ;;
    logs)
        logs "$2"
        ;;
    build)
        build_binary
        ;;
    *)
        usage
        exit 1
        ;;
esac