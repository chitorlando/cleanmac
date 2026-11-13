import SwiftUI

extension ItemMenuAction {
    /// Name of the entry. The action of another feature brings its own name, already localized.
    var title: Text {
        switch self {
        case .open:
            Text("Open", bundle: .module, comment: "Context menu item that opens a file with its app, or a folder in Finder.")
        case .select:
            Text("Select", bundle: .module, comment: "Context menu item that marks an item for removal.")
        case .deselect:
            Text("Deselect", bundle: .module, comment: "Context menu item that unmarks an item.")
        case .feature(let action, _):
            Text(verbatim: action.title)
        case .showInFinder:
            Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals an item in Finder.")
        case .copyPath:
            Text("Copy Path", bundle: .module, comment: "Context menu item that copies an item’s full path.")
        }
    }

    var symbolName: String {
        switch self {
        case .open: "arrow.up.forward.app"
        case .select: "checkmark.circle"
        case .deselect: "circle"
        case .feature(let action, _): action.symbolName
        case .showInFinder: "magnifyingglass"
        case .copyPath: "doc.on.doc"
        }
    }
}
