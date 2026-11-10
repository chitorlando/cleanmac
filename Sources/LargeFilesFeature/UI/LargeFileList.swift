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
                ForEach(files) { file in
                    LargeFileRow(
                        file: file,
                        isSelected: viewModel.isSelected(file),
                        theme: theme
                    ) { viewModel.toggle(file) }
                }
            }
            .padding(.trailing, 14)
        }
    }
}
