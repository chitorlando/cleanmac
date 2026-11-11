import CleanMacCore
import Foundation
import LoginItemsFeature
import Testing

struct LoginItemScannerTests {
    private let folder: TemporaryFolder
    private let folders: [LaunchFolder]

    init() throws {
        folder = try TemporaryFolder()
        folders = LaunchFolder.standard(home: folder.url("home"), library: folder.url("Library"))
    }

    private func scan(apps: [String: URL] = [:]) async -> [LoginItem] {
        let scanner = LoginItemScanner(
            folders: folders,
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator(),
            attributor: LoginItemAttributor(appLocator: FakeAppLocator(apps: apps), reader: LocalDirectoryReader())
        )
        return await scanner.scan()
    }

    @Test func usesTheUserAgentsAndTheSharedAgentsAndDaemons() {
        #expect(folders.map(\.url) == [
            folder.url("home/Library/LaunchAgents"),
            folder.url("Library/LaunchAgents"),
            folder.url("Library/LaunchDaemons")
        ])
    }

    @Test func listsTheItemsOfEveryFolderWithTheirScopeAndKind() async throws {
        try folder.makePlist("home/Library/LaunchAgents/com.example.user.plist", ["Label": "com.example.user"])
        try folder.makePlist("Library/LaunchAgents/com.example.shared.plist", ["Label": "com.example.shared"])
        try folder.makePlist("Library/LaunchDaemons/com.example.daemon.plist", ["Label": "com.example.daemon"])

        let items = await scan()

        #expect(items.map(\.job.label) == ["com.example.user", "com.example.shared", "com.example.daemon"])
        #expect(items.map(\.scope) == [.currentUser, .allUsers, .allUsers])
        #expect(items.map(\.kind) == [.agent, .agent, .daemon])
        #expect(items.map(\.isRemovable) == [true, false, false])
    }

    @Test func skipsMissingFoldersAndFilesThatAreNotLaunchPlists() async throws {
        try folder.makePlist("home/Library/LaunchAgents/valid.plist", ["Label": "valid"])
        try folder.makePlist("home/Library/LaunchAgents/.hidden.plist", ["Label": "hidden"])
        try folder.makePlist("home/Library/LaunchAgents/notes.txt", ["Label": "text"])
        try folder.makePlist("home/Library/LaunchAgents/nolabel.plist", ["Program": "/bin/tool"])
        try folder.make("home/Library/LaunchAgents/empty.plist")

        #expect(await scan().map(\.job.label) == ["valid"])
    }

    @Test func marksItemsWhoseProgramIsGone() async throws {
        let program = try folder.make("Apps/Present.app/Contents/MacOS/present")
        try folder.makePlist("home/Library/LaunchAgents/present.plist", ["Label": "present", "Program": program.path])
        try folder.makePlist(
            "home/Library/LaunchAgents/gone.plist",
            ["Label": "gone", "ProgramArguments": [folder.url("Apps/Gone.app/Contents/MacOS/gone").path]]
        )

        let items = await scan()
        let orphaned = Dictionary(uniqueKeysWithValues: items.map { ($0.job.label, $0.isOrphaned) })

        #expect(orphaned == ["present": false, "gone": true])
        #expect(items.first { $0.job.label == "present" }?.displayName == "Present")
        #expect(items.first { $0.job.label == "gone" }?.displayName == "gone")
    }
}
