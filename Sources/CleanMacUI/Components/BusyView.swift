import SwiftUI

/// Spinning ring in the feature's colors with a status message, shown while a long action runs.
///
/// With Reduce Motion on, the ring stands still.
public struct BusyView: View {
    private let message: Text
    private let theme: FeatureTheme

    public init(message: Text, theme: FeatureTheme) {
        self.message = message
        self.theme = theme
    }

    /// Busy state for moving items to the Trash.
    public init(theme: FeatureTheme) {
        self.init(
            message: Text("Moving to the Trash…", bundle: .module, comment: "Status shown while items are moved to the Trash."),
            theme: theme
        )
    }

    public var body: some View {
        VStack(spacing: 28) {
            BusyRing(theme: theme)
            message
                .font(.title3.weight(.medium))
        }
    }
}
