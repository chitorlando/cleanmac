import CleanMacCore
import Combine
import Foundation

/// Coordinates scanning, filtering, selection and removal for the large files screen.
///
/// Nothing is selected after a scan: these are the user's own files, so each one
/// is marked by hand. The selection survives filter changes, and `remove()` moves
/// every selected file to the Trash, visible or not.
@MainActor
public final class LargeFilesViewModel: ObservableObject {
    @Published public private(set) var phase: LargeFilesPhase = .intro
    /// Where the scan looks: the whole home folder, until another feature sends a folder to
    /// look in (see `scanFolder(at:)`). The files on screen are the ones found there.
    @Published public private(set) var scope = LargeFileScanScope.home
    /// Not `@Published`: its setter copies the whole array on every change, which made a scan
    /// that finds thousands of files slow down as it went. Every change goes through
    /// `updateFiles(_:)`, which announces it and then edits the array in place.
    ///
    /// The `didSet` must not read `oldValue`: Swift would copy the array before every change
    /// to have it.
    public private(set) var files: [LargeFile] = [] {
        didSet { filesDidChange() }
    }
    @Published public private(set) var scannedFileCount = 0
    /// The user stopped the scan, so the list only has the files found until then.
    @Published public private(set) var wasStoppedEarly = false
    @Published public private(set) var selection = ItemSelection() {
        didSet { selectionDidChange() }
    }
    /// The search field writes its text back after showing it, so the same filter often comes
    /// twice. Only a different one works the list out again.
    @Published public var filter = LargeFileFilter() {
        didSet { if filter != oldValue { forgetFilteredFiles() } }
    }
    @Published public var sortOrder = LargeFileSortOrder.size {
        didSet { if sortOrder != oldValue { forgetSortedFiles() } }
    }

    private let scanner: any LargeFileScanning
    private let cleanupService: CleanupService
    private let now: () -> Date
    private let calendar: Calendar
    private var activeTask: Task<Void, Never>?
    /// Scope asked for while files were being removed or their report was on screen, which
    /// `done()` scans.
    private var pendingScope: LargeFileScanScope?

    // Derived state kept between reads. Every change re-renders all the views that observe
    // the view model, and several of them read these values in each pass, which took several
    // frames with a few thousand files. Each value is worked out on its first read and
    // forgotten when something it comes from changes: the files, the selection, the filter,
    // the order or, for the values that group files by age, the clock (see `ageBoundaries`).
    private var cachedFoundSize: Int64?
    private var cachedSortedFiles: [LargeFile]?
    private var cachedFilteredFiles: FilteredLargeFiles?
    private var cachedSelectedItems: [CleanableItem]?
    private var cachedAllSelectionState: ItemSelection.State?
    private var cachedAges: AgeBucketSnapshot?

    /// - Parameters:
    ///   - now: Current date, used to group files by age.
    public init(
        scanner: any LargeFileScanning,
        cleanupService: CleanupService = CleanupService(remover: TrashItemRemover()),
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.scanner = scanner
        self.cleanupService = cleanupService
        self.now = now
        self.calendar = calendar
    }

    // MARK: Derived state

    /// Smallest size a file must have to be found, as the scanner looks for it.
    public var minimumSize: Int64 { scanner.criteria.minimumSize }

    public var foundCount: Int { files.count }

    public var foundSize: Int64 {
        if let cachedFoundSize { return cachedFoundSize }
        let size = files.map(\.item).totalSize
        cachedFoundSize = size
        return size
    }

    /// Files that pass the filter, in the chosen order.
    public var visibleFiles: [LargeFile] { filteredFiles.files }

    /// Kinds shown in the filter column: those of the files found, plus the chosen ones.
    public var kindOptions: [FileKind] {
        filter.kindOptions(for: files)
    }

    /// Size ranges shown in the filter column, from the smallest size the scanner looks for.
    public var sizeBuckets: [SizeBucket] {
        SizeBucket.buckets(forMinimumSize: minimumSize)
    }

    public var filterCounts: LargeFileFilterCounts { filteredFiles.counts }

    /// Items that `remove()` would move to the Trash.
    public var selectedItems: [CleanableItem] {
        if let cachedSelectedItems { return cachedSelectedItems }
        let items = selection.selectedItems(in: files.map(\.item))
        cachedSelectedItems = items
        return items
    }

    public var selectedSize: Int64 { selectedItems.totalSize }
    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    /// Scans where the last scan looked: the home folder, or the folder the scan is limited to.
    @discardableResult
    public func startScan() -> Task<Void, Never> {
        startScan(in: scope)
    }

    /// Scans the whole home folder, leaving the folder the scan was limited to.
    @discardableResult
    public func scanHome() -> Task<Void, Never> {
        startScan(in: .home)
    }

    /// Looks for large files only in the folder at `url`, as when another feature sends it.
    ///
    /// The scan starts right away, in place of the scan in progress or of the results on
    /// screen. While files are being moved to the Trash, and while their report is on screen,
    /// neither is disturbed: the folder waits and `done()` scans it.
    ///
    /// Ignored when the scanner can't look in `url`: it's not a folder, or it's one the scan
    /// of the home folder never enters.
    ///
    /// - Returns: The scan, or `nil` when the folder is ignored or left for later.
    @discardableResult
    public func scanFolder(at url: URL) -> Task<Void, Never>? {
        guard let scope = scanner.scope(limitedTo: url) else { return nil }
        switch phase {
        case .intro, .scanning, .review:
            return startScan(in: scope)
        case .removing, .finished:
            pendingScope = scope
            return nil
        }
    }

    /// Stops the scan and reviews the files found so far.
    ///
    /// Walking the home folder can take minutes, so the partial results are kept.
    public func stopScan() {
        guard phase == .scanning else { return }
        activeTask?.cancel()
        wasStoppedEarly = true
        phase = .review
    }

    /// Moves the selected files to the Trash.
    @discardableResult
    public func remove() -> Task<Void, Never>? {
        guard phase == .review else { return nil }
        let items = selectedItems
        guard !items.isEmpty else { return nil }
        phase = .removing
        let task = Task {
            let report = await cleanupService.clean(items)
            guard !Task.isCancelled else { return }
            finishRemoval(of: items, report: report)
        }
        activeTask = task
        return task
    }

    /// Leaves the finished screen and goes back to the list, without the files already moved to the Trash.
    ///
    /// Scanning again would take minutes and find the same files, because the Trash is
    /// skipped like any hidden folder. Going back also keeps the user's filters.
    ///
    /// When a folder was sent meanwhile (see `scanFolder(at:)`), it's scanned instead.
    ///
    /// - Returns: The scan of that folder, or `nil` when it goes back to the list.
    @discardableResult
    public func done() -> Task<Void, Never>? {
        guard case .finished = phase else { return nil }
        guard let pendingScope else {
            phase = .review
            return nil
        }
        return startScan(in: pendingScope)
    }

    // MARK: Selection

    public func isSelected(_ file: LargeFile) -> Bool {
        selection.contains(file.item)
    }

    public func toggle(_ file: LargeFile) {
        selection.toggle(file.item)
    }

    /// State of the "select all" checkbox, over the visible files.
    public var allSelectionState: ItemSelection.State {
        // Read first: the state is forgotten if the age ranges it was worked out with are outdated.
        let visible = visibleFiles
        if let cachedAllSelectionState { return cachedAllSelectionState }
        let state = selection.state(of: visible.map(\.item))
        cachedAllSelectionState = state
        return state
    }

    /// Selects every visible file, or clears them when all are already selected.
    public func toggleAll() {
        selection.toggleAll(visibleFiles.map(\.item))
    }

    // MARK: Derived state kept between reads

    /// Every file in the chosen order. Sorting is the slowest step and filtering keeps the
    /// order, so a change of the filter, such as a keystroke in the search field, reuses it.
    private var sortedFiles: [LargeFile] {
        if let cachedSortedFiles { return cachedSortedFiles }
        let sorted = sortOrder.sorted(files)
        cachedSortedFiles = sorted
        return sorted
    }

    /// The visible files and the counts of the filter options. They share the files, the
    /// filter and the age ranges, so they always agree.
    private var filteredFiles: FilteredLargeFiles {
        let ages = ageBoundaries
        if let cachedFilteredFiles { return cachedFilteredFiles }
        let filtered = FilteredLargeFiles(files: sortedFiles, filter: filter, ages: ages)
        cachedFilteredFiles = filtered
        return filtered
    }

    /// The age ranges that every value that groups files by age is worked out with.
    ///
    /// They follow the clock, which announces nothing, so every read checks them: once they
    /// are a minute old they're worked out again and what came from the old ones is forgotten
    /// (see `AgeBucketSnapshot` for why a minute goes unnoticed).
    private var ageBoundaries: AgeBucketBoundaries {
        let date = now()
        if let cachedAges, cachedAges.isCurrent(at: date) { return cachedAges.boundaries }
        let ages = AgeBucketSnapshot(now: date, calendar: calendar)
        cachedAges = ages
        forgetFilteredFiles()
        return ages.boundaries
    }

    private func filesDidChange() {
        cachedFoundSize = nil
        cachedSelectedItems = nil
        forgetSortedFiles()
    }

    private func selectionDidChange() {
        cachedSelectedItems = nil
        cachedAllSelectionState = nil
    }

    private func forgetSortedFiles() {
        cachedSortedFiles = nil
        forgetFilteredFiles()
    }

    /// The state of "select all" is over the visible files, so it's forgotten with them.
    private func forgetFilteredFiles() {
        cachedFilteredFiles = nil
        cachedAllSelectionState = nil
    }

    // MARK: Private

    /// Starts a scan of `newScope` in place of whatever the screen shows.
    ///
    /// The scope and the filter only change, and are only announced, when the scan looks
    /// somewhere else: the filter was chosen over the files of another place, and it could
    /// hide every file found in this one. Scanning the same place again keeps it.
    private func startScan(in newScope: LargeFileScanScope) -> Task<Void, Never> {
        activeTask?.cancel()
        pendingScope = nil
        if newScope != scope {
            scope = newScope
            filter = LargeFileFilter()
        }
        updateFiles { $0 = [] }
        selection = ItemSelection()
        scannedFileCount = 0
        wasStoppedEarly = false
        phase = .scanning
        let task = Task { await scan(newScope) }
        activeTask = task
        return task
    }

    private func scan(_ scope: LargeFileScanScope) async {
        for await event in scanner.scan(scope) {
            guard !Task.isCancelled else { return }
            switch event {
            case .progress(let scannedFiles):
                scannedFileCount = scannedFiles
            case .found(let file):
                updateFiles { $0.append(file) }
            }
        }
        guard !Task.isCancelled else { return }
        phase = .review
    }

    /// The only way `files` changes: tells the views, as `@Published` would, then edits in place.
    private func updateFiles(_ change: (inout [LargeFile]) -> Void) {
        objectWillChange.send()
        change(&files)
    }

    private func finishRemoval(of items: [CleanableItem], report: CleanupReport) {
        let failedIDs = Set(report.failures.map(\.item.id))
        let removedIDs = Set(items.map(\.id)).subtracting(failedIDs)
        updateFiles { $0.removeAll { removedIDs.contains($0.id) } }
        selection = ItemSelection()
        phase = .finished(report)
    }
}
