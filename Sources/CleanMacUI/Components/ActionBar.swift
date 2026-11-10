import SwiftUI

/// Bottom bar with the main action on the right and, optionally, a quiet secondary action on the left.
public struct ActionBar: View {
    private let secondaryTitle: Text?
    private let primaryTitle: Text
    private let isPrimaryEnabled: Bool
    private let theme: FeatureTheme
    private let onSecondary: (() -> Void)?
    private let onPrimary: () -> Void

    /// - Parameters:
    ///   - secondaryTitle: Title of the quiet action on the left, such as “Scan Again”.
    ///     Without it, or without `onSecondary`, the bar shows only the main action.
    ///   - onSecondary: What the secondary action does.
    public init(
        secondaryTitle: Text? = nil,
        primaryTitle: Text,
        isPrimaryEnabled: Bool = true,
        theme: FeatureTheme,
        onSecondary: (() -> Void)? = nil,
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
            secondaryButton

            Spacer()

            Button(action: onPrimary) {
                primaryTitle
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .disabled(!isPrimaryEnabled)
            .keyboardShortcut(.defaultAction)
        }
    }

    @ViewBuilder
    private var secondaryButton: some View {
        if let secondaryTitle, let onSecondary {
            Button(action: onSecondary) {
                secondaryTitle
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Palette.secondaryText)
        }
    }
}
