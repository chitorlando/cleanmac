import CleanMacUI
import SwiftUI

/// Progress while the chosen tasks run.
struct MaintenanceRunningView: View {
    let requiresAdministrator: Bool
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 16) {
            BusyView(
                message: Text("Running maintenance…", bundle: .module, comment: "Status shown while maintenance tasks run."),
                theme: theme
            )
            if requiresAdministrator {
                Text(
                    "If macOS asks, enter your administrator password.",
                    bundle: .module,
                    comment: "Hint shown while maintenance tasks that need the administrator password run."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
    }
}
