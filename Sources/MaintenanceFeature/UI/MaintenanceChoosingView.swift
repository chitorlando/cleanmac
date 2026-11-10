import CleanMacUI
import SwiftUI

/// List of tasks where the user chooses what to run.
struct MaintenanceChoosingView: View {
    @ObservedObject var viewModel: MaintenanceViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 20) {
            MaintenanceHeader(theme: theme)
            MaintenanceSelectAllRow(state: viewModel.allSelectionState, theme: theme) {
                viewModel.toggleAll()
            }
            taskList
            actionBar
        }
        .frame(maxWidth: 760)
    }

    /// The shared action bar, with the password notice on its left when a chosen task needs it.
    private var actionBar: some View {
        HStack(spacing: 16) {
            if viewModel.requiresAdministrator {
                AdministratorPasswordNotice()
            }
            ActionBar(
                primaryTitle: runTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme
            ) { viewModel.run() }
        }
    }

    private var runTitle: Text {
        viewModel.selectedCount == 0
            ? Text("Run Tasks", bundle: .module, comment: "Disabled button shown before any maintenance task is chosen.")
            : Text(
                "Run \(viewModel.selectedCount) Tasks",
                bundle: .module,
                comment: "Button that runs the chosen maintenance tasks. The argument is how many."
            )
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
