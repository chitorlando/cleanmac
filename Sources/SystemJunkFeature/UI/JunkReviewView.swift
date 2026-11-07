import CleanMacUI
import SwiftUI

/// List of findings where the user decides what to remove.
struct JunkReviewView: View {
    let viewModel: SystemJunkViewModel
    let theme: FeatureTheme

    @State private var expandedCategoryIDs: Set<JunkCategory.ID> = []

    var body: some View {
        VStack(spacing: 24) {
            JunkReviewHeader(foundSize: viewModel.foundSize, theme: theme)
            categoryList
            JunkReviewActionBar(
                selectedSize: viewModel.selectedSize,
                canClean: viewModel.hasSelection,
                theme: theme,
                onRescan: { viewModel.startScan() },
                onClean: { viewModel.clean() }
            )
        }
        .frame(maxWidth: 760)
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
