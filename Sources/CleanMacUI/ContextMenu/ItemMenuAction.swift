import Foundation

/// An entry of an item's context menu. None of them removes anything: removing still goes
/// through the selection and the feature's action bar.
public enum ItemMenuAction: Equatable, Identifiable, Sendable {
    /// Opens the item with its default app, or a folder in Finder.
    case open
    case select
    case deselect
    /// Hands `target` to another feature of the app, which carries out the action.
    case feature(FeatureItemAction, target: URL)
    case showInFinder
    case copyPath

    public var id: String {
        switch self {
        case .open: "open"
        case .select: "select"
        case .deselect: "deselect"
        case .feature(let action, _): "feature.\(action.id)"
        case .showInFinder: "show-in-finder"
        case .copyPath: "copy-path"
        }
    }
}
