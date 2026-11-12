import SwiftUI

extension ItemMenuAction {
    var title: Text {
        switch self {
        case .showInFinder:
            Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals an item in Finder.")
        case .open:
            Text("Open", bundle: .module, comment: "Context menu item that opens a file with its app, or a folder in Finder.")
        case .copyPath:
            Text("Copy Path", bundle: .module, comment: "Context menu item that copies an item’s full path.")
        case .select:
            Text("Select", bundle: .module, comment: "Context menu item that marks an item for removal.")
        case .deselect:
            Text("Deselect", bundle: .module, comment: "Context menu item that unmarks an item.")
        }
    }
}
