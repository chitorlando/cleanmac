import SwiftUI

private struct OpenFeatureKey: EnvironmentKey {
    static let defaultValue = OpenFeatureAction.none
}

public extension EnvironmentValues {
    /// Shows another feature of the app. See `OpenFeatureAction`.
    var openFeature: OpenFeatureAction {
        get { self[OpenFeatureKey.self] }
        set { self[OpenFeatureKey.self] = newValue }
    }
}
