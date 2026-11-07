import CleanMacUI
import CleanMacCore
import SwiftUI

/// Checkbox above the task list that chooses or clears every task.
struct MaintenanceSelectAllRow: View {
    let state: ItemSelection.State
    let theme: FeatureTheme
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            TriStateCheckbox(state: CheckState(state), tint: theme.primary, label: title, action: onToggle)
            title
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Spacer()
        }
        .padding(.horizontal, 17)
    }

    private var title: Text {
        Text("Select all", bundle: .module, comment: "Checkbox that chooses every maintenance task.")
    }
}
