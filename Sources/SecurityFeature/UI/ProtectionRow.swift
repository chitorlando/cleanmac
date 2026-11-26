import CleanMacUI
import Foundation
import SwiftUI

/// One protection: how it's set, why that matters and, when it needs attention, the way to
/// the System Settings pane that changes it.
struct ProtectionRow: View {
    let check: ProtectionCheck

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FindingIcon(level: FindingLevel(check.state))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    check.kind.title
                        .font(.body.weight(.semibold))
                    StatusBadge(check.state.title, color: FindingLevel(check.state).color)
                }
                check.explanation
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if case .updateOptionsOff(let options) = check.detail {
                    ForEach(options, id: \.self) { option in
                        Label {
                            option.title
                        } icon: {
                            Image(systemName: "xmark.circle")
                        }
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                    }
                }
                if case .xprotect(let version, let updatedAt) = check.detail {
                    xprotectDetail(version: version, updatedAt: updatedAt)
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                }
            }
            Spacer(minLength: 8)
            if check.state.needsAttention, let url = check.kind.settingsURL {
                OpenSettingsButton(url: url)
            }
        }
    }

    private func xprotectDetail(version: String?, updatedAt: Date) -> Text {
        let date = updatedAt.formatted(date: .abbreviated, time: .omitted)
        guard let version else {
            return Text("Updated on \(date)", bundle: .module, comment: "When XProtect's definitions last changed. The argument is a date.")
        }
        return Text(
            "Version \(version), updated on \(date)",
            bundle: .module,
            comment: "XProtect's version and when its definitions last changed. The arguments are a version number, such as “5377”, and a date."
        )
    }
}
