import CleanMacUI
import SwiftUI

/// The browsers with caches, where the user decides what to clear.
struct PrivacyReviewView: View {
    @ObservedObject var viewModel: PrivacyViewModel
    let theme: FeatureTheme

    @State private var expandedBrowserIDs: Set<BrowserCaches.ID> = []

    var body: some View {
        VStack(spacing: 24) {
            PrivacyReviewHeader(foundSize: viewModel.foundSize, theme: theme)
            browserList
            ActionBar(
                secondaryTitle: Text("Scan Again", bundle: .module, comment: "Button that repeats the browser caches scan."),
                primaryTitle: cleanTitle,
                isPrimaryEnabled: viewModel.hasSelection,
                theme: theme,
                onSecondary: { viewModel.startScan() },
                onPrimary: { viewModel.clean() }
            )
        }
        .frame(maxWidth: 760)
        .onAppear { viewModel.refreshRunningBrowsers() }
    }

    private var cleanTitle: Text {
        Text(
            "Clear \(viewModel.selectedSize.formattedByteCount)",
            bundle: .module,
            comment: "Button that clears the selected browser caches. The argument is a size, such as “1.2 GB”."
        )
    }

    private var browserList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.results) { browser in
                    BrowserCacheCard(browser: browser, viewModel: viewModel, theme: theme, isExpanded: binding(for: browser.id))
                }
            }
        }
        .scrollIndicators(.never)
    }

    private func binding(for id: BrowserCaches.ID) -> Binding<Bool> {
        Binding(
            get: { expandedBrowserIDs.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedBrowserIDs.insert(id)
                } else {
                    expandedBrowserIDs.remove(id)
                }
            }
        )
    }
}
