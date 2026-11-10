import CleanMacUI
import SwiftUI

/// A planned feature in the sidebar: dimmed, marked as coming soon and not selectable.
struct UpcomingSidebarRow: View {
    let feature: UpcomingFeature

    var body: some View {
        HStack(spacing: 6) {
            SidebarRow(title: feature.title, symbolName: feature.symbolName, theme: .neutral)
                .opacity(0.5)
            Spacer(minLength: 4)
            // Primary at reduced opacity stays readable on its tinted capsule in light and dark sidebars.
            StatusBadge(
                Text("Soon", bundle: .module, comment: "Badge on sidebar features that are not available yet."),
                color: .primary.opacity(0.65)
            )
        }
        .selectionDisabledWhereSupported()
        .accessibilityElement(children: .combine)
    }
}
