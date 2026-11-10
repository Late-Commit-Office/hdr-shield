import Foundation

/// User-facing strings, looked up in Resources/<lang>.lproj/Localizable.strings.
/// macOS picks the language from the user's preferred languages (including the per-app
/// setting in System Settings → General → Language & Region) and falls back to English.
/// To add a string: add a key here and to every Localizable.strings file.
///
/// 界面文字，从 Resources/<lang>.lproj/Localizable.strings 里按键查找。
/// macOS 会根据用户的首选语言（包括「系统设置 → 通用 → 语言与地区」里针对单个 app 的设置）
/// 选择语言，找不到时回退到英文。新增文字：在这里加一个键，并在每个 Localizable.strings 里加上它。
enum Strings {
    private static func tr(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    // Status / 状态
    static var statusOn: String { tr("status.on") }
    static var statusOff: String { tr("status.off") }
    static var statusNoHDR: String { tr("status.noHDR") }
    static func statusOnCount(shielding count: Int, of total: Int) -> String {
        String(format: tr("status.on.count"), count, total)
    }

    // Tooltip of the menu bar icon; `status` is one of the status lines.
    // 菜单栏图标的提示文字；`status` 是上面的某一条状态。
    static func tooltipOn(status: String) -> String { String(format: tr("tooltip.on"), status) }
    static func tooltipOff(status: String) -> String { String(format: tr("tooltip.off"), status) }

    // Displays / 显示器
    static var applyTo: String { tr("menu.applyTo") }
    static var offHint: String { tr("menu.offHint") }
    static func sdrDisplay(name: String) -> String { String(format: tr("menu.sdrDisplay"), name) }

    // Menu items / 菜单项
    static var launchAtLogin: String { tr("menu.launchAtLogin") }
    static var quit: String { tr("menu.quit") }

    // Login item alert / 登录项提示
    static var loginItemErrorTitle: String { tr("loginItem.error.title") }
    static var loginItemErrorMessage: String { tr("loginItem.error.message") }
}
