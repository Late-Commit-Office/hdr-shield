> **Notice:** The code in this repository was written by an LLM (Claude). Review it before you rely on it.
>
> **声明:** 本仓库的代码由 LLM(Claude)编写,使用前请自行审阅。

<h1><img src="Resources/AppIcon.png" width="128" height="128" alt="" align="center"> HDR Shield</h1>

[English](#english) | [简体中文](#简体中文)

## English

HDR Shield is a tiny macOS menu bar app that stops HDR content from blasting past your screen's normal brightness on the MacBook's built-in display. One click turns it on or off.

### Why

On MacBooks, HDR videos and photos are shown brighter than everything else on screen, and macOS has no switch to turn this off for the built-in display. That can be uncomfortable, especially in a dark room.

### How it works

HDR Shield installs a custom gamma table on the built-in display through the public CoreGraphics API (`CGSetDisplayTransferByTable`). While a custom table is active, macOS clips HDR content to SDR white. Turning HDR Shield off, or quitting it, restores the default table.

### Requirements

- macOS 13 Ventura or later
- A Mac with a built-in display (Apple silicon or Intel)

### Install

**Download:** get `HDR-Shield.zip` from the Releases page, unzip it, and move `HDR Shield.app` to the Applications folder. The app is not notarized, so macOS will block it the first time. Remove the quarantine flag to allow it:

```bash
xattr -dr com.apple.quarantine "/Applications/HDR Shield.app"
```

**Build from source:** you need Xcode or the Command Line Tools.

```bash
bash build.sh
```

This produces a universal `HDR Shield.app` in the current folder. Move it to the Applications folder.

### Usage

- **Left-click** the menu bar icon to toggle. Filled sunglasses mean HDR highlights are clamped; outline sunglasses mean normal behavior.
- **Right-click** (or Control-click) the icon for the menu: Launch at Login and Quit.
- The app remembers its last state. Clamping is on at first launch.

### Configuration

If clamping has no effect on your Mac, change `clampLevel` at the top of `Sources/Displays.swift` from `1.0` to `0.98` and rebuild. This makes the whole screen very slightly dimmer.

### Project layout

```
Sources/
  main.swift          app bootstrap
  AppDelegate.swift   status item, menu, toggling
  Displays.swift      display lookup and gamma tables
  Strings.swift       user-facing strings
Resources/
  AppIcon.png         1024×1024 app icon
build.sh              builds the universal app
```

### Limitations

- HDR highlights are clipped, not tone-mapped, so detail in very bright areas is lost.
- Only the built-in display is affected.
- Other apps that change gamma tables (for example BetterDisplay or f.lux) may conflict with it.
- Turning clamping off restores the default gamma tables on all displays.

### Uninstall

Turn off Launch at Login from the menu, quit the app, and delete `HDR Shield.app`.

---

## 简体中文

HDR Shield 是一个很小的 macOS 菜单栏 app,用来阻止 HDR 内容在 MacBook 内建屏幕上超出正常亮度。点一下即可开关。

### 为什么需要它

在 MacBook 上,HDR 视频和照片会比屏幕上的其他内容更亮,而 macOS 没有提供针对内建屏幕的关闭开关。这在暗处尤其刺眼。

### 原理

HDR Shield 通过公开的 CoreGraphics API(`CGSetDisplayTransferByTable`)给内建屏幕套用一张自定义色表(gamma table)。自定义色表生效期间,macOS 会把 HDR 内容裁切到 SDR 白。关闭 HDR Shield 或退出 app 后,色表恢复默认。

### 系统要求

- macOS 13 Ventura 或更高版本
- 带内建屏幕的 Mac(Apple 芯片或 Intel)

### 安装

**下载:** 从 Releases 页面下载 `HDR-Shield.zip`,解压后把 `HDR Shield.app` 移到「应用程序」文件夹。app 没有经过公证,第一次打开会被 macOS 拦截,用下面的命令移除隔离标记即可:

```bash
xattr -dr com.apple.quarantine "/Applications/HDR Shield.app"
```

**从源码构建:** 需要 Xcode 或 Command Line Tools。

```bash
bash build.sh
```

当前文件夹下会生成通用二进制的 `HDR Shield.app`,把它移到「应用程序」文件夹。

### 使用

- **左键点击**菜单栏图标切换开关。实心墨镜表示 HDR 高光已压制,空心墨镜表示正常。
- **右键点击**(或按住 Control 点击)图标打开菜单:登录时启动、退出。
- app 会记住上次的状态,第一次启动默认开启压制。

### 配置

如果压制在你的 Mac 上不起作用,把 `Sources/Displays.swift` 顶部的 `clampLevel` 从 `1.0` 改成 `0.98` 后重新构建。整个屏幕会略微变暗一点。

### 项目结构

```
Sources/
  main.swift          启动入口
  AppDelegate.swift   菜单栏图标、菜单、开关逻辑
  Displays.swift      查找显示器、套用色表
  Strings.swift       界面文字
Resources/
  AppIcon.png         1024×1024 app 图标
build.sh              构建通用二进制 app
```

### 局限

- HDR 高光是被直接裁切,而不是色调映射,所以很亮的区域会丢失细节。
- 只影响内建屏幕。
- 其他会修改色表的 app(例如 BetterDisplay、f.lux)可能与它冲突。
- 关闭压制时,会恢复所有显示器的默认色表。

### 卸载

在菜单里关闭「登录时启动」,退出 app,然后删除 `HDR Shield.app`。
