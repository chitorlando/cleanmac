import CleanMacCore
import Foundation
import LoginItemsFeature
import Testing

/// An item is orphaned when what it runs is gone, and only then.
struct OrphanDetectionTests {
    private let folder: TemporaryFolder

    init() throws {
        folder = try TemporaryFolder()
    }

    /// Whether the user's agent with these keys comes out of a scan marked as orphaned.
    private func isOrphaned(_ keys: [String: Any]) async throws -> Bool {
        try folder.makePlist("home/Library/LaunchAgents/agent.plist", keys)
        let reader = LocalDirectoryReader()
        let scanner = LoginItemScanner(
            folders: LaunchFolder.standard(home: folder.url("home"), library: folder.url("Library")),
            reader: reader,
            sizer: AllocatedSizeCalculator(),
            attributor: LoginItemAttributor(appLocator: FakeAppLocator(), reader: reader)
        )
        let items = await scanner.scan()
        return try #require(items.first).isOrphaned
    }

    /// A program inside a folder the user can't enter can't be checked, as with helpers
    /// kept in folders only root can open. It is there, so the item isn't orphaned.
    @Test func doesNotTakeAProgramItCannotReachAsGone() async throws {
        let program = try folder.make("Restricted/helper")
        let restricted = folder.url("Restricted").path
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: restricted)
        defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: restricted) }

        let orphaned = try await isOrphaned(["Label": "com.example.helper", "Program": program.path])

        #expect(!orphaned)
    }
}
