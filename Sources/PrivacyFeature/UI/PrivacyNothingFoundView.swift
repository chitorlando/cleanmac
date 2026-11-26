import CleanMacUI
import SwiftUI

/// Shown when no caches were found. It doesn't say the browsers have none: Safari keeps most
/// of its caches in its container, where CleanMac never looks.
struct PrivacyNothingFoundView: View {
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(localized: "All Clean", bundle: .module, comment: "Title shown when no browser caches were found."),
                subtitle: String(
                    localized: "We didn’t find any browser caches to clear.",
                    bundle: .module,
                    comment: "Message shown when no browser caches were found."
                ),
                theme: theme
            )
            DoneButton(theme: theme, action: onDone)
        }
    }
}
