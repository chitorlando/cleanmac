import CleanMacUI
import SwiftUI

/// A titled group of the focused app's items, such as its caches.
struct AppItemSectionView: View {
    let section: AppItemSection
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(section.category.title)
                    .font(.headline)
                Spacer()
                Text(section.totalSize.formattedByteCount)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ForEach(section.items) { item in
                AppItemRow(item: item, isProtected: section.category.isProtectedByMacOS, viewModel: viewModel, theme: theme)
            }
        }
    }
}
