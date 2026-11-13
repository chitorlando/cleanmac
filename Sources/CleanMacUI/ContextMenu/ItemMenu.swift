import Foundation

/// What the context menu of an item row offers, in the groups it keeps apart.
///
/// First what the row itself does with the item: opening it, when that makes sense, and
/// selecting it, when it can be selected. Then what the other features of the app offer for
/// an item of its kind, and last what works on any item. The disk map's menu keeps the same groups.
public struct ItemMenu: Equatable, Sendable {
    /// The entries in the order the menu lists them. No group is empty.
    public let sections: [[ItemMenuAction]]

    /// - Parameters:
    ///   - url: The item. Apps are never offered “Open”, which would launch them.
    ///   - isFolder: Whether the item is a folder, which decides what other features get.
    ///   - canOpen: `false` when opening the item makes no sense or the feature does it its own way.
    ///   - selection: Whether to offer Select or Deselect.
    ///   - featureActions: What the features of the app offer, for items of every kind.
    public init(
        url: URL,
        isFolder: Bool = false,
        canOpen: Bool = true,
        selection: ItemMenuSelection,
        featureActions: [FeatureItemAction]
    ) {
        let target = FeatureItemTarget(itemAt: url, isFolder: isFolder)
        var own: [ItemMenuAction] = []
        if canOpen, target.kind != .app {
            own.append(.open)
        }
        switch selection {
        case .unavailable: break
        case .selected: own.append(.deselect)
        case .deselected: own.append(.select)
        }
        let offered = featureActions
            .filter { $0.itemKind == target.kind }
            .map { ItemMenuAction.feature($0, target: target.url) }
        sections = [own, offered, [.showInFinder, .copyPath]].filter { !$0.isEmpty }
    }
}
