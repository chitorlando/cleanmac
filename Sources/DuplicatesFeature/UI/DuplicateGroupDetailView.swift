import CleanMacUI
import SwiftUI

/// Every copy of the focused group, with the one suggested to keep and the clones flagged.
struct DuplicateGroupDetailView: View {
    let group: DuplicateGroup
    @ObservedObject var viewModel: DuplicatesViewModel
    let theme: FeatureTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            DuplicateGroupDetailHeader(group: group, theme: theme)

            if group.isMadeOfClones {
                CloneGroupNotice()
            }

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(group.files) { file in
                        DuplicateCopyRow(
                            file: file,
                            isSelected: viewModel.isSelected(file),
                            canSelect: viewModel.canSelect(file, in: group),
                            isSuggestedKeeper: viewModel.isSuggestedKeeper(file, in: group),
                            isClone: group.isClone(file),
                            theme: theme,
                            onToggle: { viewModel.toggle(file, in: group) }
                        )
                        .equatable()
                    }
                }
            }
            .scrollIndicators(.never)
        }
    }
}
