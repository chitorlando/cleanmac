import AppKit
import CleanMacCore
import CleanMacUI
import SwiftUI

/// A single file or folder inside a category.
struct JunkItemRow: View {
    let item: CleanableItem
    let isSelected: Bool
    let tint: Color
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TriStateCheckbox(state: isSelected ? .checked : .unchecked, tint: tint, action: onToggle)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name).lineLimit(1)
                Text(parentPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Text(item.size.formattedByteCount)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)

            Button(action: revealInFinder) {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help(Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals an item in Finder."))
        }
        .padding(.leading, 4)
    }

    private var parentPath: String {
        (item.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
    }

    private func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }
}
