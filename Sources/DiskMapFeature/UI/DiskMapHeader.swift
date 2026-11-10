import CleanMacUI
import SwiftUI

/// Breadcrumbs of the focused folder, with its size and number of files.
struct DiskMapHeader: View {
    let viewModel: DiskMapViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BreadcrumbBar(
                breadcrumbs: viewModel.breadcrumbs,
                canGoUp: viewModel.canGoUp,
                onGoUp: { viewModel.goUp() },
                onSelect: { viewModel.goToBreadcrumb(at: $0) }
            )
            if let folder = viewModel.focusedFolder {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(folder.size.formattedByteCount)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.gradient)
                    Text(
                        "in \(folder.fileCount) files",
                        bundle: .module,
                        comment: "Shown after the size of the focused folder, as in “120 GB in 3,000 files”. The argument is the number of files."
                    )
                    .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
