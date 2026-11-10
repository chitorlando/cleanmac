import Foundation

/// `FileWalking` over the local disk that only offers files the user can safely review.
///
/// - Hidden files and folders are skipped.
/// - Packages such as `.app` or `.photoslibrary` are never entered: removing one of their
///   files would break them. They aren't offered either, since removing them whole could
///   be catastrophic, unless a `packageSizeCalculator` is given. Then each package is
///   reported as a single record with its whole size, for features that only measure space.
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
    private let packageSizeCalculator: (any SizeCalculating)?

    /// - Parameter packageSizeCalculator: Measures packages so they're reported whole. `nil` skips them.
    public init(
        excludedDirectories: [URL] = [Self.userLibrary],
        packageSizeCalculator: (any SizeCalculating)? = nil
    ) {
        excludedPaths = Set(excludedDirectories.map(\.standardizedFileURL.path))
        self.packageSizeCalculator = packageSizeCalculator
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
        guard let values = try? url.resourceValues(forKeys: Set(Self.resourceKeys)) else { return nil }
        if values.isPackage == true {
            return packageRecord(for: url, values: values)
        }
        guard values.isRegularFile == true else { return nil }

        return FileRecord(
            url: url,
            size: Int64(values.totalFileAllocatedSize ?? 0),
            accessDate: values.contentAccessDate,
            modificationDate: values.contentModificationDate
        )
    }

    private func packageRecord(for url: URL, values: URLResourceValues) -> FileRecord? {
        guard let packageSizeCalculator else { return nil }
        return FileRecord(
            url: url,
            size: packageSizeCalculator.size(of: url),
            accessDate: values.contentAccessDate,
            modificationDate: values.contentModificationDate,
            isPackage: true
        )
    }
}
