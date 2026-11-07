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

        for file in files {
            if anyKind.matches(file, now: now, calendar: calendar) {
                kinds[file.kind, default: 0] += 1
            }
            if anyAge.matches(file, now: now, calendar: calendar),
               let age = AgeBucket(lastAccessDate: file.lastAccessDate, now: now, calendar: calendar) {
                ages[age, default: 0] += 1
            }
            if anySize.matches(file, now: now, calendar: calendar), let size = SizeBucket(size: file.item.size) {
                sizes[size, default: 0] += 1
            }
        }
    }

    public func count(of kind: FileKind) -> Int { kinds[kind] ?? 0 }
    public func count(of age: AgeBucket) -> Int { ages[age] ?? 0 }
    public func count(of size: SizeBucket) -> Int { sizes[size] ?? 0 }
}
