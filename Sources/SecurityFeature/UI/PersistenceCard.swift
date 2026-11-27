import CleanMacUI
import SwiftUI

/// The login and background items that deserve a look, or a line saying none does.
struct PersistenceCard: View {
    let findings: [PersistenceFinding]

    var body: some View {
        ReviewCard(
            title: Text("Login & Background Items", bundle: .module, comment: "Title of the part of the security review about what launchd starts on its own."),
            summary: Text(
                "What starts on its own at login or in the background, from your Library and the Mac’s.",
                bundle: .module,
                comment: "Subtitle of the Login & Background Items part of the security review."
            )
        ) {
            if findings.isEmpty {
                HStack(spacing: 12) {
                    FindingIcon(level: .fine)
                    Text(
                        "No item runs an unsigned program, or one from a temporary or hidden folder.",
                        bundle: .module,
                        comment: "Shown when the security review found no login or background item worth a look."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(findings) { finding in
                        PersistenceFindingRow(finding: finding)
                    }
                }
            }
        }
    }
}
