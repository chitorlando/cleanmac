import SwiftUI

/// Bottom bar with the main action on the right and, optionally, a quiet secondary action on the left.
public struct ActionBar: View {
    private let secondaryTitle: Text?
    private let primaryTitle: Text
    private let isPrimaryEnabled: Bool
    private let isPrimaryDefaultAction: Bool
    private let theme: FeatureTheme
    private let onSecondary: (() -> Void)?
    private let onPrimary: () -> Void
    @Environment(\.motionPolicy) private var motion

    /// - Parameters:
    ///   - secondaryTitle: Title of the quiet action on the left, such as “Scan Again”.
    ///     Without it, or without `onSecondary`, the bar shows only the main action.
    ///   - isPrimaryDefaultAction: Whether Return triggers the main button. Turn it off when the
    ///     screen uses Return for something else, such as opening the highlighted folder.
    ///     Return presses the button like a click, so a main action that removes something
    ///     asks first, with `trashConfirmation`, instead of removing it at once.
    ///   - onSecondary: What the secondary action does.
    public init(
        secondaryTitle: Text? = nil,
        primaryTitle: Text,
        isPrimaryEnabled: Bool = true,
        isPrimaryDefaultAction: Bool = true,
        theme: FeatureTheme,
        onSecondary: (() -> Void)? = nil,
        onPrimary: @escaping () -> Void
    ) {
        self.secondaryTitle = secondaryTitle
        self.primaryTitle = primaryTitle
        self.isPrimaryEnabled = isPrimaryEnabled
        self.isPrimaryDefaultAction = isPrimaryDefaultAction
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
                    .contentTransition(motion.allowsTravel ? .numericText() : .opacity)
            }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .disabled(!isPrimaryEnabled)
            .keyboardShortcut(isPrimaryDefaultAction ? .defaultAction : nil)
            // The title often tells what the action takes, such as the size of what is
            // selected: its digits roll to each new value and the button resizes smoothly.
            .animation(Motion.totals, value: primaryTitle)
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
