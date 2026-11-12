import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?

    /// Master switch. / 总开关。
    private var shieldOn = true
    /// Connected displays, built-in first. / 已连接的显示器，内建屏幕在前。
    private var displays: [DisplayInfo] = []
    /// Per-display choices, by `DisplayInfo.key`. Displays without a saved choice use the
    /// default: built-in on, external off.
    /// 每台显示器的选择，按 `DisplayInfo.key` 保存。没有保存过的显示器使用默认值：内建开，外接关。
    private var choices: [String: Bool] = [:]
    /// Displays that currently have the clamping table installed.
    /// 当前已套用压制色表的显示器。
    private var shielded: Set<CGDirectDisplayID> = []

    // Parts of the open menu that change while it is open.
    // 菜单打开时会随之变化的部分。
    private var masterSwitch: NSSwitch?
    private var statusMenuItem: NSMenuItem?
    private var offHintMenuItem: NSMenuItem?
    private var displayCheckboxes: [NSButton] = []

    private enum Key {
        static let shieldOn = "shieldOn"
        static let choices = "displayChoices"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(clicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // The system resets gamma tables after wake and display reconfiguration, so reapply them.
        // 睡眠唤醒、屏幕配置变化后系统会重置色表，需要重新套用。
        NotificationCenter.default.addObserver(
            self, selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(reapply),
            name: NSWorkspace.didWakeNotification, object: nil)

        // Restore the last state; shielding is on by default at first launch.
        // 恢复上次的状态；第一次启动默认开启遮光。
        let defaults = UserDefaults.standard
        shieldOn = defaults.object(forKey: Key.shieldOn) as? Bool ?? true
        choices = defaults.dictionary(forKey: Key.choices) as? [String: Bool] ?? [:]
        displays = Displays.current()
        update()
    }

    // MARK: - Shielding / 遮光

    private func isSelected(_ display: DisplayInfo) -> Bool {
        choices[display.key] ?? display.isBuiltin
    }

    /// Displays that should be shielded right now.
    /// 当前应当遮光的显示器。
    private func targetDisplays() -> Set<CGDirectDisplayID> {
        guard shieldOn else { return [] }
        let hdr = displays.filter(\.supportsHDR)
        // With a single display there is no "Apply to" list, so it is always included.
        // 只有一台显示器时没有「应用于」列表，所以它总是被包括在内。
        if displays.count == 1 { return Set(hdr.map(\.id)) }
        return Set(hdr.filter(isSelected).map(\.id))
    }

    /// Applies the current state to the displays and refreshes the icon and menu.
    /// 把当前状态应用到显示器上，并刷新图标和菜单。
    private func update() {
        let targets = targetDisplays()
        if !shielded.isSubset(of: targets) {
            // A display was turned off. Only all displays can be restored, so restore all
            // and reapply to the rest (they may flicker once).
            // 有显示器被关闭了。只能一次恢复所有显示器，所以先全部恢复，再给其余的重新套用（可能会闪一下）。
            Displays.restoreAll()
        }
        Displays.applyClamp(to: targets)
        shielded = targets

        timer?.invalidate()
        timer = nil
        if !targets.isEmpty {
            // Reapply periodically in case something else reset the tables.
            // 定时重新套用，以防色表被其他操作重置。
            timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                self?.reapply()
            }
        }
        updateIcon()
        refreshMenu()
    }

    @objc private func reapply() {
        Displays.applyClamp(to: shielded)
    }

    @objc private func screensChanged() {
        displays = Displays.current()
        update()
    }

    private func setShieldOn(_ on: Bool) {
        shieldOn = on
        UserDefaults.standard.set(on, forKey: Key.shieldOn)
        update()
    }

    @objc private func masterSwitchToggled(_ sender: NSSwitch) {
        setShieldOn(sender.state == .on)
    }

    @objc private func displayToggled(_ sender: NSButton) {
        guard let key = sender.identifier?.rawValue else { return }
        choices[key] = sender.state == .on
        UserDefaults.standard.set(choices, forKey: Key.choices)
        update()
    }

    // MARK: - Menu bar icon / 菜单栏图标

    private var statusText: String {
        let hdrCount = displays.filter(\.supportsHDR).count
        if hdrCount == 0 { return Strings.statusNoHDR }
        guard shieldOn else { return Strings.statusOff }
        if hdrCount > 1 { return Strings.statusOnCount(shielding: shielded.count, of: hdrCount) }
        return Strings.statusOn
    }

    private func updateIcon() {
        // Filled sunglasses = shielding at least one display, outline sunglasses = not shielding.
        // Bundled PDFs rather than system symbols, because "sunglasses" needs macOS 14.
        // 实心墨镜 = 至少有一台显示器在遮光，空心墨镜 = 没有遮光。
        // 使用打包的 PDF 而不是系统符号，因为「sunglasses」符号需要 macOS 14。
        let image = MenuBarIcon.image(filled: !shielded.isEmpty)
        image?.accessibilityDescription = statusText
        statusItem.button?.image = image
        statusItem.button?.toolTip = shieldOn
            ? Strings.tooltipOn(status: statusText)
            : Strings.tooltipOff(status: statusText)
    }

    /// Left-click opens the menu; right-click (or Control-click) turns shielding on or off.
    /// 左键打开菜单；右键（或 Control+点击）开关遮光。
    @objc private func clicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            setShieldOn(!shieldOn)
        } else {
            showMenu()
        }
    }

    // MARK: - Menu / 菜单

    private func showMenu() {
        let menu = NSMenu()

        // Master switch and status.
        // 总开关和状态。
        let masterRow = SwitchMenuRow(title: "HDR Shield", isOn: shieldOn,
                                      target: self, action: #selector(masterSwitchToggled(_:)))
        let masterItem = NSMenuItem()
        masterItem.view = masterRow
        menu.addItem(masterItem)
        masterSwitch = masterRow.toggle

        let status = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        statusMenuItem = status

        // Per-display choices, only with more than one display.
        // 每台显示器的选择，只在有多台显示器时显示。
        if displays.count > 1 {
            menu.addItem(.separator())
            let header = NSMenuItem(title: Strings.applyTo, action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for display in displays {
                let title = display.supportsHDR ? display.name : Strings.sdrDisplay(name: display.name)
                let row = CheckboxMenuRow(
                    title: title,
                    isOn: display.supportsHDR && isSelected(display),
                    isEnabled: display.supportsHDR,
                    target: self, action: #selector(displayToggled(_:)))
                row.checkbox.identifier = NSUserInterfaceItemIdentifier(display.key)
                let item = NSMenuItem()
                item.view = row
                menu.addItem(item)
                displayCheckboxes.append(row.checkbox)
            }

            let hint = NSMenuItem(title: Strings.offHint, action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
            offHintMenuItem = hint
        }

        menu.addItem(.separator())

        let login = NSMenuItem(title: Strings.launchAtLogin,
                               action: #selector(toggleLoginItem), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        let quit = NSMenuItem(title: Strings.quit,
                              action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        menu.addItem(quit)

        refreshMenu()

        // Attach the menu only while it is shown, so a right-click can still toggle directly.
        // performClick returns once the menu closes.
        // 只在弹出时临时挂上菜单，这样右键仍然可以直接切换。performClick 会在菜单关闭后返回。
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil

        masterSwitch = nil
        statusMenuItem = nil
        offHintMenuItem = nil
        displayCheckboxes = []
    }

    /// Updates the open menu after a change.
    /// 状态变化后更新已打开的菜单。
    private func refreshMenu() {
        masterSwitch?.state = shieldOn ? .on : .off
        statusMenuItem?.title = statusText
        offHintMenuItem?.isHidden = shieldOn
        // When the master switch is off, display choices stay editable but are dimmed.
        // 总开关关闭时，显示器选项仍可修改，但会变暗。
        for checkbox in displayCheckboxes where checkbox.isEnabled {
            checkbox.alphaValue = shieldOn ? 1 : 0.5
        }
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
