/// Reviews the security of this Mac, reporting its progress as a stream of events.
///
/// A review only reads: it never changes a setting, an app or a file, and it sends nothing
/// anywhere. Cancelling the task that reads the stream stops the review.
public protocol SecurityReviewing: Sendable {
    /// Ends with `.finished` unless the review is cancelled first.
    func review() -> AsyncStream<SecurityReviewEvent>
}

/// What a review reports while it runs.
public enum SecurityReviewEvent: Hashable, Sendable {
    /// It started looking at something else.
    case started(SecurityReviewStep)
    /// It checked another app's signature, out of how many it found.
    case checkedApps(done: Int, total: Int)
    case finished(SecurityReport)
}

/// The parts of a review, in the order it goes through them.
public enum SecurityReviewStep: CaseIterable, Hashable, Sendable {
    case protections
    case apps
    case persistence
    case permissions
}
