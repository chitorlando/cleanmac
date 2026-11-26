import CleanMacCore
import Combine
import Foundation

/// Coordinates scanning, selection and cleanup for the browser caches screen.
///
/// Caches are safe to clear, so every item is selected after a scan, except those of a
/// browser that is open: they're locked until the user quits it, which never force-quits.
@MainActor
public final class PrivacyViewModel: ObservableObject {
    @Published public private(set) var phase: PrivacyPhase = .intro
    @Published public private(set) var results: [BrowserCaches] = []
    @Published public private(set) var selection = ItemSelection()
    @Published public private(set) var runningBrowserIDs: Set<BrowserCaches.ID> = []
    @Published public private(set) var quittingBrowserIDs: Set<BrowserCaches.ID> = []
    /// Whether the user is asked to confirm moving the selected caches to the Trash, which
    /// `clean()` does.
    @Published public private(set) var isConfirmingClean = false

    private let scanner: any BrowserCacheScanning
    private let runningApps: any RunningAppsProviding
    private let cleanupService: CleanupService
    private var activeTask: Task<Void, Never>?

    public init(scanner: any BrowserCacheScanning, runningApps: any RunningAppsProviding, cleanupService: CleanupService) {
        self.scanner = scanner
        self.runningApps = runningApps
        self.cleanupService = cleanupService
    }

    // MARK: Derived state

    public var foundSize: Int64 { results.map(\.totalSize).reduce(0, +) }

    /// Items that `clean()` would move to the Trash: selected and not locked by an open browser.
    public var selectedItems: [CleanableItem] {
        results.filter { !isRunning($0) }.flatMap { selection.selectedItems(in: $0.items) }
    }

    public var selectedSize: Int64 { selectedItems.totalSize }
    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        results = []
        selection = ItemSelection()
        runningBrowserIDs = []
        phase = .scanning
        let task = Task {
            let found = await scanner.scan()
            guard !Task.isCancelled else { return }
            results = found.sorted { $0.totalSize > $1.totalSize }
            selection.select(found.flatMap(\.items))
            refreshRunningBrowsers()
            phase = .review
        }
        activeTask = task
        return task
    }

    public func cancelScan() {
        activeTask?.cancel()
        phase = .intro
    }

    /// Asks the user to confirm moving the selected caches to the Trash, and removes nothing.
    /// Caches of a browser opened since the scan are left out first, as `clean()` does.
    ///
    /// The clear button calls it, also when Return presses that button.
    public func requestClean() {
        guard phase == .review else { return }
        refreshRunningBrowsers()
        guard hasSelection else { return }
        isConfirmingClean = true
    }

    /// Stops asking for confirmation, without removing anything.
    public func cancelClean() {
        isConfirmingClean = false
    }

    /// Moves the selected caches of browsers that are not open to the Trash, once the user
    /// confirmed it (see `requestClean()`).
    @discardableResult
    public func clean() -> Task<Void, Never>? {
        isConfirmingClean = false
        guard phase == .review else { return nil }
        refreshRunningBrowsers()
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

    /// Leaves the finished screen and goes back to the introduction.
    public func done() {
        results = []
        selection = ItemSelection()
        runningBrowserIDs = []
        phase = .intro
    }

    // MARK: Running browsers

    public func isRunning(_ browser: BrowserCaches) -> Bool {
        runningBrowserIDs.contains(browser.id)
    }

    public func isQuitting(_ browser: BrowserCaches) -> Bool {
        quittingBrowserIDs.contains(browser.id)
    }

    /// Asks every open instance of the browser to quit, as quitting it from its menu would,
    /// and selects its caches once it's closed.
    @discardableResult
    public func quit(_ browser: BrowserCaches) async -> Bool {
        quittingBrowserIDs.insert(browser.id)
        defer { quittingBrowserIDs.remove(browser.id) }
        var didQuit = true
        for url in Set(instances(of: browser).map(\.url)) {
            didQuit = await runningApps.quit(appAt: url) && didQuit
        }
        refreshRunningBrowsers()
        if !isRunning(browser) {
            selection.select(browser.items)
        }
        return didQuit && !isRunning(browser)
    }

    /// Checks which browsers are open and unselects their caches.
    public func refreshRunningBrowsers() {
        runningBrowserIDs = Set(results.filter { !instances(of: $0).isEmpty }.map(\.id))
        selection.deselect(results.filter(isRunning).flatMap(\.items))
    }

    // MARK: Selection

    public func canSelect(_ browser: BrowserCaches) -> Bool {
        !isRunning(browser)
    }

    public func isSelected(_ item: CleanableItem, of browser: BrowserCaches) -> Bool {
        canSelect(browser) && selection.contains(item)
    }

    public func selectionState(of browser: BrowserCaches) -> ItemSelection.State {
        canSelect(browser) ? selection.state(of: browser.items) : .none
    }

    public func toggle(_ item: CleanableItem, of browser: BrowserCaches) {
        guard canSelect(browser) else { return }
        selection.toggle(item)
    }

    public func toggle(_ browser: BrowserCaches) {
        guard canSelect(browser) else { return }
        selection.toggleAll(browser.items)
    }

    // MARK: Private

    private func instances(of browser: BrowserCaches) -> [RunningApp] {
        let bundleID = browser.browser.bundleID.lowercased()
        return runningApps.runningApps().filter { $0.bundleID?.lowercased() == bundleID }
    }
}
