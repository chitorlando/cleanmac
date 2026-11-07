import CleanMacUI
import SwiftUI

/// Column of filters by kind, last use and size, each option with its number of files.
struct LargeFileFilterPanel: View {
    @Binding var filter: LargeFileFilter
    let counts: LargeFileFilterCounts
    let theme: FeatureTheme

    var body: some View {
        GlassCard {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    LargeFileKindFilter(kinds: $filter.kinds, counts: counts, theme: theme)
                    LargeFileAgeFilter(ageBucket: $filter.ageBucket, counts: counts, theme: theme)
                    LargeFileSizeFilter(sizeBucket: $filter.sizeBucket, counts: counts, theme: theme)
                }
            }
        }
    }
}
