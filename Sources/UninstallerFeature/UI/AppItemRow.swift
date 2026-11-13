import CleanMacCore
import CleanMacUI
import SwiftUI

/// One file of the focused app, flagged when another copy of the app shares it, or when
/// macOS protects it. Protected items stay selectable: Full Disk Access lets CleanMac move them.
struct AppItemRow: View {
    let item: CleanableItem
    /// macOS protects the item, as it does apps' containers.
    var isProtected = false
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

            if viewModel.isShared(item) || isProtected {
                HStack(spacing: 6) {
                    if viewModel.isShared(item) {
                        SharedLeftoverBadge()
                    }
                    if isProtected {
                        ProtectedLeftoverBadge()
                    }
                }
                .padding(.leading, 40)
            }
        }
    }
}
