import CleanMacCore
import Observation

/// Coordinates scanning, selection and cleanup for the system junk screen.
@MainActor
@Observable
public final class SystemJunkViewModel {
    public private(set) var phase: SystemJunkPhase = .idle
    public private(set) var results: [CategoryScanResult] = []
    public private(set) var selection = ItemSelection()
    public private(set) var scannedCategoryCount = 0

    private let scanService: JunkScanService
    private let cleanupService: CleanupService
    @ObservationIgnored private var activeTask: Task<Void, Never>?

    public init(scanService: JunkScanService, cleanupService: CleanupService) {
        self.scanService = scanService
        self.cleanupService = cleanupService
    }

    // MARK: Derived state

    public var scanProgress: Double {
        guard scanService.categoryCount > 0 else { return 0 }
        return Double(scannedCategoryCount) / Double(scanService.categoryCount)
    }

    public var foundSize: Int64 { allItems.totalSize }
    public var selectedSize: Int64 { selectedItems.totalSize }
    public var hasSelection: Bool { !selection.isEmpty }

    private var allItems: [CleanableItem] { results.flatMap(\.items) }
    private var selectedItems: [CleanableItem] { selection.selectedItems(in: allItems) }

    // MARK: Actions

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        results = []
        selection = ItemSelection()
        scannedCategoryCount = 0
        phase = .scanning
        let task = Task { await runScan() }
        activeTask = task
        return task
    }

    public func cancelScan() {
        activeTask?.cancel()
        phase = .idle
    }

    @discardableResult
    public func clean() -> Task<Void, Never>? {
        let items = selectedItems
        guard !items.isEmpty else { return nil }
        phase = .cleaning
        let task = Task {
            let report = await cleanupService.clean(items)
            guard !Task.isCancelled else { return }
            phase = .finished(report)
        }
        activeTask = task
        return task
    }

    public func reset() {
        results = []
        selection = ItemSelection()
        phase = .idle
    }

    // MARK: Selection

    public func isSelected(_ item: CleanableItem) -> Bool {
        selection.contains(item)
    }

    public func selectionState(of result: CategoryScanResult) -> ItemSelection.State {
        selection.state(of: result.items)
    }

    public func toggle(_ item: CleanableItem) {
        selection.toggle(item)
    }

    public func toggle(_ result: CategoryScanResult) {
        selection.toggleAll(result.items)
    }

    // MARK: Private

    private func runScan() async {
        for await result in scanService.scan() {
            guard !Task.isCancelled else { return }
            scannedCategoryCount += 1
            guard !result.items.isEmpty else { continue }
            results.append(result)
            selection.select(result.items)
        }
        guard !Task.isCancelled else { return }
        results.sort { $0.totalSize > $1.totalSize }
        phase = .review
    }
}
