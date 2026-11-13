/// Something a feature offers to do with an item that another feature shows, such as looking
/// for duplicates in a folder of the disk map.
///
/// A feature lists its actions in `FeatureModule.itemActions`. The app shell hands the actions
/// of every feature to the views as the `featureItemActions` environment value, and a view
/// that shows items offers the ones for their kind, for instance in a context menu. Choosing
/// one opens the feature with the item, `openFeature(action.featureID, showing: itemURL)`,
/// which reaches `FeatureModule.show(itemAt:)`.
///
/// A feature offers at most one action for each kind of item.
public struct FeatureItemAction: Identifiable, Equatable, Sendable {
    /// Id of the feature that carries out the action.
    public let featureID: String
    /// Kind of item the action applies to.
    public let itemKind: FeatureItemKind
    /// Localized name of the action, as a menu shows it.
    public let title: String
    public let symbolName: String

    public init(featureID: String, itemKind: FeatureItemKind, title: String, symbolName: String) {
        self.featureID = featureID
        self.itemKind = itemKind
        self.title = title
        self.symbolName = symbolName
    }

    public var id: String { "\(featureID).\(itemKind)" }
}
