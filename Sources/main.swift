// HDR Shield — a menu bar utility that toggles clamping of HDR highlights on the built-in display.
// HDR Shield —— 菜单栏小工具，一键开关内建屏幕的“HDR 高光压制”。
//
// Left-click the icon to toggle; right-click (or Control-click) for the menu.
// 左键点击图标切换开关；右键（或 Control+点击）打开菜单。
//
// How it works: installing a custom gamma table through the public CoreGraphics API makes
// macOS clip HDR content to SDR white. The table is removed when the app quits.
// 原理：通过公开的 CoreGraphics API 套用自定义色表（gamma table）后，macOS 会把 HDR 内容
// 裁切到 SDR 白。退出 app 后色表自动恢复。
//
// Files / 文件:
//   main.swift         app bootstrap / 启动入口
//   AppDelegate.swift  status item, menu, toggling / 菜单栏图标、菜单、开关逻辑
//   Displays.swift     display lookup and gamma tables / 查找显示器、套用色表
//   Strings.swift      user-facing strings / 界面文字

import AppKit

// No Dock icon: run as a menu bar accessory app.
// 不显示 Dock 图标：以菜单栏附属 app 的方式运行。
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
