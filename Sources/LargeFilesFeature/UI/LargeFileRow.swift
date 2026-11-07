import AppKit
import CleanMacUI
import SwiftUI

/// One large file: checkbox, kind icon, name and folder, size and last use, and a button to show it in Finder.
struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let theme: FeatureTheme
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TriStateCheckbox(
                state: isSelected ? .checked : .unchecked,
                tint: theme.primary,
                label: Text(verbatim: file.item.name),
                action: onToggle
            )

            Image(systemName: file.kind.symbolName)
                .font(.title3)
                .foregroundStyle(theme.gradient)
                .frame(width: 26)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: file.item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(verbatim: folderPath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(file.item.size.formattedByteCount)
                    .font(.callout.monospacedDigit())
                LastUsedText(date: file.lastAccessDate)
            }
            .frame(minWidth: 90, alignment: .trailing)

            revealButton
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    private var folderPath: String {
        (file.item.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
    }

    private var revealButton: some View {
        Button {
            NSWorkspace.shared.activateFileViewerSelecting([file.item.url])
        } label: {
            Image(systemName: "magnifyingglass")
        }
        .buttonStyle(.borderless)
        .help(revealLabel)
        .accessibilityLabel(revealLabel)
    }

    private var revealLabel: Text {
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals a file in Finder.")
    }
}
