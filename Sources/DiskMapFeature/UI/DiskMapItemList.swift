import CleanMacUI
import SwiftUI

/// Items of the focused folder, largest first, with its small items counted together at the end.
///
/// It holds the same items as the rings, so it's also how VoiceOver reads the map.
struct DiskMapItemList: View {
    @ObservedObject var viewModel: DiskMapViewModel
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            if let folder = viewModel.focusedFolder, folder.size > 0 {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            rows(in: folder)
                        }
                        .padding(.trailing, 8)
                    }
                    .onChange(of: viewModel.highlightedID) { _, id in
                        guard let id else { return }
                        proxy.scrollTo(id)
                    }
                }
            } else {
                Text("This folder is empty", bundle: .module, comment: "Shown in the disk map for a folder with nothing inside.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func rows(in folder: DiskNode) -> some View {
        ForEach(Array(folder.children.enumerated()), id: \.element.id) { index, node in
            DiskMapItemRow(
                node: node,
                share: share(of: node.size, in: folder),
                color: SegmentPalette.color(forBranch: index),
                advice: viewModel.advice(for: node),
                isSelected: viewModel.isSelected(node),
                isHighlighted: viewModel.highlightedID == node.id,
                canOpen: viewModel.canOpen(node),
                theme: theme,
                onToggle: { viewModel.toggle(node) },
                onOpen: { viewModel.open(node) }
            )
            .id(node.id)
            .onHover { inside in
                if inside { viewModel.highlightedID = node.id }
            }
        }
        if let other = folder.otherItems {
            OtherItemsRow(itemCount: other.itemCount, size: other.size, share: share(of: other.size, in: folder))
        }
    }

    private func share(of size: Int64, in folder: DiskNode) -> Double {
        folder.size > 0 ? Double(size) / Double(folder.size) : 0
    }
}
