import CleanMacCore
import CleanMacUI
import SwiftUI

/// A login or background item worth a look: what it runs, why it stands out and, when it
/// belongs to an app, the way to that app's login items.
struct PersistenceFindingRow: View {
    let finding: PersistenceFinding

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: finding.displayName)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                ForEach(finding.concerns, id: \.self) { concern in
                    Label {
                        concern.explanation
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(FindingLevel.attention.color)
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                if let programPath = finding.job.programPath {
                    Text(verbatim: programPath)
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                NextStepButtons(itemURL: finding.plistURL, appURL: finding.owner?.appURL)
            }
            Spacer(minLength: 0)
        }
        .contextMenu {
            ItemContextMenu(
                url: finding.plistURL,
                featureTarget: finding.owner.map { FeatureItemTarget(itemAt: $0.appURL, isFolder: false) },
                selection: .unavailable
            )
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let owner = finding.owner {
            AppIconView(url: owner.appURL, size: 32)
        } else {
            Image(systemName: "gearshape.2")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
        }
    }
}

extension PersistenceConcern {
    /// Why the item stands out, in plain words.
    var explanation: Text {
        switch self {
        case .unsignedProgram:
            Text("Its program has no signature, so nothing confirms who made it.", bundle: .module, comment: "Why a login or background item stands out: its program isn't signed.")
        case .damagedProgram:
            Text("Its program no longer matches its signature: something changed it after it was signed.", bundle: .module, comment: "Why a login or background item stands out: its program's signature is damaged.")
        case .temporaryOrSharedFolder:
            Text("It runs something from a temporary or shared folder, where any app can put files. Installers don’t usually leave programs there.", bundle: .module, comment: "Why a login or background item stands out: it runs something from a folder such as /tmp or /Users/Shared.")
        case .hiddenFolder:
            Text("It runs something from a hidden folder, which Finder doesn’t show. Some developer tools do that; if you don’t recognize it, take a closer look.", bundle: .module, comment: "Why a login or background item stands out: it runs something from a folder whose name starts with a dot.")
        }
    }
}
