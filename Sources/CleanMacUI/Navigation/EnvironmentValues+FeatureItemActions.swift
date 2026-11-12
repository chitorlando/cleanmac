import SwiftUI

private struct FeatureItemActionsKey: EnvironmentKey {
    static let defaultValue: [FeatureItemAction] = []
}

public extension EnvironmentValues {
    /// What the features of the app offer to do with items shown by other features.
    /// See `FeatureItemAction`. Empty outside the app shell, such as in previews.
    var featureItemActions: [FeatureItemAction] {
        get { self[FeatureItemActionsKey.self] }
        set { self[FeatureItemActionsKey.self] = newValue }
    }
}
