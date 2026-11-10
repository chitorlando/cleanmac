import CleanMacCore
import Foundation
import Observation

/// Coordinates scanning, browsing, selection and removal for the duplicates screen.
///
/// Nothing is selected after a scan. "Select duplicates" marks every copy but one per
/// group, together with its clones, and no action can ever mark every copy of a group
/// (see `DuplicateSelectionRule`).
@MainActor
@Observable
public final class DuplicatesViewModel {
    public private(set) var phase: DuplicatesPhase = .intro
    public private(set) var groups: [DuplicateGroup] = []
    public private(set) var progress = DuplicateScanProgress()
    /// The user stopped the scan, so the list only has the groups confirmed until then.
    public private(set) var wasStoppedEarly = false
    public private(set) var selection = ItemSelection()
    public var query = DuplicateListQuery()
    public var focusedGroupID: DuplicateGroup.ID?

    private let scanner: any DuplicateScanning
    private let cleanupService: CleanupService
    @ObservationIgnored private var activeTask: Task<Void, Never>?

    public init(scanner: any DuplicateScanning, cleanupService: CleanupService) {
        self.scanner = scanner
        self.cleanupService = cleanupService
    }

    // MARK: Derived state

    public var visibleGroups: [DuplicateGroup] { query.apply(to: groups) }

    public var focusedGroup: DuplicateGroup? {
        groups.first { $0.id == focusedGroupID }
    }

    /// Space freed by keeping one copy of every group found.
    public var recoverableSize: Int64 { groups.map(\.recoverableSize).reduce(0, +) }

    /// Copies that `remove()` would move to the Trash, visible or not, each sized by the
    /// space its removal frees (see `DuplicateGroup.itemsToRemove(_:)`).
    public var selectedItems: [CleanableItem] {
        let removableIDs = Set(DuplicateSelectionRule.removableItems(in: groups, selection: selection).map(\.id))
        return groups.flatMap { $0.itemsToRemove(removableIDs) }
    }

    /// Space that removing the selected copies frees. Clones only count once every copy
    /// that shares their data is selected, so this can be less than their total size.
    public var selectedSize: Int64 { selectedItems.totalSize }

    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        groups = []
        selection = ItemSelection()
        progress = DuplicateScanProgress()
        wasStoppedEarly = false
        focusedGroupID = nil
        phase = .scanning
        let task = Task { await scan() }
        activeTask = task
        return task
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
    /// Scanning again would take minutes and find the same groups.
    public func done() {
        guard case .finished = phase else { return }
        phase = .review
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
        let states = Set(visibleGroups.filter { !$0.isMadeOfClones }.map(selectionState(of:)))
        switch states {
        case [.all]: return .all
        case [], [.none]: return .none
        default: return .some
        }
    }

    /// The checkbox can mark a visible group that frees space, or clear any visible marked copy.
    public var canToggleDuplicates: Bool {
        visibleGroups.contains { !$0.isMadeOfClones || selectionState(of: $0) != .none }
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

    private func scan() async {
        for await event in scanner.scan() {
            guard !Task.isCancelled else { return }
            switch event {
            case .progress(let newProgress):
                progress = newProgress
            case .found(let group):
                groups.append(group)
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
        groups = groups.compactMap { $0.removing(removedIDs) }
        selection = ItemSelection()
        if focusedGroup == nil {
            focusedGroupID = visibleGroups.first?.id
        }
        phase = .finished(report)
    }
}
