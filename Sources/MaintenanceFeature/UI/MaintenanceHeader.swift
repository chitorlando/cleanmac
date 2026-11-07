import CleanMacUI
import SwiftUI

/// Compact introduction that leaves room for the task list.
struct MaintenanceHeader: View {
    let theme: FeatureTheme

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(theme.gradient)
                .shadow(color: theme.primary.opacity(0.6), radius: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Maintenance", bundle: .module, comment: "Feature name in the sidebar.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .accessibilityAddTraits(.isHeader)
                Text(
                    "Run routine tasks that fix common glitches and keep macOS responsive.",
                    bundle: .module,
                    comment: "Introduction of the maintenance feature."
                )
                .font(.title3)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }
}
