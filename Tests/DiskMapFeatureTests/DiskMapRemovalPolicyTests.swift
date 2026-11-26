import DiskMapFeature
import Foundation
import Testing

struct DiskMapRemovalPolicyTests {
    private let home = URL(filePath: "/Users/test")
    private var policy: DiskMapRemovalPolicy { DiskMapRemovalPolicy(home: home) }

    private func advice(_ path: String, _ kind: DiskNodeKind = .folder) -> RemovalAdvice {
        policy.advice(for: home.appending(path: path), kind: kind)
    }

    @Test func allowsTheUsersOwnFiles() {
        #expect(advice("Movies/trip.mov", .file) == .allowed)
        #expect(advice("Developer/old-project") == .allowed)
        #expect(advice("Pictures/Old Project.fcpbundle", .package) == .allowed)
    }

    @Test func keepsTheHomeAndItsStandardFolders() {
        #expect(policy.advice(for: home, kind: .folder) == .standardFolder)
        #expect(advice("Documents") == .standardFolder)
        #expect(advice("Library") == .standardFolder)
        #expect(advice("Documents/Taxes") == .allowed)
    }

    @Test func onlyShowsAppDataInLibrary() {
        #expect(advice("Library/Application Support/Slack") == .appData)
        #expect(advice("Library/Developer/Xcode/DerivedData") == .appData)
        #expect(advice("Library/Preferences/com.example.plist", .file) == .appData)
    }

    @Test func letsCachesAndLogsGoButNotTheirFolders() {
        #expect(advice("Library/Caches/com.example.app") == .allowed)
        #expect(advice("Library/Logs/DiagnosticReports/crash.ips", .file) == .allowed)
        #expect(advice("Library/Caches") == .appData)
        #expect(advice("Library/Logs") == .appData)
    }

    @Test(arguments: ["Keychains", "Mail", "Messages", "Mobile Documents", "CloudStorage", "Containers", "Group Containers"])
    func blocksDataThatMustNeverBeRemoved(folder: String) {
        #expect(advice("Library/\(folder)") == .protectedData)
        #expect(advice("Library/\(folder)/inside/data.db", .file) == .protectedData)
    }

    @Test func suggestsTheUninstallerForApps() {
        #expect(advice("Applications/Tool.app", .package) == .useUninstaller)
        #expect(policy.advice(for: URL(filePath: "/Volumes/Backup/Old.app"), kind: .package) == .useUninstaller)
        #expect(advice("Applications/Tool.app", .file) == .allowed)
    }

    @Test func keepsPhotoLibraries() {
        #expect(advice("Pictures/Photos Library.photoslibrary", .package) == .protectedData)
    }

    @Test func treatsAppsInsideLibraryAsAppData() {
        #expect(advice("Library/Application Support/Helper.app", .package) == .appData)
    }

    @Test func movesOnlyAllowedItemsToTheTrash() {
        #expect(RemovalAdvice.allowed.allowsMovingToTrash)
        #expect(!RemovalAdvice.appData.allowsMovingToTrash)
        #expect(!RemovalAdvice.protectedData.allowsMovingToTrash)
        #expect(!RemovalAdvice.standardFolder.allowsMovingToTrash)
        #expect(!RemovalAdvice.useUninstaller.allowsMovingToTrash)
    }

    /// What removing it would free isn't known, wherever it is.
    @Test func onlyShowsAFolderThatCouldNotBeRead() {
        let folder = DiskNode(url: home.appending(path: "Projects/Private"), kind: .folder, size: 0, fileCount: 0, isUnreadable: true)
        let mail = DiskNode(url: home.appending(path: "Library/Mail"), kind: .folder, size: 0, fileCount: 0, isUnreadable: true)

        #expect(policy.advice(for: folder) == .unreadable)
        #expect(policy.advice(for: mail) == .unreadable)
        #expect(!RemovalAdvice.unreadable.allowsMovingToTrash)
    }

    @Test func comparesStandardizedPaths() {
        let messy = URL(filePath: "/Users/test/Movies/../Library/Mail/V10")
        #expect(policy.advice(for: messy, kind: .folder) == .protectedData)
    }
}
