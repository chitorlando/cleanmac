import Foundation

/// Goes through each part of the review in turn and gathers what they found.
public struct SecurityReviewer: SecurityReviewing {
    private let protections: any ProtectionReading
    private let appFinder: any AppFinding
    private let signatureChecker: AppSignatureChecker
    private let persistence: any PersistenceScanning
    private let maximumConcurrentChecks: Int

    /// - Parameter maximumConcurrentChecks: How many signatures are checked at once. Each check
    ///   reads a whole app from disk, so a few at a time keep the Mac responsive.
    public init(
        protections: any ProtectionReading,
        appFinder: any AppFinding,
        signatureChecker: AppSignatureChecker,
        persistence: any PersistenceScanning,
        maximumConcurrentChecks: Int = min(4, ProcessInfo.processInfo.activeProcessorCount)
    ) {
        self.protections = protections
        self.appFinder = appFinder
        self.signatureChecker = signatureChecker
        self.persistence = persistence
        self.maximumConcurrentChecks = max(1, maximumConcurrentChecks)
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

        continuation.yield(.started(.apps))
        let apps = appFinder.apps()
        continuation.yield(.checkedApps(done: 0, total: apps.count))
        let appChecks = await checkSignatures(of: apps, reportingTo: continuation)
        guard !Task.isCancelled else { return }

        continuation.yield(.started(.persistence))
        let persistenceFindings = persistence.findings()
        guard !Task.isCancelled else { return }

        continuation.yield(.finished(SecurityReport(
            protections: protectionChecks,
            apps: appChecks,
            persistence: persistenceFindings
        )))
    }

    /// Checks a few apps at a time, reporting each one, and returns them in the order given.
    /// Once cancelled, it starts no more checks.
    private func checkSignatures(
        of apps: [URL],
        reportingTo continuation: AsyncStream<SecurityReviewEvent>.Continuation
    ) async -> [AppSignatureCheck] {
        let checker = signatureChecker
        let limit = maximumConcurrentChecks
        let checks = await withTaskGroup(of: AppSignatureCheck.self, returning: [AppSignatureCheck].self) { group in
            var pending = apps[...]
            var checks: [AppSignatureCheck] = []
            for _ in 0..<limit {
                guard let url = pending.popFirst() else { break }
                group.addTask { checker.check(url) }
            }
            for await check in group {
                checks.append(check)
                continuation.yield(.checkedApps(done: checks.count, total: apps.count))
                if !Task.isCancelled, let url = pending.popFirst() {
                    group.addTask { checker.check(url) }
                }
            }
            return checks
        }
        let order = Dictionary(apps.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return checks.sorted { (order[$0.url] ?? 0) < (order[$1.url] ?? 0) }
    }
}
