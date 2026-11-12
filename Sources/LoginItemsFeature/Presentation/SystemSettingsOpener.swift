import AppKit

/// Opens System Settings › General › Login Items.
public struct SystemSettingsOpener: LoginItemsSettingsOpening {
    static let loginItemsURL = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")

    public init() {}

    public func openLoginItemsSettings() {
        guard let url = Self.loginItemsURL else { return }
        NSWorkspace.shared.open(url)
    }
}
