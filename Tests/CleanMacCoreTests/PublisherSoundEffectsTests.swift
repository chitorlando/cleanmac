import CleanMacCore
import Combine
import Testing

@MainActor
struct PublisherSoundEffectsTests {
    /// Steps of a screen that scans.
    private enum Phase {
        case intro
        case scanning
        case results

        /// The end of a scan plays its sound, and nothing else does.
        func soundEffect(movingTo next: Phase) -> SoundEffect? {
            self == .scanning && next == .results ? .scanFinished : nil
        }
    }

    /// A screen model that publishes its phase, as the view models of the features do.
    private final class PhaseModel: ObservableObject {
        @Published var phase = Phase.intro
    }

    private let spy = SpySoundEffectPlayer()

    @Test func playsTheEffectOfEachChangeThatCallsForOne() {
        let phases = PassthroughSubject<Phase, Never>()
        let subscription = phases.soundEffects { $0.soundEffect(movingTo: $1) }.sink { [spy] in spy.play($0) }

        for phase in [Phase.intro, .scanning, .results, .intro, .scanning, .results] {
            phases.send(phase)
        }

        #expect(spy.played == [.scanFinished, .scanFinished])
        subscription.cancel()
    }

    /// A screen shown again with its results doesn't sound again.
    @Test func playsNothingForTheValueItStartsFrom() {
        let phases = CurrentValueSubject<Phase, Never>(.results)
        var changes: [[Phase]] = []

        let subscription = phases.soundEffects { old, new in
            changes.append([old, new])
            return nil
        }
        .sink { [spy] in spy.play($0) }

        #expect(changes.isEmpty)
        #expect(spy.played.isEmpty)
        subscription.cancel()
    }

    @Test func handsOverTheValueBeforeAndTheNewOne() {
        let phases = PassthroughSubject<Phase, Never>()
        var changes: [[Phase]] = []
        let subscription = phases.soundEffects { old, new in
            changes.append([old, new])
            return nil
        }
        .sink { [spy] in spy.play($0) }

        for phase in [Phase.intro, .scanning, .results] {
            phases.send(phase)
        }

        #expect(changes == [[.intro, .scanning], [.scanning, .results]])
        subscription.cancel()
    }

    /// `@Published` sends a value each time a property is set, even to what it already was.
    @Test func playsOncePerChangeWhenAPropertyIsSetAgainToTheSameValue() {
        let model = PhaseModel()
        let subscription = model.$phase.soundEffects { $0.soundEffect(movingTo: $1) }.sink { [spy] in spy.play($0) }

        model.phase = .scanning
        model.phase = .results
        model.phase = .results
        model.phase = .results

        #expect(spy.played == [.scanFinished])
        subscription.cancel()
    }

    /// Refreshing what's on screen leaves the phase as it is, so it plays nothing.
    @Test func playsNothingWhileThePhaseStaysTheSame() {
        let model = PhaseModel()
        model.phase = .results
        let subscription = model.$phase.soundEffects { $0.soundEffect(movingTo: $1) }.sink { [spy] in spy.play($0) }

        model.phase = .results

        #expect(spy.played.isEmpty)
        subscription.cancel()
    }
}
