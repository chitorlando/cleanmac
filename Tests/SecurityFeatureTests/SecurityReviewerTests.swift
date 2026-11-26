import CleanMacCore
import Foundation
import SecurityFeature
import Testing

@Suite(.timeLimit(.minutes(1)))
struct SecurityReviewerTests {
    private let apps = (1...10).map { URL(filePath: "/Applications/App \($0).app") }
    private let protections = [ProtectionCheck(kind: .firewall, state: .off)]
    private let persistence = [
        PersistenceFinding(
            plistURL: URL(filePath: "/Library/LaunchDaemons/com.example.plist"),
            job: LaunchJobDefinition(label: "com.example", programPath: "/tmp/x", runsAtLoad: true, keepsAlive: true, isDisabled: false),
            kind: .daemon,
            scope: .allUsers,
            owner: nil,
            concerns: [.temporaryOrSharedFolder]
        )
    ]

    private func reviewer(inspector: StubSignatureInspector = StubSignatureInspector()) -> SecurityReviewer {
        SecurityReviewer(
            protections: StubProtectionReader(checks: protections),
            appFinder: StubAppFinder(urls: apps),
            signatureChecker: AppSignatureChecker(inspector: inspector, gatekeeper: SpyGatekeeper()),
            persistence: StubPersistenceScanner(results: persistence),
            maximumConcurrentChecks: 3
        )
    }

    private func events(of reviewer: SecurityReviewer) async -> [SecurityReviewEvent] {
        var events: [SecurityReviewEvent] = []
        for await event in reviewer.review() {
            events.append(event)
        }
        return events
    }

    @Test func goesThroughEachStepAndFinishesWithTheReport() async throws {
        let unsigned = SignatureFacts(validity: .unsigned)
        let inspector = StubSignatureInspector([apps[4].path: unsigned])

        let events = await events(of: reviewer(inspector: inspector))

        #expect(events.first == .started(.protections))
        let steps = events.compactMap { event -> SecurityReviewStep? in
            guard case .started(let step) = event else { return nil }
            return step
        }
        #expect(steps == SecurityReviewStep.allCases)
        guard case .finished(let report) = try #require(events.last) else {
            Issue.record("The review didn't finish with its report")
            return
        }
        #expect(report.protections == protections)
        #expect(report.apps.map(\.url) == apps)
        #expect(report.appsNeedingAttention.map(\.url) == [apps[4]])
        #expect(report.persistence == persistence)
        #expect(report.attentionCount == 3)
    }

    @Test func reportsEachAppItChecks() async {
        let progress = await events(of: reviewer()).compactMap { event -> Int? in
            guard case .checkedApps(let done, let total) = event, total == apps.count else { return nil }
            return done
        }

        #expect(progress == Array(0...apps.count))
    }

    @Test func checksOnlyAFewAppsAtOnce() async {
        let inspector = StubSignatureInspector()

        _ = await events(of: reviewer(inspector: inspector))

        #expect(inspector.mostRunningAtOnce <= 3)
    }
}
