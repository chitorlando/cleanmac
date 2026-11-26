/// Goes through each part of the review in turn and gathers what they found.
public struct SecurityReviewer: SecurityReviewing {
    private let protections: any ProtectionReading

    public init(protections: any ProtectionReading) {
        self.protections = protections
    }

    public func review() -> AsyncStream<SecurityReviewEvent> {
        let reviewer = self
        return AsyncStream { continuation in
            let task = Task {
                await reviewer.run(reportingTo: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(reportingTo continuation: AsyncStream<SecurityReviewEvent>.Continuation) async {
        continuation.yield(.started(.protections))
        let protectionChecks = await protections.protections()
        guard !Task.isCancelled else { return }

        continuation.yield(.finished(SecurityReport(protections: protectionChecks)))
    }
}
