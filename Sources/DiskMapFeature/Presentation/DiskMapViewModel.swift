import CleanMacCore
import Combine
import Foundation

/// Coordinates scanning, browsing, selection and removal for the disk map screen.
///
/// The map is browsed one folder at a time, the focused folder, reached through its
/// breadcrumbs. Items can be selected in any folder, but only those the removal policy
/// allows, and after a removal the map shrinks in place instead of being scanned again.
@MainActor
public final class DiskMapViewModel: ObservableObject {
    @Published public private(set) var phase: DiskMapPhase = .intro
    @Published public private(set) var progress = DiskMapProgress()
    @Published public private(set) var map: DiskNode?
    /// Folders opened from the top of the map down to the focused one.
    @Published public private(set) var focusPath: [URL] = []
    @Published public private(set) var selection = ItemSelection()

    /// Item pointed at with the mouse or the keyboard, shown both in the rings and in the list.
    ///
    /// Pointing at another slice of the same branch sets the same item again. A published
    /// property redraws every view that observes the model on each assignment, even of the
    /// value it already holds, so only a different item is stored.
    public var highlightedID: DiskNode.ID? {
        get { storedHighlightedID }
        set {
            guard newValue != storedHighlightedID else { return }
            storedHighlightedID = newValue
        }
    }

    @Published private var storedHighlightedID: DiskNode.ID?

    private let scanner: any DiskMapScanning
    private let cleanupService: CleanupService
    private let policy: DiskMapRemovalPolicy
    private let layout: SunburstLayout
    private var activeTask: Task<Void, Never>?

    public init(
        scanner: any DiskMapScanning,
        cleanupService: CleanupService = CleanupService(remover: TrashItemRemover()),
        policy: DiskMapRemovalPolicy = DiskMapRemovalPolicy(),
        layout: SunburstLayout = SunburstLayout()
    ) {
        self.scanner = scanner
        self.cleanupService = cleanupService
        self.policy = policy
        self.layout = layout
    }

    // MARK: Browsing

    /// The top of the map followed by every opened folder, down to the focused one.
    public var breadcrumbs: [DiskNode] {
        guard let map else { return [] }
        var crumbs = [map]
        for url in focusPath {
            guard let next = crumbs[crumbs.count - 1].children.first(where: { $0.url == url }) else { break }
            crumbs.append(next)
        }
        return crumbs
    }

    public var focusedFolder: DiskNode? { breadcrumbs.last }

    /// Items of the focused folder, largest first.
    public var items: [DiskNode] { focusedFolder?.children ?? [] }

    public var segments: [RingSegment] {
        focusedFolder.map(layout.segments(around:)) ?? []
    }

    public var canGoUp: Bool { !focusPath.isEmpty }

    /// A folder can be opened when it has something inside to show.
    public func canOpen(_ node: DiskNode) -> Bool {
        node.kind == .folder && node.size > 0
    }

    /// Focuses an item of the focused folder.
    public func open(_ node: DiskNode) {
        guard canOpen(node), items.contains(where: { $0.id == node.id }) else { return }
        focusPath.append(node.url)
        highlightedID = nil
    }

    /// Focuses the folder that holds the focused one.
    public func goUp() {
        guard let left = focusPath.popLast() else { return }
        highlightedID = left
    }

    /// Focuses the breadcrumb at `index`, where 0 is the top of the map.
    public func goToBreadcrumb(at index: Int) {
        guard index >= 0, index < focusPath.count else { return }
        focusPath.removeSubrange(index...)
        highlightedID = nil
    }

    // MARK: Keyboard

    /// Moves the highlight `offset` items down the list, or up when negative, staying within it.
    public func moveHighlight(by offset: Int) {
        guard !items.isEmpty else { return }
        guard let current = items.firstIndex(where: { $0.id == highlightedID }) else {
            highlightedID = (offset < 0 ? items.last : items.first)?.id
            return
        }
        let next = min(max(current + offset, 0), items.count - 1)
        highlightedID = items[next].id
    }

    public func openHighlighted() {
        guard let node = items.first(where: { $0.id == highlightedID }) else { return }
        open(node)
    }

    // MARK: Selection

    public func advice(for node: DiskNode) -> RemovalAdvice {
        policy.advice(for: node)
    }

    public func canSelect(_ node: DiskNode) -> Bool {
        advice(for: node).allowsMovingToTrash
    }

    public func isSelected(_ node: DiskNode) -> Bool {
        selection.contains(Self.item(for: node))
    }

    public func toggle(_ node: DiskNode) {
        guard canSelect(node) else { return }
        selection.toggle(Self.item(for: node))
    }

    /// Items that `remove()` would move to the Trash, in every folder. An item inside a
    /// selected folder goes with it, so it isn't listed on its own.
    public var selectedItems: [CleanableItem] {
        guard let map else { return [] }
        var items: [CleanableItem] = []
        collectSelected(in: map, into: &items)
        return items
    }

    public var selectedSize: Int64 { selectedItems.totalSize }
    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    @discardableResult
    public func startScan() -> Task<Void, Never> {
        activeTask?.cancel()
        map = nil
        focusPath = []
        selection = ItemSelection()
        highlightedID = nil
        progress = DiskMapProgress()
        phase = .scanning
        let task = Task { await scan() }
        activeTask = task
        return task
    }

    /// Stops the scan. A partial map would mislead, so it goes back to the start.
    public func stopScan() {
        guard phase == .scanning else { return }
        activeTask?.cancel()
        phase = .intro
    }

    /// Moves the selected items to the Trash.
    @discardableResult
    public func remove() -> Task<Void, Never>? {
        guard phase == .map else { return nil }
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

    /// Goes back to the map, without the items already moved to the Trash.
    public func done() {
        guard case .finished = phase else { return }
        phase = .map
    }

    // MARK: Private

    private func scan() async {
        for await event in scanner.scan() {
            guard !Task.isCancelled else { return }
            switch event {
            case .progress(let newProgress):
                progress = newProgress
            case .finished(let newMap):
                map = newMap
                phase = .map
            }
        }
    }

    private func finishRemoval(of items: [CleanableItem], report: CleanupReport) {
        let failedIDs = Set(report.failures.map(\.item.id))
        let removedURLs = Set(items.map(\.url)).subtracting(failedIDs)
        map = map?.removing(removedURLs)
        focusPath = breadcrumbs.dropFirst().map(\.url)
        if let highlightedID, removedURLs.contains(highlightedID) {
            self.highlightedID = nil
        }
        selection = ItemSelection()
        phase = .finished(report)
    }

    private func collectSelected(in folder: DiskNode, into items: inout [CleanableItem]) {
        for child in folder.children {
            let item = Self.item(for: child)
            if selection.contains(item) {
                items.append(item)
            } else {
                collectSelected(in: child, into: &items)
            }
        }
    }

    private static func item(for node: DiskNode) -> CleanableItem {
        CleanableItem(url: node.url, size: node.size)
    }
}
