import CleanMacCore
import Foundation
import Testing

struct ApplicationFolderAppFinderTests {
    @Test func findsAppsAtTheTopAndOneFolderDown() {
        let reader = FolderTreeReader(tree: [
            "/Applications": ["Zed.app", "Utilities", "notes.txt", "alpha.app", ".hidden.app", "Tools"],
            "/Applications/Utilities": ["Helper.app", "Deep"],
            "/Applications/Utilities/Deep": ["TooDeep.app"],
            "/Applications/Tools": ["Tool.app"],
            "/Users/ana/Applications": ["Web App.app"]
        ])
        let finder = ApplicationFolderAppFinder(
            folders: [URL(filePath: "/Applications"), URL(filePath: "/Users/ana/Applications")],
            reader: reader
        )

        #expect(finder.apps().map(\.path) == [
            "/Applications/alpha.app",
            "/Applications/Utilities/Helper.app",
            "/Applications/Tools/Tool.app",
            "/Users/ana/Applications/Web App.app",
            "/Applications/Zed.app"
        ])
    }

    @Test func skipsFoldersThatAreMissing() {
        let finder = ApplicationFolderAppFinder(folders: [URL(filePath: "/Nowhere")], reader: FolderTreeReader(tree: [:]))

        #expect(finder.apps().isEmpty)
    }
}

/// A folder tree in memory: each folder's path with the names of its items.
private struct FolderTreeReader: DirectoryReading {
    let tree: [String: [String]]

    func itemExists(at url: URL) -> Bool {
        tree[url.path] != nil || tree[url.deletingLastPathComponent().path]?.contains(url.lastPathComponent) == true
    }

    func childItems(of directory: URL) throws -> [URL] {
        guard let names = tree[directory.path] else { throw CocoaError(.fileReadNoSuchFile) }
        return names.map { directory.appending(path: $0) }
    }
}
