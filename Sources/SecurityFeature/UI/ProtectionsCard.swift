import CleanMacUI
import SwiftUI

/// The protections built into macOS, each with how it's set and why it matters.
struct ProtectionsCard: View {
    let checks: [ProtectionCheck]

    var body: some View {
        ReviewCard(
            title: Text("Mac Settings", bundle: .module, comment: "Title of the part of the security review about the protections built into macOS."),
            summary: Text("The protections built into macOS.", bundle: .module, comment: "Subtitle of the Mac Settings part of the security review.")
        ) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(checks) { check in
                    ProtectionRow(check: check)
                }
            }
        }
    }
}
