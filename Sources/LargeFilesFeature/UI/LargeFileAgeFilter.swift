import CleanMacUI
import SwiftUI

/// How long ago the files were last used. Only one range can be chosen.
struct LargeFileAgeFilter: View {
    @Binding var ageBucket: AgeBucket?
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        FilterSection(
            title: Text("Last Used", bundle: .module, comment: "Sort option and filter title: when a file was last opened."),
            anyTitle: Text("Any Time", bundle: .module, comment: "Filter option that shows files regardless of when they were last used."),
            isAnySelected: ageBucket == nil,
            theme: theme,
            onSelectAny: { ageBucket = nil }
        ) {
            VStack(spacing: 1) {
                ForEach(AgeBucket.allCases, id: \.self) { bucket in
                    FilterOptionRow(
                        title: bucket.title,
                        count: counts.count(of: bucket),
                        isSelected: ageBucket == bucket,
                        theme: theme
                    ) { ageBucket = ageBucket == bucket ? nil : bucket }
                }
            }
        }
    }
}
