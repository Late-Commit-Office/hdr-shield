import AppKit
import ColorSync
import CoreGraphics

/// Upper bound of the gamma table. If a 1:1 table (1.0) has no effect on your Mac, try 0.98.
/// 色表上限。如果 1:1 的色表（1.0）在你的 Mac 上不起作用，改成 0.98 试试。
let clampLevel: Float = 1.0

/// A connected display.
/// 一台已连接的显示器。
struct DisplayInfo {
    /// Changes between reboots and reconnects; use `key` to remember a display.
    /// 重启或重新连接后可能会变；要记住某台显示器请用 `key`。
    let id: CGDirectDisplayID
    /// Stable identifier, used to save per-display choices.
    /// 稳定的标识，用于保存每台显示器的选择。
    let key: String
    let name: String
    let isBuiltin: Bool
    /// External HDR displays only count when HDR is turned on for them in System Settings.
    /// 外接 HDR 显示器只有在系统设置里开启了 HDR 才算。
    let supportsHDR: Bool
}

/// Finds displays and installs or removes the clamping gamma table.
/// 查找显示器，套用和移除压制用的色表。
enum Displays {
    private static let table: [CGGammaValue] = (0..<256).map { Float($0) / 255 * clampLevel }

    /// Connected displays, built-in first. Mirrored copies are not listed separately.
    /// 已连接的显示器，内建屏幕在前。镜像显示不会单独列出。
    static func current() -> [DisplayInfo] {
        let screens: [DisplayInfo] = NSScreen.screens.compactMap { screen in
            let numberKey = NSDeviceDescriptionKey("NSScreenNumber")
            guard let number = screen.deviceDescription[numberKey] as? NSNumber else { return nil }
            let id = CGDirectDisplayID(number.uint32Value)
            return DisplayInfo(
                id: id,
                key: stableKey(for: id),
                name: screen.localizedName,
                isBuiltin: CGDisplayIsBuiltin(id) != 0,
                supportsHDR: screen.maximumPotentialExtendedDynamicRangeColorComponentValue > 1)
        }
        return screens.filter(\.isBuiltin) + screens.filter { !$0.isBuiltin }
    }

    /// Installs the clamping table on the given displays.
    /// 给指定的显示器套用压制色表。
    static func applyClamp(to ids: Set<CGDirectDisplayID>) {
        for id in ids {
            CGSetDisplayTransferByTable(id, 256, table, table, table)
        }
    }

    /// Restores the default gamma tables on all displays. There is no public API to restore
    /// a single display.
    /// 恢复所有显示器的默认色表。没有公开 API 可以只恢复单台显示器。
    static func restoreAll() {
        CGDisplayRestoreColorSyncSettings()
    }

    /// The display's UUID, or vendor/model/serial numbers if there is none.
    /// 显示器的 UUID；没有的话用厂商、型号、序列号代替。
    private static func stableKey(for id: CGDirectDisplayID) -> String {
        if let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue(),
           let string = CFUUIDCreateString(nil, uuid) {
            return string as String
        }
        return "\(CGDisplayVendorNumber(id))-\(CGDisplayModelNumber(id))-\(CGDisplaySerialNumber(id))"
    }
}
