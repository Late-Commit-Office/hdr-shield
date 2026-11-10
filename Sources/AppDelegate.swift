import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var clamped = false

    private static let clampedKey = "clamped"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // The system resets the gamma table after wake and display reconfiguration, so reapply it.
        // 睡眠唤醒、屏幕配置变化后系统会重置色表，需要重新套用。
        NotificationCenter.default.addObserver(
            self, selector: #selector(reapply),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(reapply),
            name: NSWorkspace.didWakeNotification, object: nil)

        // Restore the last state; clamping is on by default at first launch.
        // 恢复上次的状态；第一次启动默认开启压制。
        let saved = UserDefaults.standard.object(forKey: Self.clampedKey) as? Bool ?? true
        setClamped(saved)
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
            // 定时重新套用，以防色表被其他操作重置。
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
        clamped ? Strings.statusOn : Strings.statusOff
    }

    private func updateIcon() {
        // Filled sunglasses = shielding, outline sunglasses = normal.
        // 实心墨镜 = 遮光中，空心墨镜 = 正常。
        let symbol = clamped ? "sunglasses.fill" : "sunglasses"
        statusItem.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: statusText)
        statusItem.button?.toolTip = Strings.tooltip(status: statusText)
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

        let login = NSMenuItem(title: Strings.launchAtLogin,
                               action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        let quit = NSMenuItem(title: Strings.quit,
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quit)

        // Attach the menu only while it is shown, so a left-click still toggles directly.
        // 只在弹出时临时挂上菜单，这样左键仍然可以直接切换。
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
            alert.messageText = Strings.loginItemErrorTitle
            alert.informativeText = Strings.loginItemErrorMessage
                + "\n\n\(error.localizedDescription)"
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}
