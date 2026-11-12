// HDR Shield — a menu bar utility that clamps HDR highlights on the displays you choose.
// HDR Shield —— 菜单栏小工具，在你选择的显示器上压暗 HDR 高光。
//
// Left-click the icon for the menu; right-click (or Control-click) to turn shielding on or off.
// 左键点击图标打开菜单；右键（或 Control+点击）开关遮光。
//
// How it works: installing a custom gamma table through the public CoreGraphics API makes
// macOS clip HDR content to SDR white. The table is removed when the app quits.
// 原理：通过公开的 CoreGraphics API 套用自定义色表（gamma table）后，macOS 会把 HDR 内容
// 裁切到 SDR 白。退出 app 后色表自动恢复。
//
// Files / 文件:
//   main.swift         app bootstrap / 启动入口
//   AppDelegate.swift  status item, menu, toggling / 菜单栏图标、菜单、开关逻辑
//   MenuRows.swift     menu rows with a switch or checkbox / 带开关或复选框的菜单行
//   MenuBarIcon.swift  loads the sunglasses menu bar icon / 加载菜单栏墨镜图标
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
