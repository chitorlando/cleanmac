import Foundation

/// `FileWalking` over the local disk that only offers files the user can safely review.
///
/// - Hidden files and folders are skipped.
/// - Packages such as `.app` or `.photoslibrary` are neither entered nor offered:
///   removing one of their files would break them, and removing them whole could be catastrophic.
/// - Excluded folders, `~/Library` by default, are skipped with everything inside,
///   because other features take care of them.
public struct FileSystemWalker: FileWalking {
    private static let resourceKeys: [URLResourceKey] = [
        .isRegularFileKey,
        .isPackageKey,
        .totalFileAllocatedSizeKey,
        .contentAccessDateKey,
        .contentModificationDateKey
    ]

    private let excludedPaths: Set<String>

    public init(excludedDirectories: [URL] = [Self.userLibrary]) {
        excludedPaths = Set(excludedDirectories.map(\.standardizedFileURL.path))
    }

    public static var userLibrary: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
    }

    public func walk(_ root: URL, visit: (FileRecord) -> Bool) {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: Self.resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return }

        for case let url as URL in enumerator {
            if excludedPaths.contains(url.standardizedFileURL.path) {
                enumerator.skipDescendants()
                continue
            }
            if let record = record(for: url), !visit(record) {
                return
            }
        }
    }

    private func record(for url: URL) -> FileRecord? {
        guard
            let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys)),
            values.isRegularFile == true,
            values.isPackage != true
        else { return nil }

        return FileRecord(
            url: url,
            size: Int64(values.totalFileAllocatedSize ?? 0),
            accessDate: values.contentAccessDate,
            modificationDate: values.contentModificationDate
        )
    }
}
