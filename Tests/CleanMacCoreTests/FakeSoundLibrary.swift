@testable import CleanMacCore

/// A sound that plays nothing: it counts how many times it started, and plays until told it
/// finished.
@MainActor
final class FakePlayableSound: PlayableSound {
    private(set) var starts = 0
    private(set) var isPlaying = false

    func play() -> Bool {
        guard !isPlaying else { return false }
        starts += 1
        isPlaying = true
        return true
    }

    func finish() {
        isPlaying = false
    }
}

/// Loads a `FakePlayableSound` for each sound of macOS, the same one each time, and notes
/// each load. The sounds in `missing` aren't there.
@MainActor
final class FakeSoundLibrary {
    var missing: Set<SystemSound> = []
    private(set) var loads: [SystemSound] = []
    private var sounds: [SystemSound: FakePlayableSound] = [:]

    func load(_ systemSound: SystemSound) -> (any PlayableSound)? {
        loads.append(systemSound)
        guard !missing.contains(systemSound) else { return nil }
        return sound(systemSound)
    }

    /// The sound handed out for `systemSound`.
    func sound(_ systemSound: SystemSound) -> FakePlayableSound {
        if let sound = sounds[systemSound] {
            return sound
        }
        let sound = FakePlayableSound()
        sounds[systemSound] = sound
        return sound
    }
}
