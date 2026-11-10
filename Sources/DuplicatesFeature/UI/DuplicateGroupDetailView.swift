import CleanMacUI
import SwiftUI

/// Every copy of the focused group, with the one suggested to keep and the clones flagged.
struct DuplicateGroupDetailView: View {
    let group: DuplicateGroup
    let viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DuplicateGroupDetailHeader(group: group, theme: theme)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(group.files) { file in
                        DuplicateCopyRow(file: file, group: group, viewModel: viewModel, theme: theme)
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}
