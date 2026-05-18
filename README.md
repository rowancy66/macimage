# macimage

轻量级 macOS 图片查看器 — 在 Finder 中浏览图片，支持同目录翻页。

## 功能

- 拖放或双击图片打开
- 自动扫描同目录所有图片，← → 翻页
- 原生缩放（触控板捏合 / +/- 键）
- 旋转（[ / ] 键）
- 全屏（F 键）
- 缩略图侧边栏（T 键开关）
- 图片信息浮层（I 键）
- 复制到剪贴板（⌘C）
- 记住上次浏览位置

## 快捷键

| 键 | 功能 |
|---|---|
| `←` `→` | 上下张 |
| `Space` | 下一张 |
| `F` / `Enter` | 全屏 |
| `Esc` | 退出全屏 |
| `[` `]` | 旋转 |
| `+` `-` `0` | 缩放 / 适配 |
| `I` | 图片信息 |
| `T` | 缩略图侧边栏 |
| `⌘C` | 复制 |

## 构建

```bash
swift build -c release
```

## 打包为 .app

```bash
APP="macimage.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/macimage "$APP/Contents/MacOS/"
echo -n 'APPL????' > "$APP/Contents/PkgInfo"
# Info.plist 需包含 CFBundleDocumentTypes 注册图片格式
```

## 支持格式

JPG / JPEG / PNG / GIF / BMP / TIFF / WebP

## 技术栈

Swift 5.9+ · AppKit · SwiftUI · macOS 13+

## 开源协议

MIT
