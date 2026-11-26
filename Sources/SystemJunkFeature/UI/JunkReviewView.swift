import AppKit
import CleanMacUI
import SwiftUI

/// List of findings where the user decides what to remove, and confirms it before it's removed.
/// Emptying the Trash can't be undone, so it has its own question, which also tells what else
/// goes to the Trash afterwards.
///
/// The caches an open browser is using are locked. Which browsers are open is checked again
/// whenever an app opens or quits, since the user quits them outside CleanMac.
struct JunkReviewView: View {
    @ObservedObject var viewModel: SystemJunkViewModel
    let theme: FeatureTheme

    @State private var expandedCategoryIDs: Set<JunkCategory.ID> = []

    var body: some View {
        VStack(spacing: 24) {
            JunkReviewHeader(foundSize: viewModel.foundSize, theme: theme)
            categoryList
            ActionBar(
                secondaryTitle: Text("Scan Again", bundle: .module, comment: "Button that repeats the junk scan."),
                primaryTitle: cleanTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme,
                onSecondary: { viewModel.startScan() },
                onPrimary: { viewModel.requestClean() }
            )
            .emptyTrashConfirmation(
                trashSize: viewModel.binsToEmpty.totalSize,
                itemsToMove: viewModel.itemsToMove.count,
                sizeToMove: viewModel.itemsToMove.totalSize,
                isPresented: viewModel.isConfirmingClean && viewModel.emptiesTrash,
                onConfirm: { viewModel.clean() },
                onDismiss: { viewModel.cancelClean() }
            )
        }
        .frame(maxWidth: 760)
        .trashConfirmation(
            itemCount: viewModel.selectedCount,
            size: viewModel.selectedSize,
            isPresented: viewModel.isConfirmingClean && !viewModel.emptiesTrash,
            onConfirm: { viewModel.clean() },
            onDismiss: { viewModel.cancelClean() }
        )
        .onAppear { viewModel.refreshOpenApps() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            viewModel.refreshOpenApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            viewModel.refreshOpenApps()
        }
    }

    private var cleanTitle: Text {
        Text(
            "Clean \(viewModel.selectedSize.formattedByteCount)",
            bundle: .module,
            comment: "Button that removes the selected junk. The argument is a size, such as “1.2 GB”."
        )
    }

    private var categoryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.results) { result in
                    JunkCategoryCard(
                        result: result,
                        viewModel: viewModel,
                        theme: theme,
                        isExpanded: binding(for: result.id)
                    )
                }
            }
        }
        .scrollIndicators(.never)
    }

    private func binding(for id: JunkCategory.ID) -> Binding<Bool> {
        Binding(
            get: { expandedCategoryIDs.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategoryIDs.insert(id)
                } else {
                    expandedCategoryIDs.remove(id)
                }
            }
        )
    }
}
