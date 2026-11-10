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
    public private(set) var files: [LargeFile] = []
    @Published public private(set) var scannedFileCount = 0
    /// The user stopped the scan, so the list only has the files found until then.
    @Published public private(set) var wasStoppedEarly = false
    @Published public private(set) var selection = ItemSelection()
    @Published public var filter = LargeFileFilter()
    @Published public var sortOrder = LargeFileSortOrder.size

    private let scanner: any LargeFileScanning
    private let cleanupService: CleanupService
    private let now: () -> Date
    private let calendar: Calendar
    private var activeTask: Task<Void, Never>?

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
    public var foundSize: Int64 { files.map(\.item).totalSize }

    /// Files that pass the filter, in the chosen order.
    public var visibleFiles: [LargeFile] {
        sortOrder.sorted(filter.apply(to: files, now: now(), calendar: calendar))
    }

    /// Kinds shown in the filter column: those of the files found, plus the chosen ones.
    public var kindOptions: [FileKind] {
        filter.kindOptions(for: files)
    }

    public var filterCounts: LargeFileFilterCounts {
        LargeFileFilterCounts(files: files, filter: filter, now: now(), calendar: calendar)
    }

    /// Items that `remove()` would move to the Trash.
    public var selectedItems: [CleanableItem] {
        selection.selectedItems(in: files.map(\.item))
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
        selection.state(of: visibleFiles.map(\.item))
    }

    /// Selects every visible file, or clears them when all are already selected.
    public func toggleAll() {
        selection.toggleAll(visibleFiles.map(\.item))
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
