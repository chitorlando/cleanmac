import CleanMacCore
import Foundation
import Testing

struct SoundEffectSystemSoundTests {
    /// The alert sounds of macOS 13 and later, in `/System/Library/Sounds`.
    private static let alertSounds: Set<String> = [
        "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    ]

    @Test func endsAScanWithASoftTick() {
        #expect(SoundEffect.scanFinished.systemSound == .alert("Tink"))
    }

    @Test func playsTheSoundOfFinderWhenItemsGoToTheTrash() {
        #expect(SoundEffect.cleanupFinished.systemSound == .moveToTrash)
        #expect(SoundEffect.appUninstalled.systemSound == .moveToTrash)
    }

    @Test func playsTheSoundOfFinderWhenTheTrashIsEmptied() {
        #expect(SoundEffect.trashEmptied.systemSound == .emptyTrash)
    }

    @Test func endsMaintenanceWithABrighterSound() {
        #expect(SoundEffect.maintenanceFinished.systemSound == .alert("Hero"))
    }

    /// A success never sounds like a warning.
    @Test func keepsTheLowSoundForThreats() {
        let successes = SoundEffect.allCases.filter { $0 != .threatFound }
        let soundsOfSuccesses = successes.map { $0.systemSound }

        #expect(SoundEffect.threatFound.systemSound == .alert("Basso"))
        #expect(!soundsOfSuccesses.contains(.alert("Basso")))
    }

    /// Where Finder keeps its sounds isn't public, so each one has an alert sound to play when
    /// it's missing.
    @Test func fallsBackFromTheSoundsOfFinderToAlertSounds() {
        let finder = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/finder"

        #expect(pathAndFallback(of: .moveToTrash) == ["\(finder)/move to trash.aif", "Pop"])
        #expect(pathAndFallback(of: .emptyTrash) == ["\(finder)/empty trash.aif", "Glass"])
    }

    @Test(arguments: SoundEffect.allCases)
    func playsOnlySoundsThatComeWithMacOS(_ effect: SoundEffect) {
        switch effect.systemSound {
        case .alert(let name):
            #expect(Self.alertSounds.contains(name))
        case .file(let url, let fallback):
            #expect(url.deletingLastPathComponent().path == SystemSound.finderSounds.path)
            #expect(Self.alertSounds.contains(fallback))
        }
    }

    /// The path of the file of `sound` and the alert sound that falls back for it, or nothing
    /// for an alert sound.
    private func pathAndFallback(of sound: SystemSound) -> [String] {
        guard case .file(let url, let fallback) = sound else { return [] }
        return [url.path, fallback]
    }
}
