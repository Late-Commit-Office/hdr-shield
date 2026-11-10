import AppKit

// Custom menu rows. Unlike normal menu items, clicking the controls in them doesn't close
// the menu, so several displays can be ticked in one go.
// 自定义菜单行。和普通菜单项不同，点击其中的控件不会关闭菜单，可以一次勾选多台显示器。

/// Layout of the custom rows. Adjust these if they don't line up with the normal menu items.
/// 自定义菜单行的布局。如果和普通菜单项没对齐，调整这里的数值。
private enum RowLayout {
    static let minWidth: CGFloat = 260
    static let leading: CGFloat = 14
    static let trailing: CGFloat = 14
    static let switchRowPadding: CGFloat = 10
    static let checkboxRowPadding: CGFloat = 6
}

/// A row with a bold title and an on/off switch, like the toggles in Control Center.
/// 一行加粗的标题和一个开关，类似控制中心里的开关。
final class SwitchMenuRow: NSView {
    let toggle: NSSwitch

    init(title: String, isOn: Bool, target: AnyObject, action: Selector) {
        let label = NSTextField(labelWithString: title)
        label.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        label.sizeToFit()

        let toggle = NSSwitch()
        toggle.controlSize = .small
        toggle.state = isOn ? .on : .off
        toggle.target = target
        toggle.action = action
        toggle.setFrameSize(toggle.intrinsicContentSize)
        self.toggle = toggle

        let width = max(RowLayout.minWidth,
                        RowLayout.leading + label.frame.width + 20 + toggle.frame.width + RowLayout.trailing)
        let height = max(label.frame.height, toggle.frame.height) + RowLayout.switchRowPadding
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        autoresizingMask = [.width]

        label.setFrameOrigin(NSPoint(x: RowLayout.leading, y: (height - label.frame.height) / 2))
        toggle.setFrameOrigin(NSPoint(x: width - RowLayout.trailing - toggle.frame.width,
                                      y: (height - toggle.frame.height) / 2))
        toggle.autoresizingMask = [.minXMargin]
        addSubview(label)
        addSubview(toggle)
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}

/// A row with a checkbox, used for each display under "Apply to:".
/// 一行复选框，用于「应用于：」下面的每台显示器。
final class CheckboxMenuRow: NSView {
    let checkbox: NSButton

    init(title: String, isOn: Bool, isEnabled: Bool, target: AnyObject, action: Selector) {
        let checkbox = NSButton(checkboxWithTitle: title, target: target, action: action)
        checkbox.font = NSFont.menuFont(ofSize: 0)
        checkbox.state = isOn ? .on : .off
        checkbox.isEnabled = isEnabled
        checkbox.sizeToFit()
        self.checkbox = checkbox

        let width = max(RowLayout.minWidth, RowLayout.leading + checkbox.frame.width + RowLayout.trailing)
        let height = checkbox.frame.height + RowLayout.checkboxRowPadding
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        autoresizingMask = [.width]

        checkbox.setFrameOrigin(NSPoint(x: RowLayout.leading, y: (height - checkbox.frame.height) / 2))
        addSubview(checkbox)
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}
