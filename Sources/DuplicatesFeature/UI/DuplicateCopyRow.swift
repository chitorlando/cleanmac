import AppKit
import CleanMacUI
import SwiftUI

/// One copy of the focused group: checkbox, name and badges, folder and creation date, and a button to show it in Finder.
struct DuplicateCopyRow: View {
    let file: DuplicateFile
    let group: DuplicateGroup
    let viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    private var isSelected: Bool { viewModel.isSelected(file) }

    var body: some View {
        HStack(spacing: 12) {
            TriStateCheckbox(
                state: isSelected ? .checked : .unchecked,
                tint: theme.primary,
                label: Text(verbatim: file.item.name)
            ) {
                viewModel.toggle(file, in: group)
            }
            .disabled(!viewModel.canSelect(file, in: group))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(verbatim: file.item.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if viewModel.isSuggestedKeeper(file, in: group) && !isSelected {
                        KeepBadge()
                    }
                    if file.isClone {
                        CloneBadge()
                    }
                }
                HStack(spacing: 6) {
                    Text(verbatim: folderPath)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if file.creationDate != nil {
                        Text(verbatim: "·")
                            .foregroundStyle(.tertiary)
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
