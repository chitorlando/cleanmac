import AppKit

/// `PermissionSettingsOpening` that opens System Settings through its links.
public struct SystemSettingsOpener: PermissionSettingsOpening {
    public init() {}

    public func open(_ pane: PermissionSettingsPane) {
        NSWorkspace.shared.open(pane.url)
    }
}
