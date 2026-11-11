import AppKit
import CleanMacUI
import SwiftUI

/// One large file: checkbox, kind icon, name and folder, and size and last use.
///
/// The name gets most of the row and wraps to a second line before it's cut. Instead of a
/// separate button, the folder line shows the file in Finder, which keeps it reachable with
/// the keyboard and VoiceOver, and the row's context menu does the same.
struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let theme: FeatureTheme
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TriStateCheckbox(
                state: isSelected ? .checked : .unchecked,
                tint: theme.primary,
                label: Text(verbatim: file.item.name),
                action: onToggle
            )

            Image(systemName: file.kind.symbolName)
                .foregroundStyle(theme.gradient)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: file.item.name)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .fixedSize(horizontal: false, vertical: true)
                folderButton
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 1) {
                Text(file.item.size.formattedByteCount)
                    .font(.callout.monospacedDigit())
                LastUsedText(date: file.lastAccessDate)
            }
            .fixedSize()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .contextMenu {
            Button(action: reveal) { revealLabel }
        }
    }

    private var folderPath: String {
        (file.item.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
    }

    private var folderButton: some View {
        Button(action: reveal) {
            Text(verbatim: folderPath)
                .font(.caption)
                .foregroundStyle(.supportingText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .buttonStyle(.plain)
        .help(revealLabel)
        .accessibilityLabel(revealLabel)
        .accessibilityValue(Text(verbatim: folderPath))
    }

    private func reveal() {
        NSWorkspace.shared.activateFileViewerSelecting([file.item.url])
    }

    private var revealLabel: Text {
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals a file in Finder.")
    }
}
