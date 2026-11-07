import CleanMacUI
import SwiftUI

/// One task the user can choose, with what it does and whether it needs a password.
struct MaintenanceTaskCard: View {
    let task: MaintenanceTaskKind
    let isSelected: Bool
    let theme: FeatureTheme
    let onToggle: () -> Void

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 14) {
                TriStateCheckbox(
                    state: isSelected ? .checked : .unchecked,
                    tint: theme.primary,
                    label: Text(task.title),
                    action: onToggle
                )

                Image(systemName: task.symbolName)
                    .font(.title2)
                    .foregroundStyle(theme.gradient)
                    .frame(width: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(task.title).font(.headline)
                        if task.privilege == .administrator {
                            StatusBadge(
                                Text("Requires password", bundle: .module, comment: "Badge on maintenance tasks that ask for the administrator password."),
                                color: .orange
                            )
                        }
                    }
                    Text(task.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}
