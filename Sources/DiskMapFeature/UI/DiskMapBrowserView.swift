import CleanMacUI
import SwiftUI

/// The map: breadcrumbs on top, the rings with the list of items beside them, and the bar
/// that moves the selection to the Trash after asking.
///
/// Keys: ↑ and ↓ move through the items, → or Return opens a folder, ← or ⌘↑ goes up.
/// While something is selected, Return belongs to the bar's main button, which only asks.
struct DiskMapBrowserView: View {
    let viewModel: DiskMapViewModel
    let theme: FeatureTheme

    @State private var isConfirmingRemoval = false
    @FocusState private var hasKeyboardFocus: Bool

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
                theme: theme,
                onSecondary: { viewModel.startScan() },
                onPrimary: { isConfirmingRemoval = true }
            )
        }
        .frame(maxWidth: 1100)
        .focusable()
        .focused($hasKeyboardFocus)
        .focusEffectDisabled()
        .onAppear { hasKeyboardFocus = true }
        .onKeyPress(.downArrow) { viewModel.moveHighlight(by: 1); return .handled }
        .onKeyPress(.upArrow) { viewModel.moveHighlight(by: -1); return .handled }
        .onKeyPress(.rightArrow) { viewModel.openHighlighted(); return .handled }
        .onKeyPress(.return) { viewModel.openHighlighted(); return .handled }
        .onKeyPress(.leftArrow) { viewModel.goUp(); return .handled }
        .confirmationDialog(confirmationTitle, isPresented: $isConfirmingRemoval) {
            Button(role: .destructive) {
                viewModel.remove()
            } label: {
                Text("Move to Trash", bundle: .module, comment: "Button that confirms moving the selected items to the Trash.")
            }
        } message: {
            Text(
                "They take up \(viewModel.selectedSize.formattedByteCount). You can put them back from the Trash.",
                bundle: .module,
                comment: "Message when confirming a removal from the disk map. The argument is a size, such as “1.2 GB”."
            )
        }
    }

    @ViewBuilder
    private var chart: some View {
        if let folder = viewModel.focusedFolder {
            SunburstChart(
                folder: folder,
                segments: viewModel.segments,
                ringCount: SunburstLayout.defaultRingCount,
                highlightedBranch: highlightedBranch,
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

    private var highlightedBranch: Int? {
        viewModel.items.firstIndex { $0.id == viewModel.highlightedID }
    }

    private var confirmationTitle: Text {
        Text(
            "Move \(viewModel.selectedCount) items to the Trash?",
            bundle: .module,
            comment: "Title when confirming a removal from the disk map. The argument is the number of items."
        )
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
