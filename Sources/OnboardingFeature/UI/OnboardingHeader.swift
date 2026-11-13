import CleanMacUI
import SwiftUI

/// Welcome on the first launch, or a plain title when the screen is opened again.
struct OnboardingHeader: View {
    let isFirstRun: Bool
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(theme.gradient)
                .accessibilityHidden(true)
            title
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(
                "Two permissions let CleanMac analyze and clean without interruptions. Both are optional, and you can come back here from the CleanMac menu.",
                bundle: .module,
                comment: "Introduction of the permissions screen."
            )
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 560)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var title: Text {
        isFirstRun
            ? Text("Welcome to CleanMac", bundle: .module, comment: "Title of the permissions screen on the first launch.")
            : Text("Permissions", bundle: .module, comment: "Title of the permissions screen when opened again.")
    }
}
