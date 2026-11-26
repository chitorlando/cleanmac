import SwiftUI

/// The apps whose signature needs a look, or a line saying every app is signed as it should be.
struct AppsCard: View {
    let checkedCount: Int
    let apps: [AppSignatureCheck]

    var body: some View {
        SecurityCard(
            title: Text("Apps", bundle: .module, comment: "Title of the part of the security review about the signatures of the installed apps."),
            summary: Text(
                "\(checkedCount) apps checked in your Applications folders.",
                bundle: .module,
                comment: "Subtitle of the Apps part of the security review. The argument is how many apps had their signature checked."
            )
        ) {
            if apps.isEmpty {
                HStack(spacing: 12) {
                    FindingIcon(level: .fine)
                    Text(
                        "Every app is signed by Apple or by an identified developer, and its signature is intact.",
                        bundle: .module,
                        comment: "Shown when the security review found no app with a missing, broken or untrusted signature."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(apps) { app in
                        AppFindingRow(app: app)
                    }
                }
            }
        }
    }
}
