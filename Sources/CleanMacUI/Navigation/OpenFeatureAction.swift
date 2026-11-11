import Foundation

/// Asks the app to show another feature, given its id, and optionally an item in it.
///
/// Features read it from the environment as `openFeature` and call it like a function,
/// such as `openFeature("uninstaller", showing: appURL)`. The app shell provides it; elsewhere,
/// such as in previews, it does nothing. Ids that match no feature are ignored.
public struct OpenFeatureAction: Sendable {
    private let handler: @MainActor @Sendable (String, URL?) -> Void

    /// - Parameter handler: Receives the feature's id and the item to show in it, if any.
    public init(_ handler: @escaping @MainActor @Sendable (String, URL?) -> Void) {
        self.handler = handler
    }

    /// Does nothing, for views shown outside the app shell.
    public static let none = OpenFeatureAction { _, _ in }

    @MainActor
    public func callAsFunction(_ featureID: String) {
        handler(featureID, nil)
    }

    /// Opens the feature and asks it to show the item at `itemURL`. See `FeatureModule.show(itemAt:)`.
    @MainActor
    public func callAsFunction(_ featureID: String, showing itemURL: URL) {
        handler(featureID, itemURL)
    }
}
