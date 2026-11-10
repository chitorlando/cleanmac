import CleanMacUI
import SwiftUI

/// Right pane: the copies of the focused group, or a hint when none is focused.
struct DuplicateGroupDetailPane: View {
    let viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            if let group = viewModel.focusedGroup {
                DuplicateGroupDetailView(group: group, viewModel: viewModel, theme: theme)
            } else {
                Text("Select a group to see its copies.", bundle: .module, comment: "Shown in the detail pane when no group of duplicates is focused.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
