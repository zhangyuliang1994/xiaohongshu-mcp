# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Run
- `go run .` - Start MCP server in headless mode (default port 18060)
- `go run . -headless=false` - Start server with browser UI visible
- `go run cmd/login/main.go` - Manual login to xiaohongshu (required for first use)

### Testing
- `go test ./...` - Run all tests
- `go test ./xiaohongshu` - Test xiaohongshu package
- `go test ./pkg/downloader` - Test image downloader

### Code Quality
- `go fmt ./...` - Format all Go source files (required after modifications)
- `go mod tidy` - Clean up module dependencies

## Architecture Overview

This is a Model Context Protocol (MCP) server that enables AI clients to interact with xiaohongshu.com through browser automation.

### Core Components

1. **MCP Server Layer** (`main.go`, `app_server.go`, `handlers_mcp.go`)
   - HTTP server implementing JSON-RPC over HTTP for MCP protocol
   - Provides 4 MCP tools: check_login_status, publish_content, list_feeds, search_feeds
   - Runs on port 18060 with `/mcp` endpoint

2. **Business Service Layer** (`service.go`)
   - `XiaohongshuService` orchestrates browser automation and image processing
   - Handles login status checks, content publishing, feed listing, and search

3. **Browser Automation** (`xiaohongshu/` package)
   - Uses go-rod for headless browser automation
   - Separate modules for login, publishing, feeds, search, and navigation
   - Supports both headless and visible browser modes

4. **Image Processing** (`pkg/downloader/`)
   - Downloads images from URLs and validates local paths
   - Supports HTTP/HTTPS URLs and local file paths
   - Handles image format validation and processing

5. **Configuration** (`configs/` package)
   - Manages browser settings, user preferences, and headless mode
   - Stores username and browser configuration

### Key Architectural Patterns

- **Service-oriented**: Clear separation between MCP protocol, business logic, and browser automation
- **Context propagation**: Uses Go context throughout for cancellation and timeouts
- **Resource management**: Proper cleanup of browser instances and pages
- **Error handling**: Structured error responses for both HTTP API and MCP protocol

### MCP Integration

The server implements MCP 2024-11-05 protocol specification:
- JSON-RPC 2.0 over HTTP transport
- Standard MCP methods: initialize, tools/list, tools/call
- CORS support for web-based MCP clients
- Compatible with Claude Desktop, Cursor, VSCode, and other MCP clients

## Server Deployment Guide

### 服务器部署（推荐方案）

由于服务器环境通常无法打开浏览器进行登录，需要先在本地完成登录后将cookies传输到服务器。

#### 步骤1: 本地登录
```bash
# 在本地机器运行登录程序
go run cmd/login/main.go
```

#### 步骤2: 查找cookies文件
```bash
# 检查cookies文件路径和状态
go run scripts/check_cookies_path.go
```

#### 步骤3: 上传cookies到服务器
将本地的`cookies.json`文件上传到服务器任意位置，如`/home/user/xiaohongshu_cookies.json`

#### 步骤4: 服务器启动
```bash
# 方式1: 使用部署脚本（推荐）
./scripts/deploy_server.sh /home/user/xiaohongshu_cookies.json

# 方式2: 手动设置环境变量
export XIAOHONGSHU_COOKIES_PATH="/home/user/xiaohongshu_cookies.json"
go run .
```

#### 环境变量配置
- `XIAOHONGSHU_COOKIES_PATH`: 自定义cookies文件路径（可选，默认使用系统临时目录）

### Cookies存储机制
- 默认存储位置: 系统临时目录 + `cookies.json`
- 支持环境变量 `XIAOHONGSHU_COOKIES_PATH` 自定义路径
- JSON格式存储浏览器cookies数据
- 登录状态通过持久化cookies维持

## Development Guidelines

- 要求每次修改完后，需要帮我格式化 Go 源码文件
- 测试过程中产生的脚本和build中间文件，如果没有必要，则删除
- Always run `go fmt ./...` after code modifications
- Use browser automation responsibly - ensure proper page cleanup
- Test MCP integration using: `npx @modelcontextprotocol/inspector`
- Images must be validated before processing (both URLs and local paths)