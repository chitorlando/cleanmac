import CleanMacCore
import CleanMacUI
import Foundation
import SwiftUI

/// `ScopePill` shown while the list is limited to the items of one app: the name of the app,
/// its path as a tooltip and a button that lists every item again.
struct LoginItemsAppPill: View {
    let app: LoginItemOwner
    let theme: FeatureTheme
    let onShowAll: () -> Void

    /// What lists every item again, on the pill and wherever else the limit can be lifted.
    static var showAllTitle: Text {
        Text(
            "Show All Login Items",
            bundle: .module,
            comment: "Button, and tooltip of the button on the pill that names an app, that lists every login item again instead of only those of that app."
        )
    }

    var body: some View {
        ScopePill(
            symbolName: "app.fill",
            label: Text(
                "Only from: \(app.name)",
                bundle: .module,
                comment: "Pill shown while the list is limited to the login items of one app. The argument is the name of the app."
            ),
            help: Text(verbatim: app.appURL.tildeAbbreviatedPath),
            clearTitle: Self.showAllTitle,
            theme: theme,
            onClear: onShowAll
        )
    }
}
