import AppKit
import CleanMacUI
import SwiftUI

/// One copy of the focused group: checkbox, name and badges, folder and creation date, and a button to show it in Finder.
///
/// It takes plain values instead of the view model, and two rows are equal when they show
/// the same, so wrapped in `.equatable()` a row is only evaluated again when it changes,
/// not on every change of the screen.
struct DuplicateCopyRow: View, Equatable {
    let file: DuplicateFile
    let isSelected: Bool
    /// `false` keeps the copy from being marked, as when every other copy already is.
    let canSelect: Bool
    let isSuggestedKeeper: Bool
    let isClone: Bool
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
            .disabled(!canSelect)

            VStack(alignment: .leading, spacing: 2) {
                BadgedTitleLayout {
                    Text(verbatim: file.item.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if isSuggestedKeeper && !isSelected {
                        KeepBadge()
                    }
                    if isClone {
                        CloneBadge()
                    }
                    if file.hasOtherNames {
                        HardLinkBadge()
                    }
                }
                HStack(spacing: 6) {
                    Text(verbatim: folderPath)
                        .foregroundStyle(.supportingText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if file.creationDate != nil {
                        Text(verbatim: "·")
                            .foregroundStyle(.supportingText)
                            .accessibilityHidden(true)
                    }
                    CreationDateText(date: file.creationDate)
                        .fixedSize()
                }
                .font(.caption)
            }

            Spacer(minLength: 8)

            revealButton
        }
        .padding(.leading, 4)
    }

    /// Compares what the row shows. The action is left out: it acts on the same copy.
    /// The hard link badge has no value of its own: it comes from `file`.
    nonisolated static func == (lhs: DuplicateCopyRow, rhs: DuplicateCopyRow) -> Bool {
        lhs.file == rhs.file
            && lhs.isSelected == rhs.isSelected
            && lhs.canSelect == rhs.canSelect
            && lhs.isSuggestedKeeper == rhs.isSuggestedKeeper
            && lhs.isClone == rhs.isClone
            && lhs.theme.primary == rhs.theme.primary
            && lhs.theme.secondary == rhs.theme.secondary
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
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals a copy in Finder.")
    }
}
