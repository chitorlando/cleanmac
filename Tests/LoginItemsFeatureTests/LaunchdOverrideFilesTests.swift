import Foundation
import LoginItemsFeature
import Testing

struct LaunchdOverrideFilesTests {
    private let folder: TemporaryFolder
    private let files: LaunchdOverrideFiles

    init() throws {
        folder = try TemporaryFolder()
        files = LaunchdOverrideFiles(folder: folder.url("launchd"), userID: 501)
    }

    @Test func readsTheAgentsOfTheUsersSessionFromTheFileOfItsUserID() throws {
        try folder.makePlist("launchd/disabled.501.plist", ["com.example.off": true, "com.example.on": false])
        try folder.makePlist("launchd/disabled.502.plist", ["com.example.other-user": true])

        #expect(files.overrides(for: .agent) == ["com.example.off": true, "com.example.on": false])
    }

    @Test func readsTheDaemonsFromTheFileOfTheSystem() throws {
        try folder.makePlist("launchd/disabled.plist", ["com.example.daemon": true])
        try folder.makePlist("launchd/disabled.501.plist", ["com.example.agent": true])

        #expect(files.overrides(for: .daemon) == ["com.example.daemon": true])
    }

    @Test func readsBinaryPropertyLists() throws {
        try folder.makePlist("launchd/disabled.501.plist", ["com.example.off": true], format: .binary)

        #expect(files.overrides(for: .agent) == ["com.example.off": true])
    }

    @Test func hasNoOverridesWithoutAFile() {
        #expect(files.overrides(for: .agent).isEmpty)
        #expect(files.overrides(for: .daemon).isEmpty)
    }

    @Test func hasNoOverridesInAFileItCannotRead() throws {
        let file = try folder.makePlist("launchd/disabled.501.plist", ["com.example.off": true])
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: file.path)

        #expect(files.overrides(for: .agent).isEmpty)
    }

    @Test func hasNoOverridesInAFileThatIsNotADictionary() throws {
        try folder.make("launchd/")
        try Data("not a plist".utf8).write(to: folder.url("launchd/disabled.501.plist"))
        try PropertyListSerialization.data(fromPropertyList: ["com.example.daemon"], format: .xml, options: 0)
            .write(to: folder.url("launchd/disabled.plist"))

        #expect(files.overrides(for: .agent).isEmpty)
        #expect(files.overrides(for: .daemon).isEmpty)
    }

    @Test func skipsValuesThatAreNotBooleans() throws {
        try folder.makePlist("launchd/disabled.501.plist", ["com.example.off": true, "com.example.odd": "yes"])

        #expect(files.overrides(for: .agent) == ["com.example.off": true])
    }
}
