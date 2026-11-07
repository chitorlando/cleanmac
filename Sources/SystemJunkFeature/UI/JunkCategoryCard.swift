import CleanMacUI
import SwiftUI

/// Expandable card for one category with its items.
struct JunkCategoryCard: View {
    let result: CategoryScanResult
    let viewModel: SystemJunkViewModel
    let theme: FeatureTheme
    @Binding var isExpanded: Bool

    var body: some View {
        GlassCard {
            VStack(spacing: 0) {
                header
                if isExpanded {
                    Divider().padding(.vertical, 12)
                    itemList
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            TriStateCheckbox(
                state: CheckState(viewModel.selectionState(of: result)),
                tint: theme.primary
            ) { viewModel.toggle(result) }

            Image(systemName: result.category.symbolName)
                .font(.title2)
                .foregroundStyle(theme.gradient)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.category.title).font(.headline)
                Text(result.category.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(result.totalSize.formattedByteCount)
                .font(.headline.monospacedDigit())

            expandButton
        }
    }

    private var expandButton: some View {
        Button {
            withAnimation(.snappy) { isExpanded.toggle() }
        } label: {
            Image(systemName: "chevron.down")
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(expandButtonLabel)
    }

    private var expandButtonLabel: Text {
        isExpanded
            ? Text("Hide items", bundle: .module, comment: "Accessibility label of the button that collapses a category.")
            : Text("Show items", bundle: .module, comment: "Accessibility label of the button that expands a category.")
    }

    private var itemList: some View {
        LazyVStack(spacing: 8) {
            ForEach(result.items) { item in
                CleanableItemRow(
                    item: item,
                    isSelected: viewModel.isSelected(item),
                    tint: theme.primary
                ) { viewModel.toggle(item) }
            }
        }
    }
}
