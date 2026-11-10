import CleanMacUI
import SwiftUI

/// Filters on the left and the list of files on the right, where the user picks what to remove.
struct LargeFilesReviewView: View {
    @Bindable var viewModel: LargeFilesViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 20) {
            LargeFilesReviewHeader(foundSize: viewModel.foundSize, foundCount: viewModel.foundCount, theme: theme)
            if viewModel.wasStoppedEarly {
                WarningNotice(Text(
                    "The scan was stopped, so these results are incomplete.",
                    bundle: .module,
                    comment: "Warning shown above partial results after the user stopped the scan."
                ))
            }
            HStack(alignment: .top, spacing: 20) {
                LargeFileFilterPanel(
                    filter: $viewModel.filter,
                    kindOptions: viewModel.kindOptions,
                    counts: viewModel.filterCounts,
                    theme: theme
                )
                .frame(width: 240)
                LargeFileListPane(viewModel: viewModel, theme: theme)
            }
            ActionBar(
                secondaryTitle: Text("Scan Again", bundle: .module, comment: "Button that repeats the large files scan."),
                primaryTitle: removeTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme,
                onSecondary: { viewModel.startScan() },
                onPrimary: { viewModel.remove() }
            )
        }
        .frame(maxWidth: 1100)
    }

    private var removeTitle: Text {
        guard viewModel.hasSelection else {
            return Text("Move to Trash", bundle: .module, comment: "Disabled button to remove files, shown while nothing is selected.")
        }
        return Text(
            "Move \(viewModel.selectedCount) Files to Trash (\(viewModel.selectedSize.formattedByteCount))",
            bundle: .module,
            comment: "Button that moves the selected files to the Trash. The arguments are the number of files and their size, such as “1.2 GB”."
        )
    }
}
