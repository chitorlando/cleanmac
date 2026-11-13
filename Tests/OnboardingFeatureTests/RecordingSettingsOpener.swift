import CleanMacCore

/// Remembers which panes it was asked to open instead of opening System Settings.
final class RecordingSettingsOpener: PermissionSettingsOpening, @unchecked Sendable {
    private(set) var opened: [PermissionSettingsPane] = []

    func open(_ pane: PermissionSettingsPane) {
        opened.append(pane)
    }
}
