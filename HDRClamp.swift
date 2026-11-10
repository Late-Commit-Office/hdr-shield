// HDRClamp — a menu bar utility that toggles clamping of HDR highlights on the built-in display.
// HDRClamp —— 菜单栏小工具,一键开关内建屏幕的"HDR 高光压制"。
//
// Left-click the icon to toggle; right-click (or Control-click) for the menu.
// 左键点击图标切换开关;右键(或 Control+点击)打开菜单。
//
// How it works: installing a custom gamma table through the public CoreGraphics API makes
// macOS clip HDR content to SDR white. The table is removed when the app quits.
// 原理:通过公开的 CoreGraphics API 套用自定义色表(gamma table)后,macOS 会把 HDR 内容
// 裁切到 SDR 白。退出 app 后色表自动恢复。

import AppKit
import ServiceManagement

/// Upper bound of the gamma table. If a 1:1 table (1.0) has no effect on your Mac, try 0.98.
/// 色表上限。如果 1:1 的色表(1.0)在你的 Mac 上不起作用,改成 0.98 试试。
let clampLevel: Float = 1.0

/// Picks the Chinese string when the system language is Chinese, English otherwise.
/// 系统语言为中文时使用中文字符串,否则使用英文。
let prefersChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
func L(_ en: String, _ zh: String) -> String { prefersChinese ? zh : en }

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var clamped = false
    private let table: [CGGammaValue] = (0..<256).map { Float($0) / 255 * clampLevel }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // The system resets the gamma table after wake and display reconfiguration, so reapply it.
        // 睡眠唤醒、屏幕配置变化后系统会重置色表,需要重新套用。
        NotificationCenter.default.addObserver(
            self, selector: #selector(reapply),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(reapply),
            name: NSWorkspace.didWakeNotification, object: nil)

        // Restore the last state; clamping is on by default at first launch.
        // 恢复上次的状态;第一次启动默认开启压制。
        let saved = UserDefaults.standard.object(forKey: "clamped") as? Bool ?? true
        setClamped(saved)
    }

    // MARK: - Toggle / 开关

    private func setClamped(_ on: Bool) {
        clamped = on
        UserDefaults.standard.set(on, forKey: "clamped")

        timer?.invalidate()
        timer = nil

        if on {
            applyTable()
            // Reapply periodically in case something else reset the table.
            // 定时重新套用,以防色表被其他操作重置。
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                self?.applyTable()
            }
        } else {
            // Restores the default gamma tables (for all displays).
            // 恢复默认色表(对所有显示器生效)。
            CGDisplayRestoreColorSyncSettings()
        }
        updateIcon()
    }

    private func applyTable() {
        guard let display = builtinDisplay() else { return }
        CGSetDisplayTransferByTable(display, 256, table, table, table)
    }

    @objc private func reapply() {
        if clamped { applyTable() }
    }

    /// Finds the built-in display; external displays are left untouched.
    /// 查找内建显示器;外接显示器不受影响。
    private func builtinDisplay() -> CGDirectDisplayID? {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        CGGetOnlineDisplayList(16, &ids, &count)
        return ids.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 }
    }

    // MARK: - Menu bar / 菜单栏

    private var statusText: String {
        clamped ? L("HDR highlights: clamped", "HDR 高光:已压制")
                : L("HDR highlights: normal", "HDR 高光:正常")
    }

    private func updateIcon() {
        // Small sun = clamped, filled sun = normal.
        // 小太阳 = 已压制,实心太阳 = 正常。
        let symbol = clamped ? "sun.min" : "sun.max.fill"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: statusText)
        statusItem.button?.toolTip = statusText
            + L(" (click to toggle, right-click for menu)", "(点击切换,右键菜单)")
    }

    @objc private func clicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            setClamped(!clamped)
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        let status = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let login = NSMenuItem(title: L("Launch at Login", "登录时启动"),
                               action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        let quit = NSMenuItem(title: L("Quit", "退出"),
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quit)

        // Attach the menu only while it is shown, so a left-click still toggles directly.
        // 只在弹出时临时挂上菜单,这样左键仍然可以直接切换。
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleLoginItem() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = L("Could not change the login item", "无法更改登录项")
            alert.informativeText = L(
                "Move HDRClamp.app to the Applications folder and try again.",
                "请先把 HDRClamp.app 移到「应用程序」文件夹再试。")
                + "\n\n\(error.localizedDescription)"
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}

// No Dock icon: run as a menu bar accessory app.
// 不显示 Dock 图标:以菜单栏附属 app 的方式运行。
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
