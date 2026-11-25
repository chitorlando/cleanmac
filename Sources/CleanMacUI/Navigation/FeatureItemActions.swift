import Foundation

/// What the features of the app offer to do with items shown by other features, and which
/// items each of them takes. See `FeatureItemAction`.
///
/// A view that shows an item asks it for the actions to offer on that item, for instance when
/// its context menu opens. A feature can turn down an item of the right kind, such as a folder
/// its scan would never look in, and its action is then left out rather than doing nothing.
/// The app shell provides the actions as the `featureItemActions` environment value.
public struct FeatureItemActions: Sendable {
    private let actions: [FeatureItemAction]
    private let canPerform: @MainActor @Sendable (FeatureItemAction, URL) -> Bool

    /// - Parameters:
    ///   - actions: What the features offer, for items of every kind, in the order to list them.
    ///   - canPerform: Whether the feature of an action would carry it out on the item at a URL.
    public init(
        _ actions: [FeatureItemAction],
        canPerform: @escaping @MainActor @Sendable (FeatureItemAction, URL) -> Bool
    ) {
        self.actions = actions
        self.canPerform = canPerform
    }

    /// Offers nothing, for views shown outside the app shell.
    public static let none = FeatureItemActions([]) { _, _ in false }

    /// The actions for an item of `kind` at `url` that their features would carry out, in order.
    ///
    /// Only the features that offer an action for `kind` are asked about the item, which may
    /// mean looking at the disk: ask when the actions are about to be shown.
    @MainActor
    public func offered(for kind: FeatureItemKind, at url: URL) -> [FeatureItemAction] {
        actions.filter { $0.itemKind == kind && canPerform($0, url) }
    }
}
