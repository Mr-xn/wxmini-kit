//go:build linux

package wechat

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestLinuxGetDefaultPaths(t *testing.T) {
	homeDir := t.TempDir()
	configDir := filepath.Join(homeDir, ".config")
	t.Setenv("HOME", homeDir)
	t.Setenv("XDG_CONFIG_HOME", configDir)

	paths := []string{
		filepath.Join(configDir, "WeChat", "Applet"),
		filepath.Join(configDir, "Tencent", "xwechat", "radium", "Applet", "packages"),
		filepath.Join(configDir, "Tencent", "xwechat", "radium", "users", "account-1", "applet", "packages"),
		filepath.Join(homeDir, "Documents", "WeChat Files", "Applet"),
	}
	for _, path := range paths {
		if err := os.MkdirAll(path, 0o700); err != nil {
			t.Fatal(err)
		}
	}

	result := (&linuxPlatform{}).GetDefaultPaths()
	if !reflect.DeepEqual(result.Paths, paths) {
		t.Fatalf("GetDefaultPaths() paths = %v, want %v", result.Paths, paths)
	}
}
