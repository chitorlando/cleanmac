import CleanMacUI
import SwiftUI

/// Kinds to show. Several can be chosen; none means every kind.
///
/// Only the kinds offered are listed, and they're the one part of the column that
/// scrolls when space runs short.
struct LargeFileKindFilter: View {
    @Binding var kinds: Set<FileKind>
    let options: [FileKind]
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        FilterSection(
            title: Text("Kind", bundle: .module, comment: "Title of the file kind filters."),
            anyTitle: Text("All Kinds", bundle: .module, comment: "Filter option that shows files of every kind."),
            isAnySelected: kinds.isEmpty,
            theme: theme,
            onSelectAny: { kinds = [] }
        ) {
            OverflowScrollView(revealedID: options.first(where: kinds.contains)) {
                VStack(spacing: 1) {
                    ForEach(options, id: \.self) { kind in
                        FilterOptionRow(
                            title: kind.title,
                            symbolName: kind.symbolName,
                            count: counts.count(of: kind),
                            isSelected: kinds.contains(kind),
                            theme: theme
                        ) { toggle(kind) }
                        .id(kind)
                    }
                }
            }
        }
    }

    private func toggle(_ kind: FileKind) {
        if kinds.remove(kind) == nil {
            kinds.insert(kind)
        }
    }
}
