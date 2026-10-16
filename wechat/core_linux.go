//go:build linux

package wechat

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type linuxPlatform struct{}

func newPlatform() platform { return &linuxPlatform{} }

func (p *linuxPlatform) GetDefaultPaths() PathScanResult {
	var b strings.Builder
	log := func(line string) { b.WriteString(line + "\n") }

	homeDir, err := os.UserHomeDir()
	if err != nil {
		log("获取用户目录失败: " + err.Error())
		return PathScanResult{Logs: b.String()}
	}

	configDir, err := os.UserConfigDir()
	if err != nil {
		log("获取配置目录失败: " + err.Error())
		return PathScanResult{Logs: b.String()}
	}

	paths := make([]string, 0, 4)
	appendIfDirectory := func(label, path string) {
		info, err := os.Stat(path)
		if err == nil && info.IsDir() {
			log(fmt.Sprintf("%s - 成功\n   路径: %s", label, path))
			paths = append(paths, path)
			return
		}
		log(fmt.Sprintf("%s - 目录不存在\n   路径: %s", label, path))
	}

	appendIfDirectory("检测微信 Linux 小程序目录", filepath.Join(configDir, "WeChat", "Applet"))
	appendIfDirectory("检测微信 v4 小程序目录", filepath.Join(configDir, "Tencent", "xwechat", "radium", "Applet", "packages"))

	usersDir := filepath.Join(configDir, "Tencent", "xwechat", "radium", "users")
	entries, err := os.ReadDir(usersDir)
	if err != nil {
		log(fmt.Sprintf("检测微信 v4 多用户目录失败\n   路径: %s", usersDir))
	} else {
		var found []string
		for _, entry := range entries {
			if !entry.IsDir() {
				continue
			}
			userAppletPath := filepath.Join(usersDir, entry.Name(), "applet", "packages")
			info, err := os.Stat(userAppletPath)
			if err == nil && info.IsDir() {
				paths = append(paths, userAppletPath)
				found = append(found, entry.Name())
			}
		}
		if len(found) == 0 {
			log(fmt.Sprintf("未找到微信 v4 多用户小程序目录\n   路径: %s", usersDir))
		} else {
			log(fmt.Sprintf("检测微信 v4 多用户小程序目录 - 成功\n   路径: %s\n   有效用户: %s", usersDir, strings.Join(found, ", ")))
		}
	}

	appendIfDirectory("检测微信旧版小程序目录", filepath.Join(homeDir, "Documents", "WeChat Files", "Applet"))
	return PathScanResult{Paths: paths, Logs: b.String()}
}
