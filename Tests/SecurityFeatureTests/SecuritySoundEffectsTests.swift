import CleanMacCore
import SecurityFeature
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct SecuritySoundEffectsTests {
    private let report = SecurityReport(protections: [ProtectionCheck(kind: .fileVault, state: .off)])

    // MARK: Phases

    @Test func theEndOfAReviewPlaysItsSound() {
        #expect(SecurityPhase.reviewing.soundEffect(movingTo: .results(report)) == .scanFinished)
    }

    @Test func otherMovesPlayNothing() {
        #expect(SecurityPhase.intro.soundEffect(movingTo: .reviewing) == nil)
        #expect(SecurityPhase.reviewing.soundEffect(movingTo: .intro) == nil)
        #expect(SecurityPhase.results(report).soundEffect(movingTo: .intro) == nil)
        #expect(SecurityPhase.results(report).soundEffect(movingTo: .reviewing) == nil)
    }

    // MARK: Module

    /// The progress of a review moves on without its phase changing.
    @Test func playsOnceForEachReview() async {
        let viewModel = SecurityViewModel(reviewer: StubSecurityReviewer(events: [
            .started(.protections),
            .checkedApps(done: 1, total: 2),
            .checkedApps(done: 2, total: 2),
            .finished(report)
        ]))
        let recorder = SoundEffectRecorder(SecurityModule(viewModel: viewModel).soundEffects)

        await viewModel.startReview().value
        viewModel.done()
        await viewModel.startReview().value

        #expect(recorder.recorded == [.scanFinished, .scanFinished])
    }
}
