public extension CleanupReport {
    /// The sound effect that marks the end of the cleanup: Finder's sound for emptying the
    /// Trash when it was emptied, or else for moving items to the Trash when some were moved.
    /// `nil` when neither happened, so a cleanup where everything failed stays quiet.
    var soundEffect: SoundEffect? {
        if emptiedTrash {
            return .trashEmptied
        }
        if removedCount > 0 {
            return .cleanupFinished
        }
        return nil
    }
}
