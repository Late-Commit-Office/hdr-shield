import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var clamped = false

    private static let clampedKey = "clamped"
    /// Bundle ID used before the rename; its saved state is migrated once.
    /// 改名前使用的 bundle ID;其中保存的状态会迁移一次。
    private static let legacyBundleID = "local.hdrclamp"

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

        setClamped(savedState())
    }

    /// Restores the last state; clamping is on by default at first launch.
    /// Falls back to the state saved by HDRClamp (the old name) if there is one.
    /// 恢复上次的状态;第一次启动默认开启压制。如果有旧名 HDRClamp 保存的状态,则沿用它。
    private func savedState() -> Bool {
        if let saved = UserDefaults.standard.object(forKey: Self.clampedKey) as? Bool {
            return saved
        }
        if let legacy = UserDefaults(suiteName: Self.legacyBundleID)?
            .object(forKey: Self.clampedKey) as? Bool {
            return legacy
        }
        return true
    }

    // MARK: - Toggle / 开关

    private func setClamped(_ on: Bool) {
        clamped = on
        UserDefaults.standard.set(on, forKey: Self.clampedKey)

        timer?.invalidate()
        timer = nil

        if on {
            Displays.applyClamp()
            // Reapply periodically in case something else reset the table.
            // 定时重新套用,以防色表被其他操作重置。
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
                Displays.applyClamp()
            }
        } else {
            Displays.restoreAll()
        }
        updateIcon()
    }

    @objc private func reapply() {
        if clamped { Displays.applyClamp() }
    }

    // MARK: - Menu bar / 菜单栏

    private var statusText: String {
        clamped ? L("HDR highlights: clamped", "HDR 高光:已压制")
                : L("HDR highlights: normal", "HDR 高光:正常")
    }

    private func updateIcon() {
        // Filled sunglasses = clamped, outline sunglasses = normal.
        // 实心墨镜 = 已压制,空心墨镜 = 正常。
        let symbol = clamped ? "sunglasses.fill" : "sunglasses"
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

        let quit = NSMenuItem(title: L("Quit HDR Shield", "退出 HDR Shield"),
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
                "Move HDR Shield.app to the Applications folder and try again.",
                "请先把 HDR Shield.app 移到「应用程序」文件夹再试。")
                + "\n\n\(error.localizedDescription)"
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}
