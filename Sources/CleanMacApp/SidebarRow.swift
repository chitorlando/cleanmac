import CleanMacUI
import SwiftUI

/// Icon and title of one sidebar entry. The icon answers when the entry gets selected.
struct SidebarRow: View {
    let title: String
    let symbolName: String
    let theme: FeatureTheme
    var isSelected = false

    var body: some View {
        Label {
            Text(title)
        } icon: {
            SidebarIcon(symbolName: symbolName, theme: theme, isSelected: isSelected)
        }
        .padding(.vertical, 2)
    }
}
