import CleanMacUI
import SwiftUI

/// Shown when no launchd property list was found.
struct LoginItemsNoneFoundView: View {
    let theme: FeatureTheme
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(localized: "Nothing Found", bundle: .module, comment: "Title shown when no login items were found."),
                subtitle: String(
                    localized: "No app added login or background items that CleanMac can list. Apps can also add them in System Settings.",
                    bundle: .module,
                    comment: "Message shown when no login items were found."
                ),
                theme: theme
            )
            OpenLoginItemsSettingsButton(action: onOpenSettings)
        }
        .frame(maxWidth: 560)
    }
}
