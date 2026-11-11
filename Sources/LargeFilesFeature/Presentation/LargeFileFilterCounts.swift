import Foundation

/// How many files each filter option would show, to display next to the option.
///
/// Each group ignores its own condition and applies the rest of the filter,
/// so choosing videos still tells how many images there are.
public struct LargeFileFilterCounts: Equatable, Sendable {
    public private(set) var kinds: [FileKind: Int] = [:]
    public private(set) var ages: [AgeBucket: Int] = [:]
    public private(set) var sizes: [SizeBucket: Int] = [:]

    public init(files: [LargeFile], filter: LargeFileFilter, now: Date, calendar: Calendar = .current) {
        var anyKind = filter
        anyKind.kinds = []
        var anyAge = filter
        anyAge.ageBucket = nil
        var anySize = filter
        anySize.sizeBucket = nil
        let boundaries = AgeBucketBoundaries(now: now, calendar: calendar)
        let search = LargeFileNameSearch(filter.searchText)

        for file in files {
            if anyKind.matches(file, ages: boundaries, search: search) {
                kinds[file.kind, default: 0] += 1
            }
            if anyAge.matches(file, ages: boundaries, search: search),
               let age = boundaries.bucket(forLastAccessDate: file.lastAccessDate) {
                ages[age, default: 0] += 1
            }
            if anySize.matches(file, ages: boundaries, search: search) {
                sizes[SizeBucket(size: file.item.size), default: 0] += 1
            }
        }
    }

    public func count(of kind: FileKind) -> Int { kinds[kind] ?? 0 }
    public func count(of age: AgeBucket) -> Int { ages[age] ?? 0 }
    public func count(of size: SizeBucket) -> Int { sizes[size] ?? 0 }
}
