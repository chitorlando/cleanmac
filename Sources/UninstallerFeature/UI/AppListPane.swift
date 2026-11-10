import CleanMacUI
import SwiftUI

/// Left pane: the filtered and sorted list of installed apps.
struct AppListPane: View {
    @ObservedObject var viewModel: UninstallerViewModel
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                AppListControls(viewModel: viewModel, theme: theme)
                Divider()
                list
            }
        }
    }

    @ViewBuilder
    private var list: some View {
        let apps = viewModel.visibleApps
        if apps.isEmpty {
            AppListEmptyView(searchText: viewModel.query.searchText)
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(apps) { app in
                        AppListRow(app: app, viewModel: viewModel, theme: theme)
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}
