import CleanMacCore
import Foundation
import SecurityFeature
import Testing

struct PersistenceRulesTests {
    private func job(_ program: String, _ arguments: [String] = []) -> LaunchJobDefinition {
        LaunchJobDefinition(label: "com.example.job", programPath: program, arguments: arguments, runsAtLoad: true, keepsAlive: false, isDisabled: false)
    }

    @Test func flagsProgramsInTemporaryOrSharedFolders() {
        for path in ["/tmp/a", "/private/tmp/a", "/var/tmp/a", "/private/var/tmp/a", "/private/var/folders/xy/T/a", "/Users/Shared/a"] {
            #expect(PersistenceRules.locationConcerns(of: job(path)) == [.temporaryOrSharedFolder], "\(path)")
        }
    }

    @Test func flagsProgramsInHiddenFolders() {
        #expect(PersistenceRules.locationConcerns(of: job("/Users/ana/.config/agent")) == [.hiddenFolder])
        #expect(PersistenceRules.locationConcerns(of: job("/Users/ana/Library/.agent")) == [.hiddenFolder])
        #expect(PersistenceRules.locationConcerns(of: job("/tmp/.x/agent")) == [.temporaryOrSharedFolder, .hiddenFolder])
    }

    @Test func flagsTheScriptAnInterpreterRuns() {
        #expect(PersistenceRules.locationConcerns(of: job("/bin/sh", ["/tmp/run.sh"])) == [.temporaryOrSharedFolder])
    }

    @Test func leavesUsualLocationsAlone() {
        #expect(PersistenceRules.locationConcerns(of: job("/Applications/Example.app/Contents/MacOS/helper")).isEmpty)
        #expect(PersistenceRules.locationConcerns(of: job("/Library/Application Support/Example/agent")).isEmpty)
        #expect(PersistenceRules.locationConcerns(of: job("/usr/local/bin/tool")).isEmpty)
        #expect(PersistenceRules.locationConcerns(of: job("/Users/ana/Library/Temporary.app/agent")).isEmpty)
    }

    @Test func flagsOnlyMissingOrDamagedSignatures() {
        #expect(PersistenceRules.signatureConcern(of: .unsigned) == .unsignedProgram)
        #expect(PersistenceRules.signatureConcern(of: .damaged) == .damagedProgram)
        #expect(PersistenceRules.signatureConcern(of: .adHocOrSelfSigned) == nil)
        #expect(PersistenceRules.signatureConcern(of: .notarized) == nil)
        #expect(PersistenceRules.signatureConcern(of: .unknown) == nil)
    }
}

/// Finds apps by bundle identifier.
struct StubAppLocator: AppLocating {
    let apps: [String: URL]

    func appURL(forBundleID bundleID: String) -> URL? { apps[bundleID] }
}

struct PersistenceScannerTests {
    private let root = FileManager.default.temporaryDirectory.appending(path: "SecurityFeatureTests-\(UUID().uuidString)")
    private var agents: URL { root.appending(path: "LaunchAgents") }
    private let app = URL(filePath: "/Applications/Example.app")

    private func writePlist(_ name: String, _ keys: [String: Any]) throws {
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(fromPropertyList: keys, format: .xml, options: 0)
        try data.write(to: agents.appending(path: name))
    }

    private func scanner(inspector: StubSignatureInspector) -> PersistenceScanner {
        PersistenceScanner(
            folders: [LaunchFolder(url: agents, scope: .currentUser, kind: .agent)],
            reader: LocalDirectoryReader(),
            attributor: LoginItemAttributor(
                appLocator: StubAppLocator(apps: ["com.example.tool": app]),
                reader: StubDirectoryReader(tree: ["/Applications": ["Example.app"]])
            ),
            inspector: inspector
        )
    }

    @Test func listsOnlyTheItemsWorthALook() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        try writePlist("com.example.fine.plist", ["Label": "com.example.fine", "Program": "/Applications/Example.app/Contents/MacOS/helper"])
        try writePlist("com.example.tmp.plist", ["Label": "com.example.tmp", "ProgramArguments": ["/tmp/payload", "--quiet"]])
        try writePlist("com.example.tool.plist", ["Label": "com.example.tool", "Program": "/usr/local/bin/tool"])
        try writePlist("com.example.hidden.plist", ["Label": "com.example.hidden", "ProgramArguments": ["/bin/sh", "/Users/ana/.config/run.sh"]])
        try writePlist(".com.example.ignored.plist", ["Label": "com.example.ignored", "Program": "/tmp/ignored"])
        let unsigned = SignatureFacts(validity: .unsigned)
        let inspector = StubSignatureInspector(["/tmp/payload": unsigned, "/usr/local/bin/tool": unsigned])

        let findings = scanner(inspector: inspector).findings()

        #expect(findings.map(\.job.label) == ["com.example.hidden", "com.example.tmp", "com.example.tool"])
        #expect(findings.map(\.concerns) == [
            [.hiddenFolder],
            [.unsignedProgram, .temporaryOrSharedFolder],
            [.unsignedProgram]
        ])
    }

    @Test func attributesAFindingToItsApp() throws {
        defer { try? FileManager.default.removeItem(at: root) }
        try writePlist("com.example.tool.plist", ["Label": "com.example.tool", "Program": "/usr/local/bin/tool"])
        let inspector = StubSignatureInspector(["/usr/local/bin/tool": SignatureFacts(validity: .invalid(status: -67061))])

        let finding = try #require(scanner(inspector: inspector).findings().first)

        #expect(finding.owner == LoginItemOwner(appURL: app))
        #expect(finding.displayName == "Example")
        #expect(finding.concerns == [.damagedProgram])
        #expect(finding.scope == .currentUser)
        #expect(finding.kind == .agent)
    }

    @Test func findsNothingWithoutTheFolder() {
        #expect(scanner(inspector: StubSignatureInspector()).findings().isEmpty)
    }
}
