import CleanMacUI
import SwiftUI

/// Progress of a review: what it is looking at and how many apps it has checked.
struct SecurityReviewingView: View {
    let progress: SecurityReviewProgress
    let theme: FeatureTheme
    let onCancel: () -> Void

    var body: some View {
        ScanProgressView(
            progress: progress.fraction,
            value: progress.checkedApps.formatted(),
            caption: Text("apps checked", bundle: .module, comment: "Caption under the number of apps whose signature the security review has checked."),
            status: progress.step.status,
            theme: theme,
            onCancel: onCancel
        )
    }
}

private extension SecurityReviewStep {
    var status: Text {
        switch self {
        case .protections:
            Text("Checking your Mac’s protections…", bundle: .module, comment: "Status shown while the security review reads the settings of macOS, such as FileVault.")
        case .apps:
            Text("Checking app signatures…", bundle: .module, comment: "Status shown while the security review checks the code signature of each app.")
        case .persistence:
            Text("Checking login and background items…", bundle: .module, comment: "Status shown while the security review checks what launchd starts at login or in the background.")
        case .permissions:
            Text("Reading app permissions…", bundle: .module, comment: "Status shown while the security review reads which apps have sensitive permissions, such as Full Disk Access.")
        }
    }
}
