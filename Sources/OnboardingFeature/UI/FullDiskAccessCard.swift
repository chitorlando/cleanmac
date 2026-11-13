import CleanMacUI
import SwiftUI

/// Full Disk Access: what it's for, a live status and the way to System Settings.
///
/// While the card is on view, the status is checked every second and a half, so it turns
/// green as soon as the user switches CleanMac on in System Settings.
struct FullDiskAccessCard: View {
    @ObservedObject var viewModel: PermissionsViewModel
    let theme: FeatureTheme

    var body: some View {
        PermissionCard(
            symbolName: "externaldrive.fill",
            title: Text("Full Disk Access", bundle: .module, comment: "Name of the macOS permission."),
            explanation: Text(
                "Lets CleanMac analyze and clean protected folders, such as other apps’ containers, Mail, Safari and Group Containers. Without it, those folders are skipped.",
                bundle: .module,
                comment: "Why CleanMac asks for Full Disk Access."
            ),
            theme: theme
        ) {
            StatusBadge(Text("Recommended", bundle: .module, comment: "Badge on the permission CleanMac recommends."), color: .green)
        } status: {
            PermissionStatusLabel(state: viewModel.hasFullDiskAccess ? .on : .off)
            if !viewModel.hasFullDiskAccess {
                FullDiskAccessHint()
            }
        } actions: {
            if !viewModel.hasFullDiskAccess {
                Button {
                    viewModel.openFullDiskAccessSettings()
                } label: {
                    Text("Open Settings", bundle: .module, comment: "Button that opens the Privacy & Security settings.")
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.secondary)
            }
        }
        .task { await viewModel.watchFullDiskAccess() }
    }
}
