import CleanMacCore
import Foundation

/// Turns cache locations into the folders that exist in a user's Library.
public struct CacheLocationResolver: Sendable {
    private let library: URL
    private let reader: any DirectoryReading

    public init(library: URL, reader: any DirectoryReading) {
        self.library = library
        self.reader = reader
    }

    /// The existing cache folders of every location, without duplicates, in order.
    public func folders(for locations: [CacheLocation]) -> [URL] {
        var seenPaths: Set<String> = []
        return locations
            .flatMap(candidates(for:))
            .filter { reader.itemExists(at: $0) && seenPaths.insert($0.standardizedFileURL.path).inserted }
    }

    private func candidates(for location: CacheLocation) -> [URL] {
        let caches = library.appending(path: "Caches")
        switch location {
        case .cachesFolder(let path):
            return [caches.appending(path: path)]
        case .cachesNamed(let bundleID):
            return children(of: caches).filter { isNamed($0, after: bundleID) }
        case let .profileFolders(userData, layout, cacheFolders):
            return profiles(in: library.appending(path: userData), layout: layout)
                .flatMap { profile in cacheFolders.map { profile.appending(path: $0) } }
        }
    }

    /// The bundle identifier itself, or the identifier followed by a dot and more, ignoring case.
    private func isNamed(_ url: URL, after bundleID: String) -> Bool {
        let name = url.lastPathComponent.lowercased()
        let id = bundleID.lowercased()
        return name == id || name.hasPrefix(id + ".")
    }

    private func profiles(in userData: URL, layout: ProfileLayout) -> [URL] {
        switch layout {
        case .rootIsProfile:
            return [userData]
        case .anyFolder:
            return children(of: userData)
        case .chromium:
            return children(of: userData).filter { Self.isChromiumProfileName($0.lastPathComponent) }
        }
    }

    /// "Default" or "Profile" followed by a space and a number, such as "Profile 2".
    static func isChromiumProfileName(_ name: String) -> Bool {
        if name == "Default" { return true }
        let prefix = "Profile "
        guard name.hasPrefix(prefix) else { return false }
        let number = name.dropFirst(prefix.count)
        return !number.isEmpty && number.allSatisfy(\.isASCIIDigit)
    }

    private func children(of folder: URL) -> [URL] {
        guard reader.itemExists(at: folder) else { return [] }
        return ((try? reader.childItems(of: folder)) ?? [])
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
