import CleanMacCore
import Foundation

/// Decides where a scan may look: in the home folder, or in a single folder that the scan of
/// the home folder enters.
///
/// A scan limited to a folder walks from that folder, and a walk applies its rules to what it
/// finds below the folder it starts from, never to that folder itself. Started in `~/Library`,
/// in a hidden folder or inside a package, it would offer files that the scan of the home
/// folder keeps away from the user. So a folder only becomes a scope when a walk from the home
/// folder with `FileSystemWalker` reaches it: neither the folder nor any folder on the way to
/// it is hidden, a package or one of the excluded directories.
///
/// The folder is located by its canonical path, which resolves symbolic links on the way and
/// names written in another case. `~/library/Caches` is the `~/Library/Caches` it points to.
public struct ScanScopePolicy: Sendable {
    /// Folder a scan covers unless it's limited to another.
    public let home: URL
    private let excludedPaths: Set<String>

    /// - Parameter excludedDirectories: Folders the scan skips with everything inside. They must
    ///   be the ones given to the walker of the scan.
    public init(home: URL, excludedDirectories: [URL] = []) {
        self.home = home
        excludedPaths = Set(excludedDirectories.map(\.standardizedFileURL.path))
    }

    /// The scope of a scan limited to the folder at `url`. For the home folder it's the whole home.
    ///
    /// - Returns: `nil` when `url` is not a folder, which includes a symbolic link to one and a
    ///   folder that's gone, or when the scan of the home folder would never enter it.
    public func scope(limitedTo url: URL) -> LargeFileScanScope? {
        guard let names = folderNames(fromHomeTo: url) else { return nil }
        return names.isEmpty ? .home : .folder(folder(named: names))
    }

    /// The folder to walk for `scope`.
    ///
    /// - Returns: `nil` when the scope is a folder the scan may no longer look in, for instance
    ///   because it was removed or replaced after the scope was made.
    public func folder(of scope: LargeFileScanScope) -> URL? {
        switch scope {
        case .home: home
        case .folder(let url): folderNames(fromHomeTo: url).map(folder(named:))
        }
    }

    /// Names of the folders that lead from the home folder down to the folder at `url`, none
    /// for the home folder itself, or `nil` when the scan may not look in `url`.
    private func folderNames(fromHomeTo url: URL) -> [String]? {
        // Nothing here lists a folder, but a folder that is only in the cloud must not be
        // downloaded just to tell what it is.
        DatalessFilePolicy.withoutMaterializing {
            guard let folder = canonicalComponents(ofFolderAt: url),
                  let home = canonicalComponents(ofFolderAt: home),
                  folder.starts(with: home) else { return nil }
            let names = Array(folder.dropFirst(home.count))
            return walkEnters(names) ? names : nil
        }
    }

    /// Path components of the folder at `url` once symbolic links and letter case are resolved,
    /// or `nil` when there's no folder there. A symbolic link to a folder is not a folder.
    private func canonicalComponents(ofFolderAt url: URL) -> [String]? {
        // The URL may remember values read earlier, such as by the feature that sent the
        // folder, and the folder may have changed since.
        var url = url
        url.removeAllCachedResourceValues()
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .canonicalPathKey]),
              values.isDirectory == true,
              let path = values.canonicalPath else { return nil }
        return URL(filePath: path).pathComponents
    }

    /// Whether a walk from the home folder goes into each of the folders named, one inside the other.
    private func walkEnters(_ names: [String]) -> Bool {
        var folder = home
        for name in names {
            folder = folder.appending(component: name, directoryHint: .isDirectory)
            guard !excludedPaths.contains(folder.standardizedFileURL.path),
                  let values = try? folder.resourceValues(forKeys: [.isHiddenKey, .isPackageKey]),
                  values.isHidden != true,
                  values.isPackage != true else { return false }
        }
        return true
    }

    /// The folder reached from the home folder through the folders named, spelled as a walk
    /// from the home folder reports it.
    private func folder(named names: [String]) -> URL {
        names.reduce(home) { $0.appending(component: $1, directoryHint: .isDirectory) }
    }
}
