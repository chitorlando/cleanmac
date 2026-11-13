import CleanMacUI
import SwiftUI

/// One permission: icon, name, an optional badge, what it's for, its status and what to do.
struct PermissionCard<Badge: View, Status: View, Actions: View>: View {
    let symbolName: String
    let title: Text
    let explanation: Text
    let theme: FeatureTheme
    @ViewBuilder let badge: Badge
    @ViewBuilder let status: Status
    @ViewBuilder let actions: Actions

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: symbolName)
                        .font(.title2)
                        .foregroundStyle(theme.gradient)
                        .accessibilityHidden(true)
                    title
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 4)
                    badge
                }
                explanation
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                status
                Spacer(minLength: 0)
                actions
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
