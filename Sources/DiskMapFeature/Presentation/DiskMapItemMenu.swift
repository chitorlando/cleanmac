import CleanMacUI

/// What the context menu of an item of the disk map offers.
///
/// First what the map itself does with the item: opening it, when it's a folder with something
/// inside, and selecting it, when it can be moved to the Trash. Then what the other features
/// of the app offer for an item of its kind, and last what works on any item.
///
/// The map doesn't know which features those are. It only decides the kind of the item: a
/// folder it can open is a folder to look into, and an item it leaves to the Uninstaller is an
/// app. Other items, such as files or the app data in `~/Library`, are handed to no feature.
struct DiskMapItemMenu: Equatable, Sendable {
    /// The commands in the order the menu lists them, in the groups it keeps apart. No group is empty.
    let sections: [[DiskMapItemCommand]]

    /// - Parameters:
    ///   - advice: What the map lets the user do with the item.
    ///   - canOpen: Whether the item is a folder the map can open.
    ///   - isSelected: Whether the item is marked to be moved to the Trash.
    ///   - featureActions: What the features of the app offer for items of every kind.
    init(advice: RemovalAdvice, canOpen: Bool, isSelected: Bool, featureActions: [FeatureItemAction]) {
        var own: [DiskMapItemCommand] = []
        if canOpen {
            own.append(.open)
        }
        if advice.allowsMovingToTrash {
            own.append(isSelected ? .deselect : .select)
        }
        let itemKind = Self.itemKind(advice: advice, canOpen: canOpen)
        let offered = featureActions
            .filter { $0.itemKind == itemKind }
            .map(DiskMapItemCommand.feature)
        sections = [own, offered, [.showInFinder, .copyPath]].filter { !$0.isEmpty }
    }

    /// The kind of item the other features get, or `nil` for an item the map hands to none.
    private static func itemKind(advice: RemovalAdvice, canOpen: Bool) -> FeatureItemKind? {
        if canOpen {
            return .folder
        }
        return advice == .useUninstaller ? .app : nil
    }
}
