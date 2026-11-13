import SwiftUI

private struct FileActionsKey: EnvironmentKey {
    static let defaultValue: any FileActionPerforming = WorkspaceFileActions()
}

public extension EnvironmentValues {
    /// Carries out the file actions of the item context menus. Previews can replace it.
    var fileActions: any FileActionPerforming {
        get { self[FileActionsKey.self] }
        set { self[FileActionsKey.self] = newValue }
    }
}
