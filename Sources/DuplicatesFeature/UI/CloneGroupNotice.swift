import SwiftUI

/// Explains, in the details of a group made only of clones, why removing its copies frees no space.
struct CloneGroupNotice: View {
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(
                    "These copies share the same data on disk, so removing them frees no space.",
                    bundle: .module,
                    comment: "Explains why a group made only of APFS clones can free no space."
                )
                .fontWeight(.medium)
                Text(
                    "You can still mark copies by hand to tidy up your folders.",
                    bundle: .module,
                    comment: "Shown below the explanation of a group made only of clones."
                )
                .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.orange)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.10), in: .rect(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.orange.opacity(0.3), lineWidth: 1))
    }
}
