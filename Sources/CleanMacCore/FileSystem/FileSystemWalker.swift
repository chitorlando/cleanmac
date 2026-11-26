import Foundation

/// `FileWalking` over the local disk that only offers files the user can safely review.
///
/// - Hidden files and folders, whose names start with a dot or that Finder hides, such as
///   `~/Library`, are skipped unless `includesHiddenItems` is set. Features that offer files
///   to remove keep them out: they hold the settings and data of apps and tools.
/// - Packages such as `.app` or `.photoslibrary` are never entered: removing one of their
///   files would break them. They aren't offered either, since removing them whole could
///   be catastrophic, unless a `packageSizeCalculator` is given. Then each package is
///   reported as a single record with its whole size, for features that only measure space.
/// - Excluded folders, `~/Library` by default, are skipped with everything inside,
///   because other features take care of them.
/// - Files and folders that are only in the cloud, such as in iCloud Drive, are never
///   downloaded (see `DatalessFilePolicy`).
/// - Folders it can't read, because macOS keeps them private or their permissions keep
///   CleanMac out, are skipped, and reported to callers that ask for them.
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
    private let includesHiddenItems: Bool

    /// - Parameters:
    ///   - packageSizeCalculator: Measures packages so they're reported whole. `nil` skips them.
    ///   - includesHiddenItems: Walks hidden files and folders too, for features that only
    ///     measure space.
    public init(
        excludedDirectories: [URL] = [Self.userLibrary],
        packageSizeCalculator: (any SizeCalculating)? = nil,
        includesHiddenItems: Bool = false
    ) {
        excludedPaths = Set(excludedDirectories.map(\.standardizedFileURL.path))
        self.packageSizeCalculator = packageSizeCalculator
        self.includesHiddenItems = includesHiddenItems
    }

    public static var userLibrary: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library")
    }

    public func walk(_ root: URL, visit: (FileRecord) -> Bool) {
        walk(root, visit: visit, unreadable: { _ in })
    }

    public func walk(_ root: URL, visit: (FileRecord) -> Bool, unreadable: (URL) -> Void) {
        DatalessFilePolicy.withoutMaterializing {
            walkLocally(root, visit: visit, unreadable: unreadable)
        }
    }

    private func walkLocally(_ root: URL, visit: (FileRecord) -> Bool, unreadable: (URL) -> Void) {
        let unreadableFolders = UnreadableFolderLog()
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: Self.resourceKeys,
            options: enumerationOptions,
            errorHandler: { url, error in
                unreadableFolders.record(url, failingWith: error)
                return true
            }
        ) else { return }

        // Each item gets its own autorelease pool. The enumerator hands out autoreleased URLs,
        // holding the values read for them, and a walk on a background thread would otherwise
        // keep every one of them until it ends: hundreds of megabytes in a large home folder.
        var isWalking = true
        while isWalking {
            isWalking = autoreleasepool {
                // The enumerator reports a folder it can't enter while it moves on to the next item.
                let next = enumerator.nextObject() as? URL
                unreadableFolders.flush(into: unreadable)
                guard let url = next else { return false }
                if excludedPaths.contains(url.standardizedFileURL.path) {
                    enumerator.skipDescendants()
                    return true
                }
                guard let record = record(for: url) else { return true }
                return visit(record)
            }
        }
    }

    private var enumerationOptions: FileManager.DirectoryEnumerationOptions {
        includesHiddenItems ? [.skipsPackageDescendants] : [.skipsHiddenFiles, .skipsPackageDescendants]
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
