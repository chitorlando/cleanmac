import CleanMacCore

/// Runs every scanner in parallel and reports each category as soon as it finishes.
public struct JunkScanService: Sendable {
    private let scanners: [any JunkScanner]

    public init(scanners: [any JunkScanner]) {
        self.scanners = scanners
    }

    public var categoryCount: Int { scanners.count }

    public func scan() -> AsyncStream<CategoryScanResult> {
        let scanners = scanners
        return AsyncStream { continuation in
            let task = Task {
                await withTaskGroup(of: CategoryScanResult.self) { group in
                    for scanner in scanners {
                        group.addTask {
                            CategoryScanResult(category: scanner.category, items: await scanner.scan())
                        }
                    }
                    for await result in group {
                        continuation.yield(result)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
