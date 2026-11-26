import CleanMacCore
import Foundation
import SecurityFeature
import Testing

struct ProtectionReaderTests {
    private static let xprotectInfo = "/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"
    private static let softwareUpdate = "/Library/Preferences/com.apple.SoftwareUpdate.plist"
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func protections(
        runner: StubCommandRunner,
        files: StubProtectionFiles = StubProtectionFiles()
    ) async -> [ProtectionKind: ProtectionCheck] {
        let now = now
        let checks = await ProtectionReader(runner: runner, files: files, now: { now }).protections()
        return Dictionary(uniqueKeysWithValues: checks.map { ($0.kind, $0) })
    }

    @Test func checksEveryProtectionInOrder() async {
        let checks = await ProtectionReader(runner: StubCommandRunner([:]), files: StubProtectionFiles()).protections()

        #expect(checks.map(\.kind) == ProtectionKind.allCases)
    }

    @Test func readsWhatEachToolPrints() async {
        let runner = StubCommandRunner([
            "fdesetup": .success("FileVault is On.\n"),
            "socketfilterfw": .success("Firewall is disabled. (State = 0)\n"),
            "spctl": .success("assessments enabled\n"),
            "csrutil": .success("System Integrity Protection status: enabled.\n")
        ])

        let checks = await protections(runner: runner)

        #expect(checks[.fileVault]?.state == .on)
        #expect(checks[.firewall]?.state == .off)
        #expect(checks[.gatekeeper]?.state == .on)
        #expect(checks[.systemIntegrityProtection]?.state == .on)
    }

    /// `spctl --status` exits with an error when Gatekeeper is off, after printing so.
    @Test func readsWhatAToolPrintedBeforeFailing() async {
        let runner = StubCommandRunner([
            "spctl": .failure(CommandFailure(status: 1, message: "", output: "assessments disabled\n"))
        ])

        #expect(await protections(runner: runner)[.gatekeeper]?.state == .off)
    }

    @Test func leavesAProtectionUnknownWhenItsToolFailsWithoutSayingWhy() async {
        let runner = StubCommandRunner([
            "fdesetup": .failure(CommandFailure(status: 1, message: "Error"))
        ])

        #expect(await protections(runner: runner)[.fileVault]?.state == .unknown)
    }

    @Test func readsTheSoftwareUpdatePreferences() async {
        var files = StubProtectionFiles()
        files.propertyLists[Self.softwareUpdate] = ["ConfigDataInstall": false]

        let check = await protections(runner: StubCommandRunner([:]), files: files)[.automaticUpdates]

        #expect(check?.state == .partial)
        #expect(check?.detail == .updateOptionsOff([.installSystemDataFiles]))
    }

    @Test func turnsAutomaticUpdatesOnWithoutPreferences() async {
        #expect(await protections(runner: StubCommandRunner([:]))[.automaticUpdates]?.state == .on)
    }

    @Test func readsXProtectsVersionAndWhenItChanged() async {
        let updatedAt = now.addingTimeInterval(-5 * 24 * 60 * 60)
        var files = StubProtectionFiles()
        files.propertyLists[Self.xprotectInfo] = ["CFBundleShortVersionString": "5377"]
        files.modificationDates[Self.xprotectInfo] = updatedAt

        let check = await protections(runner: StubCommandRunner([:]), files: files)[.xprotect]

        #expect(check == ProtectionCheck(kind: .xprotect, state: .on, detail: .xprotect(version: "5377", updatedAt: updatedAt)))
    }

    @Test func leavesXProtectUnknownWhenItsDefinitionsAreMissing() async {
        #expect(await protections(runner: StubCommandRunner([:]))[.xprotect]?.state == .unknown)
    }

    @Test func linksEveryProtectionButSystemIntegrityProtectionToSystemSettings() {
        let unlinked = ProtectionKind.allCases.filter { $0.settingsURL == nil }

        #expect(unlinked == [.systemIntegrityProtection])
        #expect(ProtectionKind.allCases.compactMap(\.settingsURL).allSatisfy { $0.scheme == "x-apple.systempreferences" })
    }
}
