import CleanMacUI
import SwiftUI

extension DiskMapItemCommand {
    /// Name of the command, as an entry of the context menu and as the tooltip of its button.
    /// The action of another feature brings its own name, already localized.
    var title: Text {
        switch self {
        case .open:
            Text("Open", bundle: .module, comment: "Opens a folder in the disk map. Tooltip of a button and entry of the context menu of an item.")
        case .select:
            Text("Select", bundle: .module, comment: "Entry of the context menu of a disk map item that marks it to be moved to the Trash.")
        case .deselect:
            Text("Deselect", bundle: .module, comment: "Entry of the context menu of a disk map item that takes back its mark to be moved to the Trash.")
        case .feature(let action):
            Text(verbatim: action.title)
        case .showInFinder:
            Text("Show in Finder", bundle: .module, comment: "Reveals an item of the disk map in Finder. Tooltip of a button and entry of the context menu of an item.")
        case .copyPath:
            Text("Copy Path", bundle: .module, comment: "Entry of the context menu of a disk map item that copies its path to the clipboard.")
        }
    }

    var symbolName: String {
        switch self {
        case .open: "chevron.right"
        case .select: "checkmark.circle"
        case .deselect: "circle"
        case .feature(let action): action.symbolName
        case .showInFinder: "magnifyingglass"
        case .copyPath: "doc.on.doc"
        }
    }
}
