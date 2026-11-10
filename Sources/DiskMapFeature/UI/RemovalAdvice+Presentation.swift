import SwiftUI

extension RemovalAdvice {
    /// Short note under the item's name, or `nil` when it can be moved to the Trash.
    var note: Text? {
        switch self {
        case .allowed:
            nil
        case .standardFolder:
            Text("System folder", bundle: .module, comment: "Note on a standard folder, such as Documents, that the disk map won't remove.")
        case .appData:
            Text("Used by apps", bundle: .module, comment: "Note on app data in Library that the disk map only shows.")
        case .protectedData:
            Text("Protected", bundle: .module, comment: "Note on data the disk map never removes, such as mail or keychains.")
        case .useUninstaller:
            Text("Remove it with the Uninstaller", bundle: .module, comment: "Note on an app in the disk map, pointing to the Uninstaller feature.")
        }
    }

    /// Why the item can't be selected, shown as its checkbox's tooltip.
    var explanation: Text? {
        switch self {
        case .allowed:
            nil
        case .standardFolder:
            Text("macOS expects this folder. You can remove what’s inside it.", bundle: .module, comment: "Tooltip on a standard folder that can't be selected in the disk map.")
        case .appData:
            Text("Apps keep their data here. Removing it could break them, so the map only shows it.", bundle: .module, comment: "Tooltip on app data in Library that can't be selected in the disk map.")
        case .protectedData:
            Text("This holds data that can’t be recovered once removed, such as passwords, mail, photos or iCloud files.", bundle: .module, comment: "Tooltip on protected data that can't be selected in the disk map.")
        case .useUninstaller:
            Text("Use the Uninstaller to remove this app together with the files it leaves behind.", bundle: .module, comment: "Tooltip on an app that can't be selected in the disk map.")
        }
    }
}
