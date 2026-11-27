import CleanMacCore
import os

/// Tells whatever it's set to about the sound effects of the interface of macOS.
final class StubUserInterfaceSounds: UserInterfaceSoundsReading {
    private let plays: OSAllocatedUnfairLock<Bool>

    init(plays: Bool = true) {
        self.plays = OSAllocatedUnfairLock(initialState: plays)
    }

    var playsUserInterfaceSounds: Bool {
        plays.withLock { $0 }
    }

    /// Turns the sound effects of macOS on or off, as the user would in the Sound settings.
    func set(plays newValue: Bool) {
        plays.withLock { $0 = newValue }
    }
}
