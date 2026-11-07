import SwiftUI

/// Bottom bar with a quiet secondary action on the left and the main action on the right.
public struct ActionBar: View {
    private let secondaryTitle: Text
    private let primaryTitle: Text
    private let isPrimaryEnabled: Bool
    private let theme: FeatureTheme
    private let onSecondary: () -> Void
    private let onPrimary: () -> Void

    public init(
        secondaryTitle: Text,
        primaryTitle: Text,
        isPrimaryEnabled: Bool = true,
        theme: FeatureTheme,
        onSecondary: @escaping () -> Void,
        onPrimary: @escaping () -> Void
    ) {
        self.secondaryTitle = secondaryTitle
        self.primaryTitle = primaryTitle
        self.isPrimaryEnabled = isPrimaryEnabled
        self.theme = theme
        self.onSecondary = onSecondary
        self.onPrimary = onPrimary
    }

    public var body: some View {
        HStack {
            Button(action: onSecondary) {
                secondaryTitle
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Spacer()

            Button(action: onPrimary) {
                primaryTitle
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .disabled(!isPrimaryEnabled)
            .keyboardShortcut(.defaultAction)
        }
    }
}
