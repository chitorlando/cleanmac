import Foundation

/// Narrows the list of large files by kind, age, size and name.
///
/// Every condition left unset lets all files through.
public struct LargeFileFilter: Equatable, Sendable {
    /// Kinds to show. Empty means every kind.
    public var kinds: Set<FileKind>
    public var ageBucket: AgeBucket?
    public var sizeBucket: SizeBucket?
    /// Text the file name must contain, ignoring case and accents.
    public var searchText: String

    public init(
        kinds: Set<FileKind> = [],
        ageBucket: AgeBucket? = nil,
        sizeBucket: SizeBucket? = nil,
        searchText: String = ""
    ) {
        self.kinds = kinds
        self.ageBucket = ageBucket
        self.sizeBucket = sizeBucket
        self.searchText = searchText
    }

    /// `now` and `calendar` decide which age bucket each file falls in.
    public func matches(_ file: LargeFile, now: Date, calendar: Calendar = .current) -> Bool {
        let ages = AgeBucketBoundaries(now: now, calendar: calendar)
        return matches(file, ages: ages, search: LargeFileNameSearch(searchText))
    }

    /// Like `matches(_:now:calendar:)`, with the age buckets and the search already worked out,
    /// for passes over many files.
    func matches(_ file: LargeFile, ages: AgeBucketBoundaries, search: LargeFileNameSearch) -> Bool {
        matchesKind(file)
            && matchesAge(file, ages: ages)
            && matchesSize(file)
            && search.matches(file)
    }

    public func apply(to files: [LargeFile], now: Date, calendar: Calendar = .current) -> [LargeFile] {
        let ages = AgeBucketBoundaries(now: now, calendar: calendar)
        let search = LargeFileNameSearch(searchText)
        return files.filter { matches($0, ages: ages, search: search) }
    }

    /// Kinds worth offering as options, in catalog order: those of `files`, plus the chosen
    /// ones even when no file is left of them, so they stay visible and can be cleared.
    public func kindOptions(for files: [LargeFile]) -> [FileKind] {
        let offered = kinds.union(files.map(\.kind))
        return FileKind.allCases.filter(offered.contains)
    }

    private func matchesKind(_ file: LargeFile) -> Bool {
        kinds.isEmpty || kinds.contains(file.kind)
    }

    private func matchesAge(_ file: LargeFile, ages: AgeBucketBoundaries) -> Bool {
        guard let ageBucket else { return true }
        return ages.bucket(forLastAccessDate: file.lastAccessDate) == ageBucket
    }

    private func matchesSize(_ file: LargeFile) -> Bool {
        guard let sizeBucket else { return true }
        return SizeBucket(size: file.item.size) == sizeBucket
    }
}
