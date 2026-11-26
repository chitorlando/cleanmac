import CleanMacCore
import CleanMacUI
import SwiftUI

/// Shown when the app the list is limited to has no login items that CleanMac can list.
struct LoginItemsNoneForAppView: View {
    let app: LoginItemOwner
    let theme: FeatureTheme
    let onShowAll: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            HeroHeader(
                symbolName: "sparkles",
                title: String(
                    localized: "No Login Items for \(app.name)",
                    bundle: .module,
                    comment: "Title shown when the app the login items are limited to has none. The argument is the name of the app."
                ),
                subtitle: String(
                    localized: "\(app.name) added no login or background items that CleanMac can list. Apps can also add them in System Settings.",
                    bundle: .module,
                    comment: "Message shown when the app the login items are limited to has none. The argument is the name of the app."
                ),
                theme: theme
            )
            VStack(spacing: 16) {
                Button(action: onShowAll) {
                    LoginItemsAppPill.showAllTitle
                }
                .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
                .keyboardShortcut(.defaultAction)
                OpenLoginItemsSettingsButton(action: onOpenSettings)
            }
        }
        .frame(maxWidth: 560)
    }
}
