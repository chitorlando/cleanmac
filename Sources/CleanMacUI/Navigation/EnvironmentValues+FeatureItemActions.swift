import SwiftUI

private struct FeatureItemActionsKey: EnvironmentKey {
    static let defaultValue = FeatureItemActions.none
}

public extension EnvironmentValues {
    /// What the features of the app offer to do with items shown by other features, and which
    /// items they take. See `FeatureItemActions`. Offers nothing outside the app shell, such as
    /// in previews.
    var featureItemActions: FeatureItemActions {
        get { self[FeatureItemActionsKey.self] }
        set { self[FeatureItemActionsKey.self] = newValue }
    }
}
