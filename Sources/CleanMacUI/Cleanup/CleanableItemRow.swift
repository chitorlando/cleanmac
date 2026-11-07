import AppKit
import CleanMacCore
import SwiftUI

/// A single file or folder that can be selected for removal.
public struct CleanableItemRow: View {
    private let item: CleanableItem
    private let isSelected: Bool
    private let isToggleEnabled: Bool
    private let tint: Color
    private let onToggle: () -> Void

    /// - Parameter isToggleEnabled: `false` keeps the item visible but prevents changing its selection.
    public init(
        item: CleanableItem,
        isSelected: Bool,
        isToggleEnabled: Bool = true,
        tint: Color,
        onToggle: @escaping () -> Void
    ) {
        self.item = item
        self.isSelected = isSelected
        self.isToggleEnabled = isToggleEnabled
        self.tint = tint
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: 12) {
            TriStateCheckbox(state: isSelected ? .checked : .unchecked, tint: tint, action: onToggle)
                .disabled(!isToggleEnabled)

            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: item.name).lineLimit(1)
                Text(verbatim: parentPath)
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
