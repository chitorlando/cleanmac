import CleanMacCore
import Combine
import Foundation

/// Coordinates loading, browsing, selection and removal for the uninstaller screen.
///
/// Items of running apps can never be selected or removed, and shared leftovers are
/// only removed when the user marks them by hand (see `AppSelectionRule`). An app also
/// counts as running when the system runs it from another place (see `RunningAppMatcher`).
@MainActor
public final class UninstallerViewModel: ObservableObject {
    @Published public private(set) var phase: UninstallerPhase = .intro
    @Published public private(set) var apps: [InstalledApp] = [] {
        didSet {
            storedSelectionMemo = nil
            forgetDerivedState(sortedApps: true, visibleApps: true, selectedItems: true, allSelectionState: true)
        }
    }
    @Published public private(set) var selection = ItemSelection() {
        didSet {
            if let changingItems {
                storedSelectionMemo?.forget(appsListing: changingItems)
            } else {
                storedSelectionMemo?.forgetEverything()
            }
            forgetDerivedState(selectedItems: true, allSelectionState: true)
        }
    }
    @Published public private(set) var discoveredCount: Int?
    @Published public private(set) var analyzedCount = 0
    @Published public private(set) var sharedLeftovers = SharedLeftovers.none {
        didSet {
            storedSelectionMemo?.forgetEverything()
            forgetDerivedState(allSelectionState: true)
        }
    }
    @Published public private(set) var runningAppIDs: Set<InstalledApp.ID> = [] {
        didSet { forgetDerivedState(allSelectionState: true) }
    }
    @Published public private(set) var quittingAppIDs: Set<InstalledApp.ID> = []
    @Published public var query = AppListQuery() {
        didSet {
            forgetDerivedState(
                sortedApps: query.sortOrder != oldValue.sortOrder,
                visibleApps: true,
                allSelectionState: true
            )
        }
    }
    @Published public var focusedAppID: InstalledApp.ID?
    /// Path of the app to focus once the list is loaded, asked for by another feature.
    private var pendingFocusPath: String?
    /// Apps other features asked for, analyzed with the rest in case they're outside the
    /// application folders. Kept for later loads, which skip the ones that are gone.
    private var requestedApps: [URL] = []
    /// Items of running apps, updated whenever the running apps are refreshed.
    @Published private var lockedItemIDs: Set<CleanableItem.ID> = [] {
        didSet {
            storedSelectionMemo?.forgetEverything()
            forgetDerivedState(selectedItems: true)
        }
    }

    private let scanner: any InstalledAppScanning
    private let runningApps: any RunningAppsProviding
    private let cleanupService: CleanupService
    private var activeTask: Task<Void, Never>?

    // Derived state kept between reads. Every change re-renders all the views that observe
    // the view model, and several of them read these values in each pass, which took several
    // frames with a few hundred apps. Each value is worked out on its first read and forgotten
    // by the `didSet` of every property it comes from.
    //
    // The apps are kept in order apart from the visible ones: ordering them compares names as
    // the Finder does, most of a frame with a few hundred apps, and the search doesn't change it.
    private var cachedSortedApps: [InstalledApp]?
    private var cachedVisibleApps: [InstalledApp]?
    private var cachedSelectedItems: [CleanableItem]?
    private var cachedAllSelectionState: ItemSelection.State?

    // Working out the two values above asks the selection about every item, which hashes a
    // URL each time: most of a frame with a few thousand items. A toggle changes a handful, so
    // the answers are also kept app by app and only the apps that list those items are asked
    // again (see `AppSelectionMemo`). The memo is built on its first read after the apps change.
    private var storedSelectionMemo: AppSelectionMemo?
    /// The only items the change to `selection` under way can affect, or `nil` for any of them.
    private var changingItems: [CleanableItem]?

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

    public var visibleApps: [InstalledApp] {
        if let cachedVisibleApps { return cachedVisibleApps }
        let visible = query.filtered(sortedApps)
        cachedVisibleApps = visible
        return visible
    }

    public var focusedApp: InstalledApp? {
        apps.first { $0.id == focusedAppID }
    }

    /// Items that `uninstall()` would remove, without duplicates.
    public var selectedItems: [CleanableItem] {
        if let cachedSelectedItems { return cachedSelectedItems }
        let items = selectionMemo.selectedItems { selection.contains($0) && canSelect($0) }
        cachedSelectedItems = items
        return items
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
        let includedApps = requestedApps
        let task = Task { await load(including: includedApps) }
        activeTask = task
        return task
    }

    public func cancelLoading() {
        activeTask?.cancel()
        pendingFocusPath = nil
        phase = .intro
    }

    /// Focuses the app at `url`, such as one another feature sends here.
    ///
    /// When the list isn't loaded yet, it loads it first, starting from the intro if needed,
    /// and focuses the app when loading ends. The search is cleared if it hides the app.
    ///
    /// The app can be outside the application folders, such as in Downloads: the list is then
    /// loaded again with it, which clears the selection, also when it's asked for during a load.
    ///
    /// A loaded list is only loaded again when the scanner can analyze the app. Otherwise it
    /// stays as it is, selection and focus included: there is no app at that path, or it is
    /// one the uninstaller never lists.
    public func focusApp(at url: URL) {
        let app = url.standardizedFileURL
        switch phase {
        case .browsing:
            if isListed(app) {
                pendingFocusPath = app.path
                applyPendingFocus()
            } else if scanner.canAnalyze(appAt: app) {
                request(app)
                startLoading()
            }
        case .intro:
            request(app)
            startLoading()
        case .loading, .uninstalling, .finished:
            request(app)
        }
    }

    /// Asks a running app to quit, wherever it runs from, then refreshes which apps are open.
    @discardableResult
    public func quit(_ app: InstalledApp) async -> Bool {
        quittingAppIDs.insert(app.id)
        defer { quittingAppIDs.remove(app.id) }
        let instancesElsewhere = runningAppMatcher().instancesElsewhere(of: app)
        var didQuit = await runningApps.quit(appAt: app.info.url)
        for instance in instancesElsewhere {
            didQuit = await runningApps.quit(appAt: instance) && didQuit
        }
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
        if let cachedAllSelectionState { return cachedAllSelectionState }
        let rule = self.rule
        let states = selectionMemo.states(of: selectableVisibleApps) { rule.state(of: $0, in: selection) }
        let state = AppSelectionRule.state(combining: states)
        cachedAllSelectionState = state
        return state
    }

    public func toggle(_ item: CleanableItem) {
        guard canSelect(item) else { return }
        changeSelection(of: [item]) { $0.toggle(item) }
    }

    public func toggle(_ app: InstalledApp) {
        guard !isRunning(app) else { return }
        changeSelection(of: app.allItems) { rule.toggle(app, in: &$0) }
    }

    public func toggleAll() {
        let apps = selectableVisibleApps
        changeSelection(of: apps.flatMap(\.allItems)) { rule.toggle(apps, in: &$0) }
    }

    // MARK: Private

    private var rule: AppSelectionRule { AppSelectionRule(shared: sharedLeftovers) }

    private var selectableVisibleApps: [InstalledApp] {
        visibleApps.filter { !isRunning($0) }
    }

    private var selectionMemo: AppSelectionMemo {
        get { storedSelectionMemo ?? AppSelectionMemo(apps: apps) }
        set { storedSelectionMemo = newValue }
    }

    /// Changes the selection in a way that can only affect `items`, so that what is
    /// remembered about the apps that list none of them is kept.
    private func changeSelection(of items: [CleanableItem], _ change: (inout ItemSelection) -> Void) {
        changingItems = items
        defer { changingItems = nil }
        change(&selection)
    }

    /// Every app in the order of the query, whatever the search.
    private var sortedApps: [InstalledApp] {
        if let cachedSortedApps { return cachedSortedApps }
        let sorted = query.sorted(apps)
        cachedSortedApps = sorted
        return sorted
    }

    private func forgetDerivedState(
        sortedApps: Bool = false,
        visibleApps: Bool = false,
        selectedItems: Bool = false,
        allSelectionState: Bool = false
    ) {
        if sortedApps { cachedSortedApps = nil }
        if visibleApps { cachedVisibleApps = nil }
        if selectedItems { cachedSelectedItems = nil }
        if allSelectionState { cachedAllSelectionState = nil }
    }

    /// Shared leftovers are worked out once, when every app is in: they are only read while
    /// browsing, and rebuilding them after each app grew with the square of the app count.
    ///
    /// - Parameter includedApps: The requested apps this load analyzes with the rest.
    private func load(including includedApps: [URL]) async {
        for await event in scanner.scan(including: includedApps) {
            guard !Task.isCancelled else { return }
            switch event {
            case .discovered(let count):
                discoveredCount = count
            case .analyzed(let app):
                analyzedCount += 1
                apps.append(app)
            }
        }
        guard !Task.isCancelled else { return }
        guard !leftOutAnAppRequested(after: includedApps) else {
            startLoading()
            return
        }
        sharedLeftovers = SharedLeftovers(apps: apps)
        refreshRunningApps()
        applyPendingFocus()
        if focusedApp == nil {
            focusedAppID = visibleApps.first?.id
        }
        phase = .browsing
    }

    /// Remembers that another feature asked for `app`, so that loads analyze it with the
    /// rest and the next one to end focuses it.
    private func request(_ app: URL) {
        pendingFocusPath = app.path
        if !requestedApps.contains(app) {
            requestedApps.append(app)
        }
    }

    /// Whether an app the scanner can analyze was asked for after a load began, so that load
    /// left it out. It looks at every app asked for meanwhile, not only the last one.
    private func leftOutAnAppRequested(after includedApps: [URL]) -> Bool {
        requestedApps.contains { app in
            !includedApps.contains(app) && !isListed(app) && scanner.canAnalyze(appAt: app)
        }
    }

    private func isListed(_ app: URL) -> Bool {
        listedApp(atPath: app.path) != nil
    }

    private func listedApp(atPath path: String) -> InstalledApp? {
        apps.first { $0.id.standardizedFileURL.path == path }
    }

    private func applyPendingFocus() {
        guard let path = pendingFocusPath else { return }
        pendingFocusPath = nil
        guard let app = listedApp(atPath: path) else { return }
        if !visibleApps.contains(where: { $0.id == app.id }) {
            query.searchText = ""
        }
        focusedAppID = app.id
    }

    private func runningAppMatcher() -> RunningAppMatcher {
        RunningAppMatcher(runningApps: runningApps.runningApps(), listedApps: apps)
    }

    private func refreshRunningApps() {
        let matcher = runningAppMatcher()
        runningAppIDs = Set(apps.filter(matcher.isRunning).map(\.id))
        let lockedItems = apps.filter(isRunning).flatMap(\.allItems)
        lockedItemIDs = Set(lockedItems.map(\.id))
        changeSelection(of: lockedItems) { $0.deselect(lockedItems) }
    }
}
