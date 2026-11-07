import CleanMacUI
import SwiftUI

/// Bottom bar with the password notice and the button that runs the chosen tasks.
struct MaintenanceActionBar: View {
    let selectedCount: Int
    let requiresAdministrator: Bool
    let theme: FeatureTheme
    let onRun: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if requiresAdministrator {
                Label {
                    Text(
                        "You’ll be asked for your administrator password once.",
                        bundle: .module,
                        comment: "Notice shown when the chosen maintenance tasks need the administrator password."
                    )
                } icon: {
                    Image(systemName: "lock.fill")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onRun) { runTitle }
            .buttonStyle(GlowButtonStyle(theme: theme, shape: .capsule))
            .disabled(selectedCount == 0)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var runTitle: Text {
        selectedCount == 0
            ? Text("Run Tasks", bundle: .module, comment: "Disabled button shown before any maintenance task is chosen.")
            : Text(
                "Run \(selectedCount) Tasks",
                bundle: .module,
                comment: "Button that runs the chosen maintenance tasks. The argument is how many."
            )
    }
}
