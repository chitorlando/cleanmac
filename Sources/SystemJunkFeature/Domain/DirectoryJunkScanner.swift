import CleanMacCore
import Foundation

/// Treats every direct child of a set of folders as a removable item.
public struct DirectoryJunkScanner: JunkScanner {
    public let category: JunkCategory
    private let locations: [URL]
    private let reader: any DirectoryReading
    private let sizer: any SizeCalculating
    private let exclusions: ExclusionRules

    public init(
        category: JunkCategory,
        locations: [URL],
        reader: any DirectoryReading,
        sizer: any SizeCalculating,
        exclusions: ExclusionRules = .standard
    ) {
        self.category = category
        self.locations = locations
        self.reader = reader
        self.sizer = sizer
        self.exclusions = exclusions
    }

    public func scan() async -> [CleanableItem] {
        candidateURLs()
            .map { CleanableItem(url: $0, size: sizer.size(of: $0)) }
            .filter { $0.size > 0 }
            .sorted { $0.size > $1.size }
    }

    private func candidateURLs() -> [URL] {
        locations
            .filter { reader.itemExists(at: $0) }
            .flatMap { (try? reader.childItems(of: $0)) ?? [] }
            .filter { !exclusions.excludes($0) }
    }
}
