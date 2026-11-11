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

    @Test func returnsStandardizedURLs() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.makeFolder("Applications/Vendor/Deep/Nested.app/Contents")

        let apps = FileSystemAppLocator().applications(in: [folder.root.appending(path: "Applications")])

        #expect(apps.count == 1)
        #expect(apps.allSatisfy { $0 == $0.standardizedFileURL })
    }

    @Test func findsAnAppOutsideTheApplicationFolders() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        let app = try folder.makeFolder("Downloads/Installer/Tool.app/Contents").deletingLastPathComponent()

        let found = FileSystemAppLocator().application(at: app.appending(path: "../Tool.app/"))

        #expect(found?.path == app.standardizedFileURL.path)
    }

    @Test func findsNoAppAtPlainFoldersLinksOrMissingPaths() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.makeFolder("Downloads/Real.app/Contents")
        let plainFolder = try folder.makeFolder("Downloads/Photos")
        let link = try folder.makeLink("Downloads/Linked.app", to: "Downloads/Real.app")
        let missing = folder.root.appending(path: "Downloads/Gone.app")
        let locator = FileSystemAppLocator()

        #expect(locator.application(at: plainFolder) == nil)
        #expect(locator.application(at: link) == nil)
        #expect(locator.application(at: missing) == nil)
    }

    @Test func findsNoAppInTheTrash() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        let trashed = try folder.makeFolder("Home/.Trash/Old.app/Contents").deletingLastPathComponent()
        let trashedOnAVolume = try folder.makeFolder("Volume/.Trashes/501/Old.app/Contents").deletingLastPathComponent()
        let locator = FileSystemAppLocator()

        #expect(locator.application(at: trashed) == nil)
        #expect(locator.application(at: trashedOnAVolume) == nil)
    }

    @Test func findsNoAppInsideAnotherApp() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        let helper = try folder.makeFolder("Downloads/Host.app/Contents/Helpers/Helper.app/Contents")
            .deletingLastPathComponent()
        let host = folder.root.appending(path: "Downloads/Host.app")
        let locator = FileSystemAppLocator()

        #expect(locator.application(at: helper) == nil)
        #expect(locator.application(at: host)?.path == host.standardizedFileURL.path)
    }
}
