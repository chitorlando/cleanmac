import CleanMacCore
import CleanMacUI
import SwiftUI

/// Finder automation: what it's for, its status and the button that shows the system's question.
struct FinderAutomationCard: View {
    @ObservedObject var viewModel: PermissionsViewModel
    let theme: FeatureTheme

    var body: some View {
        PermissionCard(
            symbolName: "folder.fill",
            title: Text("Finder Automation", bundle: .module, comment: "Name of the permission to control Finder."),
            explanation: Text(
                "Lets CleanMac ask Finder to move protected apps to the Trash, so you can still put them back.",
                bundle: .module,
                comment: "Why CleanMac asks to control Finder."
            ),
            theme: theme
        ) {
            EmptyView()
        } status: {
            PermissionStatusLabel(state: statusState)
        } actions: {
            switch viewModel.finderAutomation {
            case .notDetermined:
                Button {
                    Task { await viewModel.allowFinderAutomation() }
                } label: {
                    Text("Allow", bundle: .module, comment: "Button that shows the system's question about controlling Finder.")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.secondary)
            case .denied:
                Button {
                    viewModel.openAutomationSettings()
                } label: {
                    Text("Open Settings", bundle: .module, comment: "Button that opens the Privacy & Security settings.")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.secondary)
            case .granted:
                EmptyView()
            }
        }
    }

    private var statusState: PermissionStatusLabel.State {
        switch viewModel.finderAutomation {
        case .granted: .on
        case .denied: .off
        case .notDetermined: .notSetUp
        }
    }
}
