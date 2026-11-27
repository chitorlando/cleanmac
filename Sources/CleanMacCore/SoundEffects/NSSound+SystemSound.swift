import AppKit

extension NSSound: PlayableSound {}

extension NSSound {
    /// The sound `sound` stands for, from where macOS keeps it: its file, or the alert sound
    /// of its name when it has no file or the file can't be read. `nil` when neither is there.
    static func system(_ sound: SystemSound) -> NSSound? {
        switch sound {
        case .alert(let name):
            return NSSound(named: name)
        case .file(let url, let fallback):
            return NSSound(contentsOf: url, byReference: true) ?? NSSound(named: fallback)
        }
    }
}
