package main

import (
	"fmt"
	"os"

	"github.com/xpzouying/xiaohongshu-mcp/cookies"
)

func main() {
	path := cookies.GetCookiesFilePath()
	fmt.Printf("Cookies文件路径: %s\n", path)

	if customPath := os.Getenv("XIAOHONGSHU_COOKIES_PATH"); customPath != "" {
		fmt.Printf("🔧 使用自定义路径（环境变量）\n")
	} else {
		fmt.Printf("📁 使用默认路径（系统临时目录）\n")
	}

	if _, err := os.Stat(path); os.IsNotExist(err) {
		fmt.Printf("❌ Cookies文件不存在\n")
		fmt.Printf("💡 请先在本地运行 'go run cmd/login/main.go' 完成登录\n")
	} else {
		fmt.Printf("✅ Cookies文件存在\n")

		// 显示文件信息
		if info, err := os.Stat(path); err == nil {
			fmt.Printf("📊 文件大小: %d bytes\n", info.Size())
			fmt.Printf("🕐 修改时间: %s\n", info.ModTime().Format("2006-01-02 15:04:05"))
		}
	}
}
