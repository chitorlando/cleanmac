import CleanMacCore
import Combine
import Foundation

/// Coordinates scanning, browsing, selection and removal for the duplicates screen.
///
/// Nothing is selected after a scan. "Select duplicates" marks every copy but one per
/// group, together with its clones, and no action can ever mark every copy of a group
/// (see `DuplicateSelectionRule`).
@MainActor
public final class DuplicatesViewModel: ObservableObject {
    @Published public private(set) var phase: DuplicatesPhase = .intro
    /// What the scan on screen covers: the whole home folder, or a folder another feature sent.
    @Published public private(set) var scope = DuplicateScanScope.home
    /// Not `@Published`: its setter copies the whole array on every change, which made a scan
    /// that finds thousands of groups slow down as it went. Every change goes through
    /// `updateGroups(_:)`, which announces it and then edits the array in place.
    ///
    /// The `didSet` must not read `oldValue`: Swift would copy the array before every change
    /// to have it.
    public private(set) var groups: [DuplicateGroup] = [] {
        didSet { groupsDidChange() }
    }
    @Published public private(set) var progress = DuplicateScanProgress()
    /// The user stopped the scan, so the list only has the groups confirmed until then.
    @Published public private(set) var wasStoppedEarly = false
    @Published public private(set) var selection = ItemSelection() {
        didSet { selectionDidChange() }
    }
    /// The search field writes its text back after showing it, so the same query often comes
    /// twice. Only a different one recomputes the list.
    @Published public var query = DuplicateListQuery() {
        didSet { if query != oldValue { queryDidChange() } }
    }
    @Published public var focusedGroupID: DuplicateGroup.ID? {
        didSet { if focusedGroupID != oldValue { focusedGroupMemo.invalidate() } }
    }

    private let scanner: any DuplicateScanning
    private let cleanupService: CleanupService
    private var activeTask: Task<Void, Never>?
    /// Folder asked for while a removal or its report was on screen, to scan once they are left.
    private var pendingFolder: URL?

    // Derived state, computed once per change of what it depends on (see `Memoized`).
    private var visibleGroupsMemo = Memoized<[DuplicateGroup]>()
    private var focusedGroupMemo = Memoized<DuplicateGroup?>()
    private var recoverableSizeMemo = Memoized<Int64>()
    private var selectedItemsMemo = Memoized<[CleanableItem]>()
    private var duplicatesSelectionStateMemo = Memoized<ItemSelection.State>()
    private var canToggleDuplicatesMemo = Memoized<Bool>()

    public init(scanner: any DuplicateScanning, cleanupService: CleanupService) {
        self.scanner = scanner
        self.cleanupService = cleanupService
    }

    // MARK: Derived state

    public var visibleGroups: [DuplicateGroup] {
        visibleGroupsMemo.value { query.apply(to: groups) }
    }

    public var focusedGroup: DuplicateGroup? {
        focusedGroupMemo.value { groups.first { $0.id == focusedGroupID } }
    }

    /// Space freed by keeping one copy of every group found.
    public var recoverableSize: Int64 {
        recoverableSizeMemo.value { groups.map(\.recoverableSize).reduce(0, +) }
    }

    /// Copies that `remove()` would move to the Trash, visible or not, each sized by the
    /// space its removal frees (see `DuplicateGroup.itemsToRemove(_:)`).
    public var selectedItems: [CleanableItem] {
        selectedItemsMemo.value {
            let removableIDs = Set(DuplicateSelectionRule.removableItems(in: groups, selection: selection).map(\.id))
            return groups.flatMap { $0.itemsToRemove(removableIDs) }
        }
    }

    /// Space that removing the selected copies frees. Clones only count once every copy
    /// that shares their data is selected, so this can be less than their total size.
    public var selectedSize: Int64 { selectedItems.totalSize }

    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    /// Scans the current scope from scratch: the whole home folder, or the folder the screen
    /// is limited to. Only `scanHome()` leaves that folder.
    @discardableResult
    public func startScan() -> Task<Void, Never> {
        startScan(scope)
    }

    /// Leaves the folder the screen is limited to and scans the whole home folder.
    @discardableResult
    public func scanHome() -> Task<Void, Never> {
        startScan(.home)
    }

    /// Looks for duplicates only in the folder at `url`, for a feature that shows folders.
    ///
    /// The scan starts at once, also in place of a scan in progress or of the results on
    /// screen. A removal is never disturbed: asked for during one or on its report, the folder
    /// is scanned when the user leaves the report, and the last folder asked for wins.
    ///
    /// The request is ignored, and nothing changes, when the scanner can't scan the folder on
    /// its own: there is no folder at `url`, or the scan of the home folder leaves it out.
    /// The home folder itself gets a scan of the whole home folder.
    ///
    /// - Returns: The scan, or `nil` when the request was ignored or waits for the report.
    @discardableResult
    public func scanFolder(at url: URL) -> Task<Void, Never>? {
        guard let folderScope = scanner.scope(limitedTo: url) else { return nil }
        switch phase {
        case .intro, .scanning, .review:
            return startScan(folderScope)
        case .removing, .finished:
            pendingFolder = url
            return nil
        }
    }

    /// Stops the scan and reviews the groups confirmed so far, which are complete and safe to use.
    public func stopScan() {
        guard phase == .scanning else { return }
        activeTask?.cancel()
        wasStoppedEarly = true
        finishScan()
    }

    /// Moves the selected copies to the Trash.
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

    /// Leaves the finished screen and goes back to the list, without the copies already removed.
    ///
    /// Scanning again would take minutes and find the same groups. Only a folder asked for
    /// since the removal started is scanned instead, if it still can be (see `scanFolder(at:)`).
    ///
    /// - Returns: The scan of that folder, or `nil` when the list is shown.
    @discardableResult
    public func done() -> Task<Void, Never>? {
        guard case .finished = phase else { return nil }
        if let folder = pendingFolder, let folderScope = scanner.scope(limitedTo: folder) {
            return startScan(folderScope)
        }
        pendingFolder = nil
        phase = .review
        return nil
    }

    // MARK: Selection

    public func isSelected(_ file: DuplicateFile) -> Bool {
        selection.contains(file.item)
    }

    public func canSelect(_ file: DuplicateFile, in group: DuplicateGroup) -> Bool {
        DuplicateSelectionRule.canSelect(file, in: group, selection: selection)
    }

    /// The copy kept by "Select duplicates".
    public func isSuggestedKeeper(_ file: DuplicateFile, in group: DuplicateGroup) -> Bool {
        DuplicateKeeper.keeper(in: group)?.id == file.id
    }

    public func selectionState(of group: DuplicateGroup) -> ItemSelection.State {
        DuplicateSelectionRule.state(of: group, selection: selection)
    }

    public func toggle(_ file: DuplicateFile, in group: DuplicateGroup) {
        DuplicateSelectionRule.toggle(file, in: group, selection: &selection)
    }

    public func toggle(_ group: DuplicateGroup) {
        DuplicateSelectionRule.toggle(group, selection: &selection)
    }

    /// State of the "Select duplicates" checkbox, over the visible groups with duplicates to mark.
    public var duplicatesSelectionState: ItemSelection.State {
        duplicatesSelectionStateMemo.value {
            let states = Set(visibleGroups.filter { !$0.isMadeOfClones }.map(selectionState(of:)))
            switch states {
            case [.all]: return .all
            case [], [.none]: return .none
            default: return .some
            }
        }
    }

    /// The checkbox can mark a visible group that frees space, or clear any visible marked copy.
    public var canToggleDuplicates: Bool {
        canToggleDuplicatesMemo.value {
            visibleGroups.contains { !$0.isMadeOfClones || selectionState(of: $0) != .none }
        }
    }

    /// Marks the duplicates of every visible group, keeping one copy and its clones in each.
    public func selectDuplicates() {
        DuplicateSelectionRule.selectDuplicates(in: visibleGroups, selection: &selection)
    }

    /// Clears the visible groups when all their duplicates are marked; otherwise marks them.
    public func toggleDuplicates() {
        if duplicatesSelectionState == .all {
            selection.deselect(visibleGroups.flatMap(\.items))
        } else {
            selectDuplicates()
        }
    }

    // MARK: Private

    private func startScan(_ newScope: DuplicateScanScope) -> Task<Void, Never> {
        activeTask?.cancel()
        pendingFolder = nil
        if newScope != scope {
            // A search left from another place would hide what is found in this one.
            query.searchText = ""
            scope = newScope
        }
        updateGroups { $0 = [] }
        selection = ItemSelection()
        progress = DuplicateScanProgress()
        wasStoppedEarly = false
        focusedGroupID = nil
        phase = .scanning
        let task = Task { await scan(newScope) }
        activeTask = task
        return task
    }

    /// The only way `groups` changes: tells the views, as `@Published` would, then edits in place.
    private func updateGroups(_ change: (inout [DuplicateGroup]) -> Void) {
        objectWillChange.send()
        change(&groups)
    }

    private func groupsDidChange() {
        visibleGroupsMemo.invalidate()
        focusedGroupMemo.invalidate()
        recoverableSizeMemo.invalidate()
        selectionDidChange()
    }

    private func queryDidChange() {
        visibleGroupsMemo.invalidate()
        duplicatesSelectionStateMemo.invalidate()
        canToggleDuplicatesMemo.invalidate()
    }

    private func selectionDidChange() {
        selectedItemsMemo.invalidate()
        duplicatesSelectionStateMemo.invalidate()
        canToggleDuplicatesMemo.invalidate()
    }

    private func scan(_ scope: DuplicateScanScope) async {
        for await event in scanner.scan(scope) {
            guard !Task.isCancelled else { return }
            switch event {
            case .progress(let newProgress):
                progress = newProgress
            case .found(let group):
                updateGroups { $0.append(group) }
            }
        }
        guard !Task.isCancelled else { return }
        finishScan()
    }

    private func finishScan() {
        if focusedGroup == nil {
            focusedGroupID = visibleGroups.first?.id
        }
        phase = .review
    }

    private func finishRemoval(of items: [CleanableItem], report: CleanupReport) {
        let failedIDs = Set(report.failures.map(\.item.id))
        let removedIDs = Set(items.map(\.id)).subtracting(failedIDs)
        updateGroups { $0 = $0.compactMap { $0.removing(removedIDs) } }
        selection = ItemSelection()
        if focusedGroup == nil {
            focusedGroupID = visibleGroups.first?.id
        }
        phase = .finished(report)
    }
}
