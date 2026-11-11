import CleanMacUI
import SwiftUI

/// The items of one scope, with a checkbox for the whole section when they can be removed.
struct LoginItemSectionCard: View {
    let section: LoginItemSection
    @ObservedObject var viewModel: LoginItemsViewModel
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                header
                Divider()
                LazyVStack(spacing: 10) {
                    ForEach(section.items) { item in
                        LoginItemRow(
                            item: item,
                            isSelected: viewModel.isSelected(item),
                            theme: theme
                        ) { viewModel.toggle(item) }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if section.scope == .currentUser {
                TriStateCheckbox(
                    state: CheckState(viewModel.selectionState(of: section)),
                    tint: theme.primary,
                    label: section.scope.title
                ) { viewModel.toggleAll(in: section) }
            }
            VStack(alignment: .leading, spacing: 2) {
                section.scope.title
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                section.scope.summary
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
