import CleanMacUI
import SwiftUI

/// List of tasks where the user chooses what to run.
struct MaintenanceChoosingView: View {
    let viewModel: MaintenanceViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 20) {
            MaintenanceHeader(theme: theme)
            MaintenanceSelectAllRow(state: viewModel.allSelectionState, theme: theme) {
                viewModel.toggleAll()
            }
            taskList
            MaintenanceActionBar(
                selectedCount: viewModel.selectedCount,
                requiresAdministrator: viewModel.requiresAdministrator,
                theme: theme
            ) { viewModel.run() }
        }
        .frame(maxWidth: 760)
    }

    private var taskList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.tasks) { task in
                    MaintenanceTaskCard(
                        task: task,
                        isSelected: viewModel.isSelected(task),
                        theme: theme
                    ) { viewModel.toggle(task) }
                }
            }
        }
        .scrollIndicators(.never)
    }
}
