import CleanMacCore
import Combine
import Foundation

/// Coordinates scanning, selection and cleanup for the browser caches screen.
///
/// Caches are safe to clear, so every item is selected after a scan, except those of a
/// browser that is open: they're locked until the user quits it, which never force-quits.
/// What websites stored through their service workers is listed but only selected by hand.
/// A browser also counts as open while another edition of it is, since they share folders.
@MainActor
public final class PrivacyViewModel: ObservableObject {
    @Published public private(set) var phase: PrivacyPhase = .intro
    @Published public private(set) var results: [BrowserCaches] = []
    @Published public private(set) var selection = ItemSelection()
    /// The open apps that lock each browser's caches: the browser and its other editions.
    @Published public private(set) var openAppsByBrowser: [BrowserCaches.ID: [RunningApp]] = [:]
    @Published public private(set) var quittingBrowserIDs: Set<BrowserCaches.ID> = []

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
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        results = []
        selection = ItemSelection()
        openAppsByBrowser = [:]
        phase = .scanning
        let task = Task {
            let found = await scanner.scan()
            guard !Task.isCancelled else { return }
            results = found.sorted { $0.totalSize > $1.totalSize }
            selection.select(found.flatMap(\.cacheItems))
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

    /// Moves the selected caches of browsers that are not open to the Trash.
    @discardableResult
    public func clean() -> Task<Void, Never>? {
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
        openAppsByBrowser = [:]
        phase = .intro
    }

    // MARK: Running browsers

    /// Whether the browser or another edition of it is open.
    public func isRunning(_ browser: BrowserCaches) -> Bool {
        !openApps(of: browser).isEmpty
    }

    /// The apps that keep the browser's caches locked, as of the last check.
    public func openApps(of browser: BrowserCaches) -> [RunningApp] {
        openAppsByBrowser[browser.id] ?? []
    }

    public func isQuitting(_ browser: BrowserCaches) -> Bool {
        quittingBrowserIDs.contains(browser.id)
    }

    /// Asks the browser and every open edition of it to quit, as quitting them from their
    /// menu would, and selects its caches once they're closed.
    @discardableResult
    public func quit(_ browser: BrowserCaches) async -> Bool {
        quittingBrowserIDs.insert(browser.id)
        defer { quittingBrowserIDs.remove(browser.id) }
        var didQuit = true
        for url in Set(openEditions(of: browser).map(\.url)) {
            didQuit = await runningApps.quit(appAt: url) && didQuit
        }
        refreshRunningBrowsers()
        if !isRunning(browser) {
            selection.select(browser.cacheItems)
        }
        return didQuit && !isRunning(browser)
    }

    /// Checks which browsers are open and unselects their caches.
    public func refreshRunningBrowsers() {
        openAppsByBrowser = results.reduce(into: [:]) { openApps, browser in
            let editions = openEditions(of: browser)
            if !editions.isEmpty { openApps[browser.id] = editions }
        }
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

    /// Selects the browser's caches unless all of them are selected, in which case it clears
    /// everything. Site data is never selected from here, only item by item.
    public func toggle(_ browser: BrowserCaches) {
        guard canSelect(browser) else { return }
        if selection.state(of: browser.cacheItems) == .all {
            selection.deselect(browser.items)
        } else {
            selection.select(browser.cacheItems)
        }
    }

    // MARK: Private

    /// The open apps that may be using the browser's caches, by name.
    private func openEditions(of browser: BrowserCaches) -> [RunningApp] {
        runningApps.openApps().filter(browser.browser.isEdition).sorted { $0.name < $1.name }
    }
}
