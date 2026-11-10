import CleanMacUI
import SwiftUI

/// Icon, name, number of copies and space the focused group can free.
///
/// The space sits on the right when everything fits on one line, and below the name otherwise.
struct DuplicateGroupDetailHeader: View {
    let group: DuplicateGroup
    let theme: FeatureTheme

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                DuplicateFileIcon(group: group, size: 56)
                titles
                Spacer(minLength: 16)
                recoverableSpace(alignment: .trailing)
            }
            HStack(alignment: .top, spacing: 16) {
                DuplicateFileIcon(group: group, size: 56)
                VStack(alignment: .leading, spacing: 8) {
                    titles
                    recoverableSpace(alignment: .leading)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: group.name)
                .font(.title2.weight(.bold))
                .lineLimit(1)
                .truncationMode(.middle)
            Text(
                "\(group.files.count) copies of \(group.fileSize.formattedByteCount) each",
                bundle: .module,
                comment: "Number of copies in a group of duplicates and the size of each, as in “3 copies of 1.2 GB each”."
            )
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
    }

    private func recoverableSpace(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(group.recoverableSize.formattedByteCount)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(theme.gradient)
            Text("can be freed", bundle: .module, comment: "Caption below the space a group of duplicates can free.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
    }
}
