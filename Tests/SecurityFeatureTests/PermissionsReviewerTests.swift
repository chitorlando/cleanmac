import CleanMacCore
import Foundation
import SecurityFeature
import Testing

/// Answers each database with fixed grants, or as unreadable when it has none configured.
struct StubPermissionDatabases: PermissionDatabaseReading {
    let grantsByPath: [String: [PermissionGrant]]

    func grants(in database: URL) -> [PermissionGrant]? {
        grantsByPath[database.path]
    }
}

struct PermissionsReviewerTests {
    private let userDatabase = URL(filePath: "/Users/ana/Library/Application Support/com.apple.TCC/TCC.db")
    private let systemDatabase = URL(filePath: "/Library/Application Support/com.apple.TCC/TCC.db")
    private let backup = URL(filePath: "/Applications/Backup.app")
    private let recorder = URL(filePath: "/Applications/Recorder.app")

    private func reviewer(
        _ grantsByPath: [String: [PermissionGrant]],
        inspector: StubSignatureInspector = StubSignatureInspector()
    ) -> PermissionsReviewer {
        PermissionsReviewer(
            databases: [userDatabase, systemDatabase],
            reader: StubPermissionDatabases(grantsByPath: grantsByPath),
            appLocator: StubAppLocator(apps: ["com.example.backup": backup, "com.example.recorder": recorder]),
            files: StubDirectoryReader(tree: [
                "/Applications": ["Recorder.app"],
                "/Applications/Recorder.app/Contents/MacOS": ["helper"],
                "/usr/local/bin": ["capture"]
            ]),
            inspector: inspector
        )
    }

    @Test func groupsTheAppsByPermissionInTheOrderOfPrivacyAndSecurity() {
        let review = reviewer([
            userDatabase.path: [PermissionGrant(permission: .microphone, client: .bundleID("com.example.recorder"))],
            systemDatabase.path: [
                PermissionGrant(permission: .screenRecording, client: .bundleID("com.example.recorder")),
                PermissionGrant(permission: .fullDiskAccess, client: .bundleID("com.example.backup")),
                PermissionGrant(permission: .screenRecording, client: .bundleID("com.example.backup"))
            ]
        ]).review(knownApps: [])

        #expect(review.availability == .complete)
        #expect(review.groups.map(\.permission) == [.fullDiskAccess, .screenRecording, .microphone])
        #expect(review.groups[1].clients.map(\.name) == ["Backup", "Recorder"])
        #expect(review.clientsNeedingAttention.isEmpty)
    }

    @Test func isUnavailableWhenNoDatabaseCanBeRead() {
        let review = reviewer([:]).review(knownApps: [])

        #expect(review == PermissionsReview(availability: .unavailable))
    }

    @Test func isPartialWhenSomeDatabaseCannotBeRead() {
        let review = reviewer([userDatabase.path: []]).review(knownApps: [])

        #expect(review.availability == .partial)
        #expect(review.groups.isEmpty)
    }

    @Test func findsTheAppAProgramIsPartOfAndKeepsLooseProgramsAsTheyAre() {
        let review = reviewer([systemDatabase.path: [
            PermissionGrant(permission: .accessibility, client: .path("/Applications/Recorder.app/Contents/MacOS/helper")),
            PermissionGrant(permission: .accessibility, client: .path("/usr/local/bin/capture")),
            PermissionGrant(permission: .accessibility, client: .path("/usr/local/bin/gone"))
        ]]).review(knownApps: [])

        let clients = review.groups.first?.clients ?? []
        #expect(clients.map(\.name) == ["/usr/local/bin/gone", "capture", "Recorder"])
        #expect(clients.map(\.url) == [nil, URL(filePath: "/usr/local/bin/capture"), recorder])
    }

    @Test func flagsOnlyAppsWhoseSignatureIsMissingOrDamaged() {
        let inspector = StubSignatureInspector([
            recorder.path: SignatureFacts(validity: .unsigned),
            backup.path: StubSignatureInspector.adHoc
        ])
        let review = reviewer([systemDatabase.path: [
            PermissionGrant(permission: .screenRecording, client: .bundleID("com.example.recorder")),
            PermissionGrant(permission: .inputMonitoring, client: .bundleID("com.example.recorder")),
            PermissionGrant(permission: .fullDiskAccess, client: .bundleID("com.example.backup"))
        ]], inspector: inspector).review(knownApps: [])

        #expect(review.clientsNeedingAttention.map(\.name) == ["Recorder"])
    }

    @Test func reusesTheSignaturesAlreadyChecked() {
        let inspector = StubSignatureInspector([recorder.path: SignatureFacts(validity: .unsigned)])
        let review = reviewer(
            [systemDatabase.path: [PermissionGrant(permission: .camera, client: .bundleID("com.example.recorder"))]],
            inspector: inspector
        ).review(knownApps: [AppSignatureCheck(url: recorder, signature: .damaged)])

        #expect(review.groups.first?.clients.first?.signature == .damaged)
    }

    @Test func leavesOutOfTheCountTheAppsAlreadyFlagged() {
        let recorderClient = PermissionClient(identifier: "com.example.recorder", name: "Recorder", url: recorder, signature: .unsigned)
        let loose = PermissionClient(identifier: "/tmp/tool", name: "tool", url: URL(filePath: "/tmp/tool"), signature: .unsigned)
        let report = SecurityReport(
            apps: [AppSignatureCheck(url: recorder, signature: .unsigned)],
            permissions: PermissionsReview(availability: .complete, groups: [
                PermissionGroup(permission: .camera, clients: [loose, recorderClient])
            ])
        )

        #expect(report.permissionClientsNeedingAttention == [loose])
        #expect(report.attentionCount == 2)
    }
}
