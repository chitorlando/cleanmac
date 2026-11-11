import CleanMacUI
import SwiftUI

/// Column of filters by kind, last use and size, each option with its number of files.
///
/// Compact enough to fit the smallest window without scrolling. When space still runs
/// short, only the kinds scroll, so the chosen age and size always stay in view.
struct LargeFileFilterPanel: View {
    @Binding var filter: LargeFileFilter
    let kindOptions: [FileKind]
    let sizeBuckets: [SizeBucket]
    let minimumSize: Int64
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                LargeFileKindFilter(kinds: $filter.kinds, options: kindOptions, counts: counts, theme: theme)
                LargeFileAgeFilter(ageBucket: $filter.ageBucket, counts: counts, theme: theme)
                LargeFileSizeFilter(
                    sizeBucket: $filter.sizeBucket,
                    buckets: sizeBuckets,
                    minimumSize: minimumSize,
                    counts: counts,
                    theme: theme
                )
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
