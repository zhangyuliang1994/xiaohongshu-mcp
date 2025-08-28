#!/bin/bash

# 服务器部署脚本 - 小红书MCP服务
# 使用方法: ./deploy_server.sh [cookies_file_path]

set -e

echo "🚀 小红书MCP服务 - 服务器部署脚本"
echo "================================"

# 检查是否提供了cookies文件路径
COOKIES_FILE=""
if [ $# -eq 1 ]; then
    COOKIES_FILE="$1"
    echo "📁 使用提供的cookies文件: $COOKIES_FILE"
else
    echo "⚠️  未提供cookies文件路径，将使用默认临时目录"
    echo "   使用方法: $0 /path/to/cookies.json"
fi

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ Go未安装，请先安装Go环境"
    exit 1
fi

echo "✅ Go环境检查通过"

# 检查cookies文件（如果提供）
if [ -n "$COOKIES_FILE" ]; then
    if [ ! -f "$COOKIES_FILE" ]; then
        echo "❌ Cookies文件不存在: $COOKIES_FILE"
        echo "💡 请确保已从本地机器复制cookies.json文件到服务器"
        exit 1
    fi
    
    # 设置环境变量
    export XIAOHONGSHU_COOKIES_PATH="$COOKIES_FILE"
    echo "🔧 设置环境变量: XIAOHONGSHU_COOKIES_PATH=$COOKIES_FILE"
fi

# 检查cookies状态
echo "🔍 检查cookies状态..."
go run scripts/check_cookies_path.go

# 检查端口18060是否可用
if lsof -i :18060 &> /dev/null; then
    echo "⚠️  端口18060已被占用，请先停止相关进程"
    lsof -i :18060
    exit 1
fi

echo "✅ 端口18060可用"

# 构建并启动服务
echo "🏗️  构建服务..."
go build -o xiaohongshu-mcp .

echo "🌟 启动小红书MCP服务..."
echo "   服务地址: http://localhost:18060/mcp"
echo "   使用 Ctrl+C 停止服务"
echo ""

if [ -n "$COOKIES_FILE" ]; then
    XIAOHONGSHU_COOKIES_PATH="$COOKIES_FILE" ./xiaohongshu-mcp
else
    ./xiaohongshu-mcp
fi