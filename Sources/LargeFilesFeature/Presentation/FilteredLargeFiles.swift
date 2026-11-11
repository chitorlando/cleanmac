/// The files a filter shows and how many files each of its options would show, worked out together.
///
/// The list and each group of counts apply nearly the same conditions, and searching the
/// name is by far the slowest. One pass checks each condition once per file, so a keystroke
/// in the search field looks at every name once instead of four times. The list and the
/// counts also come from the same files and age ranges, so they always agree.
struct FilteredLargeFiles: Sendable {
    /// Files that pass the filter, in the order they were given.
    let files: [LargeFile]
    let counts: LargeFileFilterCounts

    init(files: [LargeFile], filter: LargeFileFilter, ages: AgeBucketBoundaries) {
        let search = LargeFileNameSearch(filter.searchText)
        var matches: [LargeFile] = []
        var kindCounts: [FileKind: Int] = [:]
        var ageCounts: [AgeBucket: Int] = [:]
        var sizeCounts: [SizeBucket: Int] = [:]

        // Every count applies the search, so a file it leaves out counts nowhere.
        for file in files where search.matches(file) {
            let age = ages.bucket(forLastAccessDate: file.lastAccessDate)
            let size = SizeBucket(size: file.item.size)
            let isKindAllowed = filter.allowsKind(file.kind)
            let isAgeAllowed = filter.allowsAge(age)
            let isSizeAllowed = filter.allowsSize(size)

            // Each group ignores its own condition (see `LargeFileFilterCounts`).
            if isAgeAllowed, isSizeAllowed {
                kindCounts[file.kind, default: 0] += 1
            }
            if isKindAllowed, isSizeAllowed, let age {
                ageCounts[age, default: 0] += 1
            }
            if isKindAllowed, isAgeAllowed {
                sizeCounts[size, default: 0] += 1
            }
            if isKindAllowed, isAgeAllowed, isSizeAllowed {
                matches.append(file)
            }
        }

        self.files = matches
        counts = LargeFileFilterCounts(kinds: kindCounts, ages: ageCounts, sizes: sizeCounts)
    }
}
