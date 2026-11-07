import CleanMacUI
import SwiftUI

/// Kinds to show. Several can be chosen; none means every kind.
struct LargeFileKindFilter: View {
    @Binding var kinds: Set<FileKind>
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        FilterSection(title: Text("Kind", bundle: .module, comment: "Title of the file kind filters.")) {
            FilterOptionRow(
                title: String(localized: "All Kinds", bundle: .module, comment: "Filter option that shows files of every kind."),
                symbolName: "square.grid.2x2.fill",
                count: nil,
                isSelected: kinds.isEmpty,
                theme: theme
            ) { kinds = [] }
            ForEach(FileKind.allCases, id: \.self) { kind in
                FilterOptionRow(
                    title: kind.title,
                    symbolName: kind.symbolName,
                    count: counts.count(of: kind),
                    isSelected: kinds.contains(kind),
                    theme: theme
                ) { toggle(kind) }
            }
        }
    }

    private func toggle(_ kind: FileKind) {
        if kinds.remove(kind) == nil {
            kinds.insert(kind)
        }
    }
}
