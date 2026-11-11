import CleanMacUI
import SwiftUI

/// Items of the focused folder, largest first, with its small items counted together at the end.
///
/// It holds the same items as the rings, so it's also how VoiceOver reads the map.
struct DiskMapItemList: View {
    @ObservedObject var viewModel: DiskMapViewModel
    let theme: FeatureTheme

    @Environment(\.openFeature) private var openFeature
    @Environment(\.uninstallerFeatureID) private var uninstallerFeatureID

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
                    .onValueChange(of: viewModel.highlightedID) { id in
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
            let advice = viewModel.advice(for: node)
            DiskMapItemRow(
                node: node,
                share: share(of: node.size, in: folder),
                color: SegmentPalette.color(forBranch: index),
                advice: advice,
                isSelected: viewModel.isSelected(node),
                isHighlighted: viewModel.highlightedID == node.id,
                canOpen: viewModel.canOpen(node),
                canShowInUninstaller: advice == .useUninstaller && uninstallerFeatureID != nil,
                theme: theme,
                onToggle: { viewModel.toggle(node) },
                onOpen: { viewModel.open(node) },
                onShowInUninstaller: { showInUninstaller(node) }
            )
            .equatable()
            .id(node.id)
            .onHover { inside in
                if inside { viewModel.highlightedID = node.id }
            }
        }
        if let other = folder.otherItems {
            OtherItemsRow(itemCount: other.itemCount, size: other.size, share: share(of: other.size, in: folder))
        }
    }

    private func showInUninstaller(_ app: DiskNode) {
        guard let uninstallerFeatureID else { return }
        openFeature(uninstallerFeatureID, showing: app.url)
    }

    private func share(of size: Int64, in folder: DiskNode) -> Double {
        folder.size > 0 ? Double(size) / Double(folder.size) : 0
    }
}
