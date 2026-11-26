import CleanMacCore
import Foundation

/// Offers the user's Trash bins: the one on this Mac and the ones on connected volumes.
///
/// Cleaning them empties the Trash, which erases every bin at once and for good, so none is
/// selected until the user chooses to. Without Full Disk Access, macOS keeps CleanMac out of
/// the Trash, and the category says so instead of showing it empty.
public struct TrashJunkScanner: JunkScanner {
    private let reader: TrashSizeReader

    public init(reader: TrashSizeReader) {
        self.reader = reader
    }

    public var category: JunkCategory { .trashBins }

    public func scan() async -> CategoryScanResult {
        switch reader.read() {
        case .unreadable:
            return .unreadable(category)
        case .readable(let usages):
            return CategoryScanResult(
                category: category,
                items: usages.map { CleanableItem(url: $0.bin.url, size: $0.size) },
                details: Dictionary(uniqueKeysWithValues: usages.map { ($0.bin.url, JunkItemDetail.trashBin($0.bin)) })
            )
        }
    }
}
