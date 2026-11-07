import CleanMacCore
import Foundation
import Observation

/// Coordinates loading, browsing, selection and removal for the uninstaller screen.
///
/// Items of running apps can never be selected or removed, and shared leftovers are
/// only removed when the user marks them by hand (see `AppSelectionRule`).
@MainActor
@Observable
public final class UninstallerViewModel {
    public private(set) var phase: UninstallerPhase = .intro
    public private(set) var apps: [InstalledApp] = []
    public private(set) var selection = ItemSelection()
    public private(set) var discoveredCount: Int?
    public private(set) var analyzedCount = 0
    public private(set) var sharedLeftovers = SharedLeftovers.none
    public private(set) var runningAppIDs: Set<InstalledApp.ID> = []
    public private(set) var quittingAppIDs: Set<InstalledApp.ID> = []
    public var query = AppListQuery()
    public var focusedAppID: InstalledApp.ID?
    /// Items of running apps, updated whenever the running apps are refreshed.
    private var lockedItemIDs: Set<CleanableItem.ID> = []

    private let scanner: any InstalledAppScanning
    private let runningApps: any RunningAppsProviding
    private let cleanupService: CleanupService
    @ObservationIgnored private var activeTask: Task<Void, Never>?

    public init(
        scanner: any InstalledAppScanning,
        runningApps: any RunningAppsProviding,
        cleanupService: CleanupService
    ) {
        self.scanner = scanner
        self.runningApps = runningApps
        self.cleanupService = cleanupService
    }

    // MARK: Derived state

    /// Fraction of discovered apps already analyzed, or zero before discovery ends.
    public var loadProgress: Double {
        guard let discoveredCount, discoveredCount > 0 else { return 0 }
        return Double(analyzedCount) / Double(discoveredCount)
    }

    public var visibleApps: [InstalledApp] { query.apply(to: apps) }

    public var focusedApp: InstalledApp? {
        apps.first { $0.id == focusedAppID }
    }

    /// Items that `uninstall()` would remove, without duplicates.
    public var selectedItems: [CleanableItem] {
        var seen: Set<CleanableItem.ID> = []
        return apps
            .flatMap(\.allItems)
            .filter { selection.contains($0) && canSelect($0) && seen.insert($0.id).inserted }
    }

    public var selectedSize: Int64 { selectedItems.totalSize }
    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    /// Apps whose bundle is selected, so they will be uninstalled.
    public var selectedAppCount: Int {
        apps.count { selection.contains($0.bundle) && !isRunning($0) }
    }

    // MARK: Actions

    @discardableResult
    public func startLoading() -> Task<Void, Never> {
        activeTask?.cancel()
        apps = []
        selection = ItemSelection()
        sharedLeftovers = .none
        runningAppIDs = []
        lockedItemIDs = []
        discoveredCount = nil
        analyzedCount = 0
        phase = .loading
        let task = Task { await load() }
        activeTask = task
        return task
    }

    public func cancelLoading() {
        activeTask?.cancel()
        phase = .intro
    }

    /// Asks a running app to quit, then refreshes which apps are open.
    @discardableResult
    public func quit(_ app: InstalledApp) async -> Bool {
        quittingAppIDs.insert(app.id)
        defer { quittingAppIDs.remove(app.id) }
        let didQuit = await runningApps.quit(appAt: app.info.url)
        refreshRunningApps()
        return didQuit
    }

    /// Moves the selected items of apps that are not running to the Trash.
    @discardableResult
    public func uninstall() -> Task<Void, Never>? {
        guard phase == .browsing else { return nil }
        refreshRunningApps()
        let items = selectedItems
        guard !items.isEmpty else { return nil }
        phase = .uninstalling
        let task = Task {
            let report = await cleanupService.clean(items)
            guard !Task.isCancelled else { return }
            phase = .finished(report)
        }
        activeTask = task
        return task
    }

    /// Leaves the finished screen and loads the app list again.
    @discardableResult
    public func done() -> Task<Void, Never> {
        startLoading()
    }

    // MARK: Running apps

    public func isRunning(_ app: InstalledApp) -> Bool {
        runningAppIDs.contains(app.id)
    }

    public func isQuitting(_ app: InstalledApp) -> Bool {
        quittingAppIDs.contains(app.id)
    }

    // MARK: Selection

    public func isShared(_ item: CleanableItem) -> Bool {
        sharedLeftovers.contains(item)
    }

    /// Items of running apps cannot be selected.
    public func canSelect(_ item: CleanableItem) -> Bool {
        !lockedItemIDs.contains(item.id)
    }

    public func isSelected(_ item: CleanableItem) -> Bool {
        selection.contains(item) && canSelect(item)
    }

    public func selectionState(of app: InstalledApp) -> ItemSelection.State {
        guard !isRunning(app) else { return .none }
        return rule.state(of: app, in: selection)
    }

    /// State of the "select all" checkbox, over the visible apps that are not running.
    public var allSelectionState: ItemSelection.State {
        rule.state(of: selectableVisibleApps, in: selection)
    }

    public func toggle(_ item: CleanableItem) {
        guard canSelect(item) else { return }
        selection.toggle(item)
    }

    public func toggle(_ app: InstalledApp) {
        guard !isRunning(app) else { return }
        rule.toggle(app, in: &selection)
    }

    public func toggleAll() {
        rule.toggle(selectableVisibleApps, in: &selection)
    }

    // MARK: Private

    private var rule: AppSelectionRule { AppSelectionRule(shared: sharedLeftovers) }

    private var selectableVisibleApps: [InstalledApp] {
        visibleApps.filter { !isRunning($0) }
    }

    private func load() async {
        for await event in scanner.scan() {
            guard !Task.isCancelled else { return }
            switch event {
            case .discovered(let count):
                discoveredCount = count
            case .analyzed(let app):
                analyzedCount += 1
                apps.append(app)
                sharedLeftovers = SharedLeftovers(apps: apps)
            }
        }
        guard !Task.isCancelled else { return }
        refreshRunningApps()
        if focusedApp == nil {
            focusedAppID = visibleApps.first?.id
        }
        phase = .browsing
    }

    private func refreshRunningApps() {
        let runningURLs = runningApps.runningAppURLs()
        runningAppIDs = Set(apps.map(\.id).filter { runningURLs.contains($0.standardizedFileURL) })
        let lockedItems = apps.filter(isRunning).flatMap(\.allItems)
        lockedItemIDs = Set(lockedItems.map(\.id))
        selection.deselect(lockedItems)
    }
}
