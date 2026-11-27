import CleanMacCore
import Combine

/// Records each sound effect a publisher sends from now on, in order, for as long as it's kept.
@MainActor
final class SoundEffectRecorder {
    private(set) var recorded: [SoundEffect] = []
    private var subscription: AnyCancellable?

    init(_ soundEffects: AnyPublisher<SoundEffect, Never>) {
        subscription = soundEffects.sink { [unowned self] effect in
            recorded.append(effect)
        }
    }
}
