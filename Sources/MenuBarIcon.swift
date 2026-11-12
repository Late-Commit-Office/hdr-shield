import AppKit

/// The menu bar icon: sunglasses, outlined when nothing is shielded and filled when shielding.
///
/// Public-domain (CC0) sunglasses drawings, bundled as vector PDFs (Resources/MenuBarOff.pdf,
/// MenuBarOn.pdf). Bundled because the system "sunglasses" symbol only exists on macOS 14 and
/// later. The SVG sources sit next to the PDFs. They are template images, so macOS colours them
/// for light and dark menu bars.
///
/// 菜单栏图标：墨镜，没有遮光时为空心，遮光时为实心。
/// 公有领域（CC0）的墨镜图形，以矢量 PDF（Resources/MenuBarOff.pdf、MenuBarOn.pdf）
/// 的形式打包。之所以自带图形，是因为系统的「sunglasses」符号只在 macOS 14 及以上版本才有。
/// SVG 源文件放在 PDF 旁边。它们是模板图像，macOS 会按浅色、深色菜单栏自动着色。
enum MenuBarIcon {
    /// Width of the icon in the menu bar, in points; the height follows the shape.
    /// 图标在菜单栏中的宽度（点）；高度按比例计算。
    private static let width: CGFloat = 20

    static func image(filled: Bool) -> NSImage? {
        guard let image = Bundle.main.image(forResource: filled ? "MenuBarOn" : "MenuBarOff") else {
            return nil
        }
        let natural = image.size
        if natural.width > 0 {
            image.size = NSSize(width: width, height: width * natural.height / natural.width)
        }
        image.isTemplate = true
        return image
    }
}
