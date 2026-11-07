import Foundation

/// Sums the space actually allocated on disk, which is what gets freed when an item is removed.
public struct AllocatedSizeCalculator: SizeCalculating {
    private static let resourceKeys: [URLResourceKey] = [
        .isRegularFileKey,
        .totalFileAllocatedSizeKey,
        .fileAllocatedSizeKey
    ]

    public init() {}

    public func size(of url: URL) -> Int64 {
        if let fileSize = regularFileSize(of: url) {
            return fileSize
        }
        return directorySize(of: url)
    }

    private func directorySize(of url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Self.resourceKeys,
            errorHandler: { _, _ in true }
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            total += regularFileSize(of: fileURL) ?? 0
        }
        return total
    }

    private func regularFileSize(of url: URL) -> Int64? {
        guard
            let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys)),
            values.isRegularFile == true
        else { return nil }

        let bytes = values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0
        return Int64(bytes)
    }
}
