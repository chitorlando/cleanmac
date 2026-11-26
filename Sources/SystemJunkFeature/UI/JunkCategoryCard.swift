import CleanMacCore
import CleanMacUI
import SwiftUI

/// Expandable card for one category with its items. The ones an open browser is using are locked.
struct JunkCategoryCard: View {
    let result: CategoryScanResult
    @ObservedObject var viewModel: SystemJunkViewModel
    let theme: FeatureTheme
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassCard {
            VStack(spacing: 0) {
                header
                if !lockingAppNames.isEmpty {
                    WarningNotice(lockedNotice).padding(.top, 12)
                }
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
                tint: theme.primary,
                label: Text(result.category.title)
            ) { viewModel.toggle(result) }
            .disabled(!viewModel.canSelectItems(of: result))

            Image(systemName: result.category.symbolName)
                .font(.title2)
                .foregroundStyle(theme.gradient)
                .frame(width: 32)
                .accessibilityHidden(true)

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
            withAnimation(reduceMotion ? nil : .snappy) { isExpanded.toggle() }
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

    /// The open browsers that lock items of the category, such as "Firefox" and "Vivaldi".
    private var lockingAppNames: [String] {
        viewModel.openApps(lockingItemsOf: result).map(\.name)
    }

    private var lockedNotice: Text {
        Text(
            "Caches in use by \(lockingAppNames.formatted(.list(type: .and))) stay locked until you quit.",
            bundle: .module,
            comment: "Notice on a junk category with caches that can't be cleaned while a browser is open. The argument is the open browsers."
        )
    }

    private var itemList: some View {
        LazyVStack(spacing: 8) {
            ForEach(result.items) { item in
                CleanableItemRow(
                    item: item,
                    isSelected: viewModel.isSelected(item),
                    isToggleEnabled: viewModel.canSelect(item),
                    tint: theme.primary
                ) { viewModel.toggle(item) }
            }
        }
    }
}
