import Combine
import Foundation

/// Coordinates the security review: starting it, following its progress and showing what it
/// found. The review only reads, so there is nothing to select or confirm.
@MainActor
public final class SecurityViewModel: ObservableObject {
    @Published public private(set) var phase: SecurityPhase = .intro
    @Published public private(set) var progress = SecurityReviewProgress()

    private let reviewer: any SecurityReviewing
    private var activeTask: Task<Void, Never>?

    public init(reviewer: any SecurityReviewing) {
        self.reviewer = reviewer
    }

    /// What the last review found, while its results are shown.
    public var report: SecurityReport? {
        guard case .results(let report) = phase else { return nil }
        return report
    }

    // MARK: Actions

    /// Starts a review, stopping one already running.
    @discardableResult
    public func startReview() -> Task<Void, Never> {
        activeTask?.cancel()
        progress = SecurityReviewProgress()
        phase = .reviewing
        let events = reviewer.review()
        let task = Task {
            for await event in events {
                guard !Task.isCancelled else { return }
                apply(event)
            }
        }
        activeTask = task
        return task
    }

    /// Stops the review and goes back to the introduction.
    public func cancelReview() {
        activeTask?.cancel()
        activeTask = nil
        phase = .intro
    }

    /// Leaves the results and goes back to the introduction.
    public func done() {
        activeTask?.cancel()
        activeTask = nil
        phase = .intro
    }

    // MARK: Private

    private func apply(_ event: SecurityReviewEvent) {
        switch event {
        case .started(let step):
            progress.step = step
        case .checkedApps(let done, let total):
            progress.checkedApps = done
            progress.appCount = total
        case .finished(let report):
            phase = .results(report)
        }
    }
}
