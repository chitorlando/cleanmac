import AppKit
import CleanMacUI
import SwiftUI

/// One item of the focused folder: checkbox, icon in its branch's color, name with its number
/// of files or a note on why it can't be removed, size and share, and buttons to open or reveal it.
///
/// On an app, the note that points to the Uninstaller is a button that shows the app there,
/// when the row is told it can.
///
/// The name gets the room left by the fixed columns and wraps to a second line before it's
/// cut, so names like “Application Support” stay whole in the smallest window.
struct DiskMapItemRow: View {
    let node: DiskNode
    let share: Double
    let color: Color
    let advice: RemovalAdvice
    let isSelected: Bool
    let isHighlighted: Bool
    let canOpen: Bool
    let canShowInUninstaller: Bool
    let theme: FeatureTheme
    let onToggle: () -> Void
    let onOpen: () -> Void
    let onShowInUninstaller: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            TriStateCheckbox(
                state: isSelected ? .checked : .unchecked,
                tint: theme.primary,
                label: Text(verbatim: node.name),
                action: onToggle
            )
            .disabled(!advice.allowsMovingToTrash)
            .help(advice.explanation ?? Text(verbatim: node.name))

            Image(systemName: node.symbolName)
                .foregroundStyle(color)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: node.name)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .fixedSize(horizontal: false, vertical: true)
                subtitle
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 1) {
                Text(node.size.formattedByteCount)
                    .font(.callout.monospacedDigit())
                Text(share, format: .percent.precision(.fractionLength(0)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .fixedSize()

            actions
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(SelectionHighlight(isSelected: isHighlighted, theme: theme))
        .contentShape(.rect)
        .onTapGesture(count: 2) { if canOpen { onOpen() } }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var subtitle: some View {
        if let note = advice.note {
            if canShowInUninstaller {
                uninstallerButton(titled: note)
            } else {
                note
            }
        } else if node.kind == .folder {
            Text(
                "\(node.fileCount) files",
                bundle: .module,
                comment: "Number of files inside a folder of the disk map."
            )
        } else {
            Text(verbatim: "")
        }
    }

    private func uninstallerButton(titled title: Text) -> some View {
        Button(action: onShowInUninstaller) {
            title
                .underline()
                .foregroundStyle(theme.primary)
        }
        .buttonStyle(.plain)
        .help(advice.explanation ?? title)
    }

    private var actions: some View {
        HStack(spacing: 4) {
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([node.url])
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help(revealTitle)
            .accessibilityLabel(revealTitle)

            Button(action: onOpen) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .opacity(canOpen ? 1 : 0)
            .disabled(!canOpen)
            .help(openTitle)
            .accessibilityLabel(openTitle)
        }
    }

    private var revealTitle: Text {
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals an item in Finder.")
    }

    private var openTitle: Text {
        Text("Open", bundle: .module, comment: "Tooltip of the button that opens a folder in the disk map.")
    }
}
