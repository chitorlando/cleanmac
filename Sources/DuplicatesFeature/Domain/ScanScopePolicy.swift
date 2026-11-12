import CleanMacCore
import Foundation

/// Decides which folders can be scanned on their own, so that choosing a folder never reaches
/// files the scan of the home folder leaves out.
///
/// A walk judges what it finds under the folder it starts from, never that folder: started
/// inside `~/Library`, a hidden folder or a package, it would offer files the home scan skips.
/// So a folder is only scanned alone when the walk of the home folder gets to it. For that,
/// the folder and every folder between it and the home folder must be:
///
/// - a real folder, because the walk doesn't follow symbolic links;
/// - neither hidden nor a package;
/// - none of the excluded folders;
/// - spelled as on disk, the way the walk reports it. Another spelling of the same path, such
///   as `~/library` on a volume that ignores case or a path with `..`, would get past the
///   excluded folders, which are compared by path.
///
/// Nothing is downloaded to find out: see `DatalessFilePolicy`.
public struct ScanScopePolicy: Sendable {
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isSymbolicLinkKey,
        .isHiddenKey,
        .isPackageKey,
        .nameKey
    ]

    private let home: URL
    /// Path components of the home folder as given and as the file system spells them. A walk
    /// reports what it finds with the second spelling, which is another one when the path of
    /// the home folder goes through a symbolic link, as `/var` does.
    private let homeSpellings: [[String]]
    private let excludedPaths: Set<String>

    /// - Parameter excludedDirectories: Folders the walk of the home folder skips with
    ///   everything inside. They must be the ones the walker is given.
    public init(home: URL, excludedDirectories: [URL]) {
        self.home = home
        let canonicalPath = try? home.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
        let canonicalHome = canonicalPath.map { URL(filePath: $0, directoryHint: .isDirectory) }
        homeSpellings = [home, canonicalHome].compactMap { $0?.pathComponents }
        excludedPaths = Set(excludedDirectories.map(\.standardizedFileURL.path))
    }

    /// The scope that covers only the folder at `url`, or `nil` when the scan of the home
    /// folder never walks it. The home folder itself gives `.home`.
    ///
    /// The folder of the scope is spelled from the home folder as given, like the excluded
    /// folders, whichever spelling of the home folder `url` uses.
    public func scope(limitedTo url: URL) -> DuplicateScanScope? {
        guard let names = namesBelowHome(of: url) else { return nil }
        guard !names.isEmpty else { return .home }
        return DatalessFilePolicy.withoutMaterializing {
            var folder = home
            for name in names {
                folder = folder.appending(path: name, directoryHint: .notDirectory)
                guard isWalked(folder, named: name) else { return nil }
            }
            return .folder(folder)
        }
    }

    /// Whether the folder at `url` can be scanned on its own.
    public func allows(_ url: URL) -> Bool {
        scope(limitedTo: url) != nil
    }

    /// Names of the folders that lead from the home folder down to `url`, or `nil` when it is
    /// not in the home folder.
    private func namesBelowHome(of url: URL) -> ArraySlice<String>? {
        guard url.isFileURL else { return nil }
        let components = url.pathComponents
        guard let spelling = homeSpellings.first(where: { components.starts(with: $0) }) else { return nil }
        return components.dropFirst(spelling.count)
    }

    /// Whether a walk that reached the parent of `url` goes on into `url`.
    private func isWalked(_ url: URL, named name: String) -> Bool {
        guard let values = try? url.resourceValues(forKeys: Self.resourceKeys) else { return false }
        return values.isDirectory == true
            && values.isSymbolicLink != true
            && values.isHidden != true
            && values.isPackage != true
            && values.name == name
            && !excludedPaths.contains(url.standardizedFileURL.path)
    }
}
