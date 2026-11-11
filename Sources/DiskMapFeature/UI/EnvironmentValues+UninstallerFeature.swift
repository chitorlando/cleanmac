import SwiftUI

private struct UninstallerFeatureIDKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// Id of the feature that uninstalls apps, which the disk map opens for the apps it
    /// won't remove itself. `nil` when the app has no such feature.
    var uninstallerFeatureID: String? {
        get { self[UninstallerFeatureIDKey.self] }
        set { self[UninstallerFeatureIDKey.self] = newValue }
    }
}
