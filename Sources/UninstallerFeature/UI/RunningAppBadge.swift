import CleanMacUI
import SwiftUI

/// Marks an app that is open and therefore cannot be uninstalled yet.
struct RunningAppBadge: View {
    var body: some View {
        StatusBadge(
            Text("Open", bundle: .module, comment: "Badge on an app that is currently running."),
            color: .green
        )
        .help(Text("Quit this app to uninstall it.", bundle: .module, comment: "Tooltip of the badge on a running app."))
    }
}
