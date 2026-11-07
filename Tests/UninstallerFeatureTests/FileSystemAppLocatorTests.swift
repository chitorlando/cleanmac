import Foundation
import Testing
import UninstallerFeature

struct FileSystemAppLocatorTests {
    private func appNames(in folders: [URL]) -> [String] {
        FileSystemAppLocator().applications(in: folders).map(\.lastPathComponent).sorted()
    }

    @Test func findsTopLevelAndNestedApps() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.makeFolder("Applications/Top.app/Contents")
        try folder.makeFolder("Applications/Unity/Hub/Editor/6.0/Unity.app/Contents")
        try folder.makeFolder("Applications/Chrome Apps.localized/Titan.app/Contents")

        let names = appNames(in: [folder.root.appending(path: "Applications")])

        #expect(names == ["Titan.app", "Top.app", "Unity.app"])
    }

    @Test func doesNotLookInsideAppBundles() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.makeFolder("Applications/Host.app/Contents/Helpers/Helper.app/Contents")

        #expect(appNames(in: [folder.root.appending(path: "Applications")]) == ["Host.app"])
    }

    @Test func ignoresSymbolicLinksPlainFoldersAndHiddenItems() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.makeFolder("Elsewhere/Linked.app/Contents")
        try folder.makeFolder("Applications/Real.app/Contents")
        try folder.makeFolder("Applications/Utilities")
        try folder.makeFolder("Applications/.Hidden/Secret.app")
        try folder.makeLink("Applications/Linked.app", to: "Elsewhere/Linked.app")

        #expect(appNames(in: [folder.root.appending(path: "Applications")]) == ["Real.app"])
    }

    @Test func removesDuplicatesAndSkipsMissingFolders() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.makeFolder("Applications/Only.app/Contents")
        let applications = folder.root.appending(path: "Applications")

        let names = appNames(in: [
            applications,
            folder.root.appending(path: "Applications/./"),
            folder.root.appending(path: "Missing")
        ])

        #expect(names == ["Only.app"])
    }
}
