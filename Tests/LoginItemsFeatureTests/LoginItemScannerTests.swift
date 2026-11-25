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

    private func scan(
        apps: [String: URL] = [:],
        overrides: any LaunchOverridesReading = FakeLaunchOverrides()
    ) async -> [LoginItem] {
        let scanner = LoginItemScanner(
            folders: folders,
            reader: LocalDirectoryReader(),
            sizer: AllocatedSizeCalculator(),
            attributor: LoginItemAttributor(appLocator: FakeAppLocator(apps: apps), reader: LocalDirectoryReader()),
            overrides: overrides
        )
        return await scanner.scan()
    }

    /// Whether each item comes out of a scan as disabled, by label.
    private func disabledStates(overrides: any LaunchOverridesReading) async -> [String: Bool] {
        let items = await scan(overrides: overrides)
        return Dictionary(uniqueKeysWithValues: items.map { ($0.job.label, $0.isDisabled) })
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

    @Test func takesLaunchdsOverrideOverThePropertyListsDisabledKey() async throws {
        try folder.makePlist("home/Library/LaunchAgents/off.plist", ["Label": "com.example.off"])
        try folder.makePlist("home/Library/LaunchAgents/on.plist", ["Label": "com.example.on", "Disabled": true])
        try folder.makePlist("Library/LaunchDaemons/daemon.plist", ["Label": "com.example.daemon"])
        let overrides = FakeLaunchOverrides(
            agents: ["com.example.off": true, "com.example.on": false],
            daemons: ["com.example.daemon": true]
        )

        let disabled = await disabledStates(overrides: overrides)

        #expect(disabled == ["com.example.off": true, "com.example.on": false, "com.example.daemon": true])
    }

    @Test func followsThePropertyListsDisabledKeyWithoutAnOverrideForTheItem() async throws {
        try folder.makePlist("home/Library/LaunchAgents/plain.plist", ["Label": "com.example.plain"])
        try folder.makePlist("home/Library/LaunchAgents/disabled.plist", ["Label": "com.example.disabled", "Disabled": true])
        let overrides = FakeLaunchOverrides(
            agents: ["com.example.unrelated": false],
            daemons: ["com.example.plain": true, "com.example.disabled": false]
        )

        let disabled = await disabledStates(overrides: overrides)

        #expect(disabled == ["com.example.plain": false, "com.example.disabled": true])
    }

    @Test func followsThePropertyListsDisabledKeyWithoutLaunchdsFiles() async throws {
        try folder.makePlist("home/Library/LaunchAgents/plain.plist", ["Label": "com.example.plain"])
        try folder.makePlist("Library/LaunchDaemons/disabled.plist", ["Label": "com.example.disabled", "Disabled": true])
        let missingFiles = LaunchdOverrideFiles(folder: folder.url("var/db/com.apple.xpc.launchd"), userID: 501)

        let disabled = await disabledStates(overrides: missingFiles)

        #expect(disabled == ["com.example.plain": false, "com.example.disabled": true])
    }
}
