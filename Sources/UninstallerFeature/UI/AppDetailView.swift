import CleanMacUI
import SwiftUI

/// Everything that belongs to the focused app, grouped by kind.
struct AppDetailView: View {
    let app: InstalledApp
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            AppDetailHeader(app: app, theme: theme)

            if viewModel.isRunning(app) {
                RunningAppNotice(isQuitting: viewModel.isQuitting(app)) {
                    Task { await viewModel.quit(app) }
                }
            }

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(AppItemSection.sections(of: app)) { section in
                        AppItemSectionView(section: section, viewModel: viewModel, theme: theme)
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}
