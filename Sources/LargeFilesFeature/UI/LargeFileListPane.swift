import CleanMacUI
import SwiftUI

/// Search, ordering, "select all" and the filtered list of files.
struct LargeFileListPane: View {
    @ObservedObject var viewModel: LargeFilesViewModel
    let theme: FeatureTheme

    var body: some View {
        let files = viewModel.visibleFiles
        GlassCard {
            VStack(spacing: 12) {
                LargeFileListToolbar(viewModel: viewModel, theme: theme)
                Divider()
                if files.isEmpty {
                    NoMatchingFilesView(theme: theme) { viewModel.filter = LargeFileFilter() }
                } else {
                    LargeFileList(files: files, viewModel: viewModel, theme: theme)
                }
            }
        }
    }
}
