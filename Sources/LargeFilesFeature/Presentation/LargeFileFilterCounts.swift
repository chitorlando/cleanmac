import Foundation

/// How many files each filter option would show, to display next to the option.
///
/// Each group ignores its own condition and applies the rest of the filter,
/// so choosing videos still tells how many images there are.
public struct LargeFileFilterCounts: Equatable, Sendable {
    public let kinds: [FileKind: Int]
    public let ages: [AgeBucket: Int]
    public let sizes: [SizeBucket: Int]

    public init(files: [LargeFile], filter: LargeFileFilter, now: Date, calendar: Calendar = .current) {
        let boundaries = AgeBucketBoundaries(now: now, calendar: calendar)
        self = FilteredLargeFiles(files: files, filter: filter, ages: boundaries).counts
    }

    init(kinds: [FileKind: Int], ages: [AgeBucket: Int], sizes: [SizeBucket: Int]) {
        self.kinds = kinds
        self.ages = ages
        self.sizes = sizes
    }

    public func count(of kind: FileKind) -> Int { kinds[kind] ?? 0 }
    public func count(of age: AgeBucket) -> Int { ages[age] ?? 0 }
    public func count(of size: SizeBucket) -> Int { sizes[size] ?? 0 }
}
