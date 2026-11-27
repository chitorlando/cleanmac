import CleanMacUI
import SwiftUI

/// Scrollable list of the visible files.
struct LargeFileList: View {
    let files: [LargeFile]
    @ObservedObject var viewModel: LargeFilesViewModel
    let theme: FeatureTheme

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(files.enumerated()), id: \.element.id) { order, file in
                    LargeFileRow(
                        file: file,
                        isSelected: viewModel.isSelected(file),
                        theme: theme
                    ) { viewModel.toggle(file) }
                    .staggeredEntrance(order: order)
                }
            }
            .revealsRowsInTurn()
            .padding(.trailing, 14)
        }
    }
}
