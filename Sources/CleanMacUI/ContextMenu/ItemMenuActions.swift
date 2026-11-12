import Foundation

/// Chooses the common actions of an item's context menu, in the order they're shown.
public enum ItemMenuActions {
    /// Show in Finder, Open, Copy Path and Select or Deselect, as the item allows.
    ///
    /// - Parameters:
    ///   - url: The item. Apps are never offered “Open”, which would launch them.
    ///   - canOpen: `false` when the feature opens the item its own way, such as a folder
    ///     of the disk map, or opening it makes no sense.
    ///   - selection: Whether to offer Select or Deselect.
    public static func standard(for url: URL, canOpen: Bool = true, selection: ItemMenuSelection) -> [ItemMenuAction] {
        var actions: [ItemMenuAction] = [.showInFinder]
        if canOpen, !isApp(url) {
            actions.append(.open)
        }
        actions.append(.copyPath)
        switch selection {
        case .unavailable: break
        case .selected: actions.append(.deselect)
        case .deselected: actions.append(.select)
        }
        return actions
    }

    private static func isApp(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == "app"
    }
}
