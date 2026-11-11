import CleanMacUI
import SwiftUI

/// Size range of the files. Only one range can be chosen.
struct LargeFileSizeFilter: View {
    @Binding var sizeBucket: SizeBucket?
    /// Ranges worth offering, which depend on the smallest size the scan looks for.
    let buckets: [SizeBucket]
    let minimumSize: Int64
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        FilterSection(
            title: Text("Size", bundle: .module, comment: "Sort option and filter title: how much space a file takes up."),
            anyTitle: Text("Any Size", bundle: .module, comment: "Filter option that shows files of every size."),
            isAnySelected: sizeBucket == nil,
            theme: theme,
            onSelectAny: { sizeBucket = nil }
        ) {
            VStack(spacing: 1) {
                ForEach(buckets, id: \.self) { bucket in
                    FilterOptionRow(
                        title: bucket.title(forMinimumSize: minimumSize),
                        count: counts.count(of: bucket),
                        isSelected: sizeBucket == bucket,
                        theme: theme
                    ) { sizeBucket = sizeBucket == bucket ? nil : bucket }
                }
            }
        }
    }
}
