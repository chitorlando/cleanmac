import CleanMacUI
import SwiftUI

/// An app whose signature needs a look: what is wrong with it, who signed it and what to do.
struct AppFindingRow: View {
    let app: AppSignatureCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AppIconView(url: app.url, size: 32)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(verbatim: app.name)
                        .font(.body.weight(.semibold))
                        .lineLimit(1)
                    StatusBadge(app.signature.title, color: FindingLevel.attention.color)
                }
                app.signature.explanation
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let signer = app.signer {
                    Text("Signed by \(signer)", bundle: .module, comment: "Who signed an app or a program. The argument is a developer's name, such as “Example Ltd (ABCDE12345)”.")
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                }
                NextStepButtons(itemURL: app.url, appURL: app.url)
            }
            Spacer(minLength: 0)
        }
        .contextMenu {
            ItemContextMenu(url: app.url, selection: .unavailable)
        }
    }
}
