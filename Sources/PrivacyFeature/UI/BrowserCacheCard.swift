import CleanMacCore
import CleanMacUI
import SwiftUI

/// Expandable card with a browser's caches, locked while the browser is open.
struct BrowserCacheCard: View {
    let browser: BrowserCaches
    @ObservedObject var viewModel: PrivacyViewModel
    let theme: FeatureTheme
    @Binding var isExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GlassCard {
            VStack(spacing: 0) {
                header
                if viewModel.isRunning(browser) {
                    OpenBrowserNotice(
                        appNames: viewModel.openApps(of: browser).map(\.name),
                        isQuitting: viewModel.isQuitting(browser)
                    ) {
                        Task { await viewModel.quit(browser) }
                    }
                    .padding(.top, 12)
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
                state: CheckState(viewModel.selectionState(of: browser)),
                tint: theme.primary,
                label: Text(verbatim: browser.name)
            ) { viewModel.toggle(browser) }
            .disabled(!viewModel.canSelect(browser))

            AppIconView(url: browser.appURL, size: 32)

            Text(verbatim: browser.name).font(.headline)

            Spacer()

            Text(browser.totalSize.formattedByteCount)
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
            ? Text("Hide caches", bundle: .module, comment: "Accessibility label of the button that collapses a browser.")
            : Text("Show caches", bundle: .module, comment: "Accessibility label of the button that expands a browser.")
    }

    /// Says what a service worker folder is, under its row, since its name doesn't.
    private var siteDataNote: some View {
        Text(
            "Service worker data that websites and web apps stored to work offline. Not selected by default: clearing it can make them start over.",
            bundle: .module,
            comment: "Note under a browser's service worker folder, which is listed but not selected by default."
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.leading, 40)
    }

    private var itemList: some View {
        LazyVStack(spacing: 8) {
            ForEach(browser.items) { item in
                VStack(alignment: .leading, spacing: 2) {
                    CleanableItemRow(
                        item: item,
                        isSelected: viewModel.isSelected(item, of: browser),
                        isToggleEnabled: viewModel.canSelect(browser),
                        tint: theme.primary
                    ) { viewModel.toggle(item, of: browser) }
                    if browser.holdsSiteData(item) {
                        siteDataNote
                    }
                }
            }
        }
    }
}
