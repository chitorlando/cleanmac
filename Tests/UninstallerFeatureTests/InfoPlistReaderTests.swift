import Foundation
import Testing
import UninstallerFeature

struct InfoPlistReaderTests {
    @Test func readsIdentityFromInfoPlist() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.writePlist([
            "CFBundleIdentifier": "com.example.editor",
            "CFBundleShortVersionString": "2.1",
            "CFBundleName": "Editor",
            "CFBundleDisplayName": "Example Editor"
        ], to: "Editor.app/Contents/Info.plist")
        let app = folder.root.appending(path: "Editor.app")

        let info = try #require(InfoPlistReader().info(forAppAt: app))

        #expect(info.url == app)
        #expect(info.bundleID == "com.example.editor")
        #expect(info.name == "Editor")
        #expect(info.version == "2.1")
        #expect(info.alternateNames == ["Example Editor"])
    }

    @Test func toleratesMissingOptionalKeys() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.writePlist(["CFBundleIdentifier": "com.example.tool"], to: "Tool.app/Contents/Info.plist")

        let info = try #require(InfoPlistReader().info(forAppAt: folder.root.appending(path: "Tool.app")))

        #expect(info.version == nil)
        #expect(info.alternateNames.isEmpty)
    }

    @Test func returnsNilWithoutBundleIdentifier() throws {
        let folder = try TemporaryFolder()
        defer { folder.remove() }
        try folder.writePlist(["CFBundleName": "Nameless"], to: "Nameless.app/Contents/Info.plist")
        try folder.makeFolder("Empty.app/Contents")

        let reader = InfoPlistReader()

        #expect(reader.info(forAppAt: folder.root.appending(path: "Nameless.app")) == nil)
        #expect(reader.info(forAppAt: folder.root.appending(path: "Empty.app")) == nil)
    }
}
