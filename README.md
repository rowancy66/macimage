# macimage

轻量级 macOS 图片查看器，在原生预览基础上增加文件夹内图片翻页功能。

## ✨ 功能

- **同目录翻页** — 打开一张图片，自动扫描同目录下所有图片，支持翻页浏览
- **多种翻页方式** — 键盘左右箭头、鼠标滚轮、触控板双指滑动
- **缩放** — 触控板双指捏合、键盘 `+` `-`、双击缩放
- **旋转** — 键盘 `[` `]` 左旋/右旋
- **全屏** — 按 `F` 或 `Enter` 进入全屏模式
- **图片信息** — 按 `I` 显示文件名、尺寸、大小、格式
- **复制图片** — `Cmd+C` 复制图片到剪贴板
- **快速跳转** — 输入数字跳转到指定图片
- **记住位置** — 记住每个文件夹最后浏览的图片
- **深色/浅色模式** — 自动跟随系统设置

## 📦 安装

### 从 Release 下载

1. 前往 [Releases](https://github.com/yourusername/macimage/releases) 页面
2. 下载最新版本的 `macimage.dmg`
3. 拖拽 `macimage.app` 到 `Applications` 文件夹

### 从源码构建

```bash
git clone https://github.com/yourusername/macimage.git
cd macimage
open macimage.xcodeproj
```

在 Xcode 中点击 `Run` 或按 `Cmd+R`。

## 🎯 设置为默认图片查看器

1. 右键任意图片文件
2. 选择「显示简介」（或按 `Cmd+I`）
3. 在「打开方式」下拉菜单中选择 `macimage`
4. 点击「全部更改」

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `←` | 上一张 |
| `→` / `Space` | 下一张 |
| `[` | 左旋 90° |
| `]` | 右旋 90° |
| `+` / `=` | 放大 |
| `-` | 缩小 |
| `0` | 适配窗口 |
| `F` / `Enter` | 全屏 |
| `Esc` | 退出全屏 |
| `I` | 显示/隐藏图片信息 |
| `Cmd+C` | 复制图片 |
| `0-9` + `Enter` | 快速跳转 |

## 🖥️ 系统要求

- macOS 13 Ventura 或更高版本

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交你的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开一个 Pull Request
