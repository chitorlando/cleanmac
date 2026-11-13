import CleanMacUI

/// Something the user can do with an item of the disk map, from its row or its context menu.
enum DiskMapItemCommand: Equatable, Identifiable, Sendable {
    /// Opens the folder in the map.
    case open
    /// Marks the item to be moved to the Trash.
    case select
    /// Takes the mark off the item.
    case deselect
    /// Hands the item to another feature of the app, which carries out the action.
    case feature(FeatureItemAction)
    case showInFinder
    /// Copies the item's path to the clipboard.
    case copyPath

    var id: String {
        switch self {
        case .open: "open"
        case .select: "select"
        case .deselect: "deselect"
        case .feature(let action): "feature.\(action.id)"
        case .showInFinder: "show-in-finder"
        case .copyPath: "copy-path"
        }
    }
}
