/// Tells how much the user's Trash holds, as `TrashSizeReader` does, so that whoever shows it
/// can be checked with a Trash of its own.
public protocol TrashUsageReading: Sendable {
    /// The bins that hold something, or `.unreadable` when macOS keeps CleanMac out of the Trash.
    /// It may take a while on a full Trash, so it's best called away from the main thread.
    func read() -> TrashUsage
}

extension TrashSizeReader: TrashUsageReading {}
