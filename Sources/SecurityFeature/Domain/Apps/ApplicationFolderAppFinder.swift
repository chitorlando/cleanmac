import CleanMacCore
import Foundation

/// Finds the apps the review checks.
public protocol AppFinding: Sendable {
    /// Each app once, sorted by name.
    func apps() -> [URL]
}

/// Finds the apps at the top of the application folders and in their subfolders, one level
/// down, such as `/Applications/Utilities`. Apps inside other apps and hidden items are left out.
public struct ApplicationFolderAppFinder: AppFinding {
    private static let appExtension = "app"

    private let folders: [URL]
    private let reader: any DirectoryReading

    public init(folders: [URL], reader: any DirectoryReading = LocalDirectoryReader()) {
        self.folders = folders
        self.reader = reader
    }

    public func apps() -> [URL] {
        var seenPaths: Set<String> = []
        return folders
            .flatMap { folder in
                visibleItems(in: folder).flatMap { item in
                    isApp(item) ? [item] : visibleItems(in: item).filter(isApp)
                }
            }
            .filter { seenPaths.insert($0.standardizedFileURL.path).inserted }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    /// The items of a folder, or none when it's a file or can't be read.
    private func visibleItems(in folder: URL) -> [URL] {
        ((try? reader.childItems(of: folder)) ?? []).filter { !$0.lastPathComponent.hasPrefix(".") }
    }

    private func isApp(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == Self.appExtension
    }
}
