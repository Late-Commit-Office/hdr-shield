import CoreGraphics

/// Upper bound of the gamma table. If a 1:1 table (1.0) has no effect on your Mac, try 0.98.
/// 色表上限。如果 1:1 的色表(1.0)在你的 Mac 上不起作用,改成 0.98 试试。
let clampLevel: Float = 1.0

/// Installs and removes the clamping gamma table.
/// 负责套用和移除压制用的色表。
enum Displays {
    private static let table: [CGGammaValue] = (0..<256).map { Float($0) / 255 * clampLevel }

    /// Installs the clamping table on the built-in display.
    /// 给内建显示器套用压制色表。
    static func applyClamp() {
        guard let display = builtinDisplay() else { return }
        CGSetDisplayTransferByTable(display, 256, table, table, table)
    }

    /// Restores the default gamma tables (for all displays).
    /// 恢复默认色表(对所有显示器生效)。
    static func restoreAll() {
        CGDisplayRestoreColorSyncSettings()
    }

    /// Finds the built-in display; external displays are left untouched.
    /// 查找内建显示器;外接显示器不受影响。
    static func builtinDisplay() -> CGDirectDisplayID? {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        CGGetOnlineDisplayList(16, &ids, &count)
        return ids.prefix(Int(count)).first { CGDisplayIsBuiltin($0) != 0 }
    }
}
