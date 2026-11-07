import SwiftUI

/// Main button that closes a result screen.
public struct DoneButton: View {
    private let theme: FeatureTheme
    private let action: () -> Void

    public init(theme: FeatureTheme, action: @escaping () -> Void) {
        self.theme = theme
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text("Done", bundle: .module, comment: "Button that closes a result screen.")
        }
        .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
        .keyboardShortcut(.defaultAction)
    }
}
