/// Opens System Settings where the user grants a permission.
public protocol PermissionSettingsOpening: Sendable {
    func open(_ pane: PermissionSettingsPane)
}
