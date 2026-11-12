import SwiftUI

/// Title of the list with how many items were found, and the way to System Settings.
struct LoginItemsHeader: View {
    let itemCount: Int
    let orphanedCount: Int
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Login Items", bundle: .module, comment: "Feature name in the sidebar.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)
                summary
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            OpenLoginItemsSettingsButton(action: onOpenSettings)
        }
    }

    private var summary: Text {
        let items = Text("\(itemCount) items", bundle: .module, comment: "Number of login items found.")
        guard orphanedCount > 0 else { return items }
        let orphaned = Text(
            "\(orphanedCount) orphaned",
            bundle: .module,
            comment: "Number of login items found whose program no longer exists, shown after the number of items."
        )
        return items + Text(verbatim: " · ") + orphaned
    }
}
