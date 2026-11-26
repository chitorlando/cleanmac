import Foundation
import LoginItemsFeature
import Testing

struct FileSystemItemPresenceCheckerTests {
    private let folder: TemporaryFolder
    private let checker = FileSystemItemPresenceChecker()

    init() throws {
        folder = try TemporaryFolder()
    }

    @Test func findsWhatIsThere() throws {
        #expect(checker.presence(of: try folder.make("bin/tool")) == .present)
        #expect(checker.presence(of: try folder.make("Example.app/")) == .present)
    }

    @Test func knowsWhatIsGone() throws {
        let file = try folder.make("bin/tool")

        #expect(checker.presence(of: folder.url("bin/missing")) == .missing)
        #expect(checker.presence(of: folder.url("Gone.app/Contents/MacOS/gone")) == .missing)
        #expect(checker.presence(of: file.appending(path: "inside-a-file")) == .missing)
    }

    @Test func takesALinkToSomethingGoneAsMissing() throws {
        let link = folder.url("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: folder.url("gone"))

        #expect(checker.presence(of: link) == .missing)
    }

    @Test func cannotTellInsideAFolderItCannotEnter() throws {
        let present = try folder.make("Restricted/helper")
        let restricted = folder.url("Restricted").path
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: restricted)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: restricted) }

        #expect(checker.presence(of: present) == .unknown)
        #expect(checker.presence(of: folder.url("Restricted/missing")) == .unknown)
    }
}
