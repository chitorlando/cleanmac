import CleanMacUI
import SwiftUI

/// The map: breadcrumbs on top, the rings with the list of items beside them, and the bar
/// that moves the selection to the Trash after asking.
///
/// Keys: ↑ and ↓ move through the items, → or Return opens a folder or shows an app in the
/// Uninstaller, ← or ⌘↑ goes up.
/// Return keeps opening folders while something is selected: the bar's main button only
/// responds to a click, so a key press never starts a removal.
struct DiskMapBrowserView: View {
    @ObservedObject var viewModel: DiskMapViewModel
    let theme: FeatureTheme

    @State private var isConfirmingRemoval = false

    var body: some View {
        VStack(spacing: 16) {
            DiskMapHeader(viewModel: viewModel, theme: theme)
            HStack(alignment: .center, spacing: 20) {
                chart
                    .frame(minWidth: 200, maxWidth: .infinity, maxHeight: .infinity)
                DiskMapItemList(viewModel: viewModel, theme: theme)
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 360)
            }
            ActionBar(
                secondaryTitle: Text("Scan Again", bundle: .module, comment: "Button that measures the home folder again."),
                primaryTitle: removeTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                isPrimaryDefaultAction: false,
                theme: theme,
                onSecondary: { viewModel.startScan() },
                onPrimary: { isConfirmingRemoval = true }
            )
        }
        .frame(maxWidth: 1100)
        .modifier(DiskMapKeyboardNavigation(viewModel: viewModel))
        .trashConfirmation(
            itemCount: viewModel.selectedCount,
            size: viewModel.selectedSize,
            isPresented: isConfirmingRemoval,
            onConfirm: { viewModel.remove() },
            onDismiss: { isConfirmingRemoval = false }
        )
    }

    @ViewBuilder
    private var chart: some View {
        if let folder = viewModel.focusedFolder {
            // Laid out here, once per folder, and not each time the highlight moves.
            let segments = viewModel.segments
            DiskMapHighlightReader(highlight: viewModel.highlight) { highlightedID in
                SunburstChart(
                    folder: folder,
                    segments: segments,
                    ringCount: SunburstLayout.defaultRingCount,
                    highlightedBranch: folder.children.firstIndex { $0.id == highlightedID },
                    onPoint: { segment in
                        if let branch = segment?.branch, viewModel.items.indices.contains(branch) {
                            viewModel.highlightedID = viewModel.items[branch].id
                        }
                    },
                    onOpen: { segment in
                        guard viewModel.items.indices.contains(segment.branch) else { return }
                        viewModel.open(viewModel.items[segment.branch])
                    },
                    onCenter: { viewModel.goUp() }
                )
            }
        }
    }

    private var removeTitle: Text {
        guard viewModel.hasSelection else {
            return Text("Move to Trash", bundle: .module, comment: "Button that confirms moving the selected items to the Trash.")
        }
        return Text(
            "Move \(viewModel.selectedCount) Items to Trash (\(viewModel.selectedSize.formattedByteCount))",
            bundle: .module,
            comment: "Button that moves the items selected in the disk map to the Trash. The arguments are the number of items and their size, such as “1.2 GB”."
        )
    }
}
