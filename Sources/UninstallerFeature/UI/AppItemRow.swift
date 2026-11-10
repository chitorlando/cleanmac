import CleanMacCore
import CleanMacUI
import SwiftUI

/// One file of the focused app, flagged when another copy of the app shares it.
struct AppItemRow: View {
    let item: CleanableItem
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CleanableItemRow(
                item: item,
                isSelected: viewModel.isSelected(item),
                isToggleEnabled: viewModel.canSelect(item),
                tint: theme.primary
            ) { viewModel.toggle(item) }

            if viewModel.isShared(item) {
                SharedLeftoverBadge()
                    .padding(.leading, 40)
            }
        }
    }
}
