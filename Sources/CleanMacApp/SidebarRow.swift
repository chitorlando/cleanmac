import CleanMacUI
import SwiftUI

/// Icon and title of one sidebar entry.
struct SidebarRow: View {
    let title: String
    let symbolName: String
    let theme: FeatureTheme

    var body: some View {
        Label {
            Text(title)
        } icon: {
            SidebarIcon(symbolName: symbolName, theme: theme)
        }
        .padding(.vertical, 2)
    }
}
