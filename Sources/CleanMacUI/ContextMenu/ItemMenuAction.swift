/// A common action of an item's context menu. None of them removes anything:
/// removing still goes through the selection and the feature's action bar.
public enum ItemMenuAction: Hashable, Sendable {
    case showInFinder
    /// Opens the item with its default app, or a folder in Finder.
    case open
    case copyPath
    case select
    case deselect
}
