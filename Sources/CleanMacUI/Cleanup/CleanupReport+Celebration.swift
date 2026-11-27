import CleanMacCore

public extension CleanupReport {
    /// Whether the cleanup did everything it was asked to, and did something at all: only then
    /// does its end deserve a celebration. A cleanup that left items behind, or couldn't empty
    /// the Trash, is reported without one.
    var isCompleteSuccess: Bool {
        failures.isEmpty && (removedCount > 0 || emptiedTrash)
    }
}
