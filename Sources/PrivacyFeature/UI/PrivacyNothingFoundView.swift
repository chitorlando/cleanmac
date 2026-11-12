import CleanMacUI
import SwiftUI

/// Shown when no installed browser has caches to clear.
struct PrivacyNothingFoundView: View {
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(localized: "All Clean", bundle: .module, comment: "Title shown when no browser caches were found."),
                subtitle: String(
                    localized: "Your browsers have no caches to clear.",
                    bundle: .module,
                    comment: "Message shown when no browser caches were found."
                ),
                theme: theme
            )
            DoneButton(theme: theme, action: onDone)
        }
    }
}
