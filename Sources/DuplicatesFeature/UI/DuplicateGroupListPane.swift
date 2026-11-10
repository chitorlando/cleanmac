import CleanMacUI
import SwiftUI

/// Left pane: the searchable, sorted list of groups of duplicates.
struct DuplicateGroupListPane: View {
    @ObservedObject var viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                DuplicateGroupListControls(viewModel: viewModel, theme: theme)
                Divider()
                list
            }
        }
    }

    @ViewBuilder
    private var list: some View {
        let groups = viewModel.visibleGroups
        if groups.isEmpty {
            DuplicateGroupListEmptyView(searchText: viewModel.query.searchText)
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(groups) { group in
                        DuplicateGroupRow(group: group, viewModel: viewModel, theme: theme)
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}
