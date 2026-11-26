import Foundation
import SwiftUI

/// Opens the System Settings pane where the user changes what a finding is about.
struct OpenSettingsButton: View {
    let url: URL
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(url)
        } label: {
            Text(
                "Open Settings",
                bundle: .module,
                comment: "Button that opens the System Settings pane of a finding of the security review, such as FileVault or Full Disk Access."
            )
        }
    }
}
