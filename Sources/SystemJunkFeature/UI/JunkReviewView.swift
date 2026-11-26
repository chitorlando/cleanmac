import CleanMacUI
import SwiftUI

/// List of findings where the user decides what to remove, and confirms it before it's removed.
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
        }
        .frame(maxWidth: 760)
        .trashConfirmation(
            itemCount: viewModel.selectedCount,
            size: viewModel.selectedSize,
            isPresented: viewModel.isConfirmingClean,
            onConfirm: { viewModel.clean() },
            onDismiss: { viewModel.cancelClean() }
        )
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
