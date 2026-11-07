import CleanMacUI
import SwiftUI

/// Shown when the scan finds nothing to remove.
struct JunkAllCleanView: View {
    let theme: FeatureTheme
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(localized: "All Clean", bundle: .module, comment: "Title shown when no junk was found."),
                subtitle: String(
                    localized: "We didn’t find any junk to remove.",
                    bundle: .module,
                    comment: "Message shown when no junk was found."
                ),
                theme: theme
            )
            DoneButton(theme: theme, action: onDone)
        }
    }
}
