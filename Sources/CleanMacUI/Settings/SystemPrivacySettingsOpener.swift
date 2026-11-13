import AppKit

/// `PrivacySettingsOpening` with the System Settings deep links. Opening a pane never asks
/// for anything: the user grants access there by hand.
public struct SystemPrivacySettingsOpener: PrivacySettingsOpening {
    static let fullDiskAccessURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!

    public init() {}

    @MainActor
    public func openFullDiskAccess() {
        NSWorkspace.shared.open(Self.fullDiskAccessURL)
    }
}
