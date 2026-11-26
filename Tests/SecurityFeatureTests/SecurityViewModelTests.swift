import Foundation
import SecurityFeature
import Testing

/// Replays a fixed list of events, or never finishes when told to hang.
struct StubSecurityReviewer: SecurityReviewing {
    var events: [SecurityReviewEvent] = []
    var hangs = false

    func review() -> AsyncStream<SecurityReviewEvent> {
        let events = events
        let hangs = hangs
        return AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            if !hangs {
                continuation.finish()
            }
        }
    }
}

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SecurityViewModelTests {
    private let report = SecurityReport(protections: [
        ProtectionCheck(kind: .fileVault, state: .off),
        ProtectionCheck(kind: .gatekeeper, state: .on)
    ])

    @Test func startsOnTheIntroduction() {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer())

        #expect(viewModel.phase == .intro)
        #expect(viewModel.report == nil)
    }

    @Test func showsWhatTheReviewFound() async {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer(events: [
            .started(.protections),
            .finished(report)
        ]))

        await viewModel.startReview().value

        #expect(viewModel.phase == .results(report))
        #expect(viewModel.report?.attentionCount == 1)
        #expect(viewModel.report?.protectionsNeedingAttention.map(\.kind) == [.fileVault])
    }

    @Test func followsTheProgressOfTheReview() async {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer(
            events: [.started(.protections), .checkedApps(done: 3, total: 4)],
            hangs: true
        ))

        let task = viewModel.startReview()
        while viewModel.progress.checkedApps < 3 {
            await Task.yield()
        }

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.progress.appCount == 4)
        viewModel.cancelReview()
        await task.value
    }

    @Test func goesBackToTheIntroductionWhenCancelled() async {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer(hangs: true))

        let task = viewModel.startReview()
        #expect(viewModel.phase == .reviewing)
        viewModel.cancelReview()
        await task.value

        #expect(viewModel.phase == .intro)
    }

    @Test func goesBackToTheIntroductionWhenDone() async {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer(events: [.finished(report)]))
        await viewModel.startReview().value

        viewModel.done()

        #expect(viewModel.phase == .intro)
    }

    @Test func startsOverWhenReviewedAgain() async {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer(events: [
            .checkedApps(done: 2, total: 2),
            .finished(report)
        ]))
        await viewModel.startReview().value

        let task = viewModel.startReview()

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.progress == SecurityReviewProgress())
        await task.value
        #expect(viewModel.phase == .results(report))
    }
}
