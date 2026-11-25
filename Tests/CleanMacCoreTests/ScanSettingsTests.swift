import CleanMacCore
import Foundation
import Testing

struct ScanSettingsTests {
    @Test func leavesOutNoFoldersUntilTheUserChoosesSome() {
        #expect(ScanSettings.excludedFolders.key == "scans.excludedFolders")
        #expect(ScanSettings.excludedFolders.defaultValue.isEmpty)
        #expect(ScanSettings.excludedFolders.allowedValues == nil)
    }

    @Test func readsEachPathAsAFolder() {
        let folders = ScanSettings.folders(at: ["/Users/test/Movies", "/Users/test/Music Videos"])

        #expect(folders.map(\.path) == ["/Users/test/Movies", "/Users/test/Music Videos"])
        #expect(folders.allSatisfy { $0.hasDirectoryPath })
    }

    @Test func scansOfTheCurrentUserAlwaysLeaveOutTheirLibrary() {
        let policy = ScanScopePolicy.currentUserHome

        #expect(policy.home == FileManager.default.homeDirectoryForCurrentUser)
        #expect(policy.excludedDirectories == [FileSystemWalker.userLibrary])
    }
}
