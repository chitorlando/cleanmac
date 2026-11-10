import CleanMacUI
import SwiftUI

/// Groups of duplicates on the left and the copies of the focused group on the right,
/// where the user marks the copies to remove.
struct DuplicatesReviewView: View {
    let viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(spacing: 20) {
            DuplicatesReviewHeader(
                recoverableSize: viewModel.recoverableSize,
                groupCount: viewModel.groups.count,
                theme: theme
            )
            if viewModel.wasStoppedEarly {
                WarningNotice(Text(
                    "The scan was stopped, so these results are incomplete.",
                    bundle: .module,
                    comment: "Warning shown above partial results after the user stopped the scan."
                ))
            }
            HStack(alignment: .top, spacing: 16) {
                DuplicateGroupListPane(viewModel: viewModel, theme: theme)
                    .frame(minWidth: 300, idealWidth: 340, maxWidth: 340)
                DuplicateGroupDetailPane(viewModel: viewModel, theme: theme)
            }
            ActionBar(
                secondaryTitle: Text("Scan Again", bundle: .module, comment: "Button that repeats the duplicates scan."),
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
            return Text("Move to Trash", bundle: .module, comment: "Disabled button to remove copies, shown while nothing is selected.")
        }
        return Text(
            "Move to Trash (\(viewModel.selectedSize.formattedByteCount))",
            bundle: .module,
            comment: "Button that moves the selected copies to the Trash. The argument is the space it frees, such as “1.2 GB”."
        )
    }
}
