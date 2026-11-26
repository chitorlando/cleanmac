import CleanMacCore
import Combine
import Foundation

/// Coordinates scanning, selection and cleanup for the system junk screen.
///
/// Most junk is safe to remove, so its items are selected after a scan, except the caches an
/// open browser is using: they're shown but locked until the user quits it. The user picks the
/// items of the other categories, such as the Trash, whose bins are erased for good.
@MainActor
public final class SystemJunkViewModel: ObservableObject {
    @Published public private(set) var phase: SystemJunkPhase = .idle
    @Published public private(set) var results: [CategoryScanResult] = []
    @Published public private(set) var selection = ItemSelection()
    @Published public private(set) var scannedCategoryCount = 0
    /// Whether the user is asked to confirm what `clean()` does: emptying the Trash, moving the
    /// selected junk to it, or both.
    @Published public private(set) var isConfirmingClean = false
    /// The open browsers that lock each item they may be using, as of the last check.
    @Published public private(set) var openAppsByItem: [CleanableItem.ID: [RunningApp]] = [:]

    private let scanService: JunkScanService
    private let cleanupService: CleanupService
    private let trashEmptying: TrashEmptyingService
    private let runningApps: any RunningAppsProviding
    private let cacheUsage: BrowserCacheUsage
    private var activeTask: Task<Void, Never>?

    public init(
        scanService: JunkScanService,
        cleanupService: CleanupService,
        trashEmptying: TrashEmptyingService,
        runningApps: any RunningAppsProviding,
        cacheUsage: BrowserCacheUsage
    ) {
        self.scanService = scanService
        self.cleanupService = cleanupService
        self.trashEmptying = trashEmptying
        self.runningApps = runningApps
        self.cacheUsage = cacheUsage
    }

    // MARK: Derived state

    public var scanProgress: Double {
        guard scanService.categoryCount > 0 else { return 0 }
        return Double(scannedCategoryCount) / Double(scanService.categoryCount)
    }

    public var foundSize: Int64 { allItems.totalSize }

    /// Items that `clean()` would remove: selected and not locked by an open browser.
    public var selectedItems: [CleanableItem] {
        selection.selectedItems(in: allItems).filter { canSelect($0) }
    }

    /// Selected Trash bins, which `clean()` empties for good before it moves anything to the Trash.
    public var binsToEmpty: [CleanableItem] { selectedItems(removedBy: .emptyTrash) }

    /// Selected items that `clean()` moves to the Trash, where the user can put them back.
    public var itemsToMove: [CleanableItem] { selectedItems(removedBy: .moveToTrash) }

    /// Whether `clean()` would empty the Trash, which can't be undone.
    public var emptiesTrash: Bool { !binsToEmpty.isEmpty }

    public var selectedSize: Int64 { selectedItems.totalSize }
    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    private var allItems: [CleanableItem] { results.flatMap(\.items) }

    // MARK: Actions

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        results = []
        selection = ItemSelection()
        openAppsByItem = [:]
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

    /// Asks the user to confirm the cleanup, and removes nothing.
    ///
    /// The clean button calls it, also when Return presses that button. Which browsers are
    /// open is checked first, so the question leaves out the caches they're using.
    public func requestClean() {
        refreshOpenApps()
        guard phase == .review, hasSelection else { return }
        isConfirmingClean = true
    }

    /// Stops asking for confirmation, without removing anything.
    public func cancelClean() {
        if isConfirmingClean { isConfirmingClean = false }
    }

    /// Empties the Trash if its bins are selected, then moves the selected items that no open
    /// browser is using to the Trash, once the user confirmed it (see `requestClean()`).
    ///
    /// The Trash is emptied first, so what the cleanup moves to it can still be put back.
    @discardableResult
    public func clean() -> Task<Void, Never>? {
        if isConfirmingClean { isConfirmingClean = false }
        refreshOpenApps()
        let bins = binsToEmpty
        let items = itemsToMove
        guard !bins.isEmpty || !items.isEmpty else { return nil }
        phase = .cleaning
        let task = Task {
            var report = await trashEmptying.empty(bins)
            report.merge(await cleanupService.clean(items))
            guard !Task.isCancelled else { return }
            phase = .finished(report)
        }
        activeTask = task
        return task
    }

    public func reset() {
        results = []
        selection = ItemSelection()
        openAppsByItem = [:]
        phase = .idle
    }

    // MARK: Open browsers

    /// The open browsers that may be using the item, which stays locked until they quit.
    public func openApps(using item: CleanableItem) -> [RunningApp] {
        openAppsByItem[item.id] ?? []
    }

    /// The open browsers that lock items of the category, by name.
    public func openApps(lockingItemsOf result: CategoryScanResult) -> [RunningApp] {
        Set(result.items.flatMap(openApps(using:))).sorted { $0.name < $1.name }
    }

    /// Checks which browsers are open and unselects the items they may be using. An item
    /// whose browser has quit can be selected again, but that's left to the user.
    public func refreshOpenApps() {
        let openApps = runningApps.openApps()
        openAppsByItem = allItems.reduce(into: [:]) { locked, item in
            let apps = cacheUsage.apps(using: item.url, among: openApps).sorted { $0.name < $1.name }
            if !apps.isEmpty { locked[item.id] = apps }
        }
        selection.deselect(allItems.filter { !canSelect($0) })
    }

    // MARK: Selection

    public func canSelect(_ item: CleanableItem) -> Bool {
        openAppsByItem[item.id] == nil
    }

    /// Whether the category has any item that isn't locked.
    public func canSelectItems(of result: CategoryScanResult) -> Bool {
        result.items.contains { canSelect($0) }
    }

    public func isSelected(_ item: CleanableItem) -> Bool {
        canSelect(item) && selection.contains(item)
    }

    /// The state of the items of the category that can be selected.
    public func selectionState(of result: CategoryScanResult) -> ItemSelection.State {
        selection.state(of: result.items.filter { canSelect($0) })
    }

    /// Toggles the item, or every Trash bin when it's one: Finder empties them all at once.
    public func toggle(_ item: CleanableItem) {
        guard canSelect(item) else { return }
        if let trash = results.first(where: { $0.category.removal == .emptyTrash && $0.items.contains(item) }) {
            toggle(trash)
        } else {
            selection.toggle(item)
        }
    }

    public func toggle(_ result: CategoryScanResult) {
        selection.toggleAll(result.items.filter { canSelect($0) })
    }

    // MARK: Private

    private func selectedItems(removedBy removal: JunkRemoval) -> [CleanableItem] {
        let items = results.filter { $0.category.removal == removal }.flatMap(\.items)
        return selection.selectedItems(in: items).filter { canSelect($0) }
    }

    private func runScan() async {
        for await result in scanService.scan() {
            guard !Task.isCancelled else { return }
            scannedCategoryCount += 1
            guard !result.items.isEmpty || result.needsFullDiskAccess else { continue }
            results.append(result)
            if result.category.preselectsItems {
                selection.select(result.items)
            }
            refreshOpenApps()
        }
        guard !Task.isCancelled else { return }
        results.sort { $0.totalSize > $1.totalSize }
        phase = .review
    }
}
