import CleanMacUI
import SwiftUI

/// Size range of the files. Only one range can be chosen.
struct LargeFileSizeFilter: View {
    @Binding var sizeBucket: SizeBucket?
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        FilterSection(title: Text("Size", bundle: .module, comment: "Sort option and filter title: how much space a file takes up.")) {
            FilterOptionRow(
                title: String(localized: "Any Size", bundle: .module, comment: "Filter option that shows files of every size."),
                count: nil,
                isSelected: sizeBucket == nil,
                theme: theme
            ) { sizeBucket = nil }
            ForEach(SizeBucket.allCases, id: \.self) { bucket in
                FilterOptionRow(
                    title: bucket.title,
                    count: counts.count(of: bucket),
                    isSelected: sizeBucket == bucket,
                    theme: theme
                ) { sizeBucket = sizeBucket == bucket ? nil : bucket }
            }
        }
    }
}
