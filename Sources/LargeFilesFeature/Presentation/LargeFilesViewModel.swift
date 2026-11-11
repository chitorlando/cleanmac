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

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        updateFiles { $0 = [] }
        selection = ItemSelection()
        scannedFileCount = 0
        wasStoppedEarly = false
        phase = .scanning
        let task = Task { await scan() }
        activeTask = task
        return task
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
    public func done() {
        guard case .finished = phase else { return }
        phase = .review
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

    private func scan() async {
        for await event in scanner.scan() {
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
