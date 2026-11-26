import CleanMacCore
import SwiftUI

/// A single file or folder that can be selected for removal, with the common item context menu.
public struct CleanableItemRow: View {
    private let item: CleanableItem
    private let title: String
    private let subtitle: String?
    private let badge: Text?
    private let isSelected: Bool
    private let isToggleEnabled: Bool
    private let tint: Color
    private let onToggle: () -> Void
    @Environment(\.fileActions) private var files

    /// - Parameters:
    ///   - title: What the item is called, when its file name doesn't tell, such as the volume
    ///     a Trash bin is on. By default, its file name.
    ///   - subtitle: What's shown below the title, such as the model of an iPhone a backup
    ///     belongs to. By default, the folder that holds the item.
    ///   - badge: A short label next to the title, such as “Most Recent”.
    ///   - isToggleEnabled: `false` keeps the item visible but prevents changing its selection.
    public init(
        item: CleanableItem,
        title: String? = nil,
        subtitle: String? = nil,
        badge: Text? = nil,
        isSelected: Bool,
        isToggleEnabled: Bool = true,
        tint: Color,
        onToggle: @escaping () -> Void
    ) {
        self.item = item
        self.title = title ?? item.name
        self.subtitle = subtitle
        self.badge = badge
        self.isSelected = isSelected
        self.isToggleEnabled = isToggleEnabled
        self.tint = tint
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: 12) {
            TriStateCheckbox(
                state: isSelected ? .checked : .unchecked,
                tint: tint,
                label: Text(verbatim: title),
                action: onToggle
            )
                .disabled(!isToggleEnabled)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(verbatim: title).lineLimit(1)
                    if let badge {
                        StatusBadge(badge, color: tint)
                    }
                }
                Text(verbatim: subtitle ?? parentPath)
                    .font(.caption)
                    .foregroundStyle(.supportingText)
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
            .help(revealLabel)
            .accessibilityLabel(revealLabel)
        }
        .padding(.leading, 4)
        .contextMenu {
            // Folders found by a scan usually end in a slash; others count as files.
            ItemContextMenu(
                url: item.url,
                isFolder: item.url.hasDirectoryPath,
                selection: ItemMenuSelection(isSelected: isSelected, canChange: isToggleEnabled),
                onToggle: onToggle
            )
        }
    }

    private var revealLabel: Text {
        Text("Show in Finder", bundle: .module, comment: "Tooltip of the button that reveals an item in Finder.")
    }

    private var parentPath: String {
        (item.url.deletingLastPathComponent().path as NSString).abbreviatingWithTildeInPath
    }

    private func revealInFinder() {
        files.showInFinder(item.url)
    }
}
