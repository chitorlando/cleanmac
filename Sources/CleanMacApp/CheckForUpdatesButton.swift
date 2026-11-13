import SwiftUI

struct CheckForUpdatesButton: View {
    @ObservedObject var updater: AppUpdater

    var body: some View {
        Button(action: updater.checkForUpdates) {
            Text("Check for Updates…", bundle: .module, comment: "Application menu command to check for a new version.")
        }
        .disabled(!updater.canCheckForUpdates)
    }
}
