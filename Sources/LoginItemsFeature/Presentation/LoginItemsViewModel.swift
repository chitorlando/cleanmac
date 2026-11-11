import CleanMacCore
import Combine

/// Coordinates listing, selection and removal for the login items screen.
///
/// Nothing is selected after listing, and only the user's own agents can be selected:
/// shared items in `/Library` need an administrator to remove. Removing an agent moves
/// its property list to the Trash without unloading it, so it stops at the next login.
@MainActor
public final class LoginItemsViewModel: ObservableObject {
    @Published public private(set) var phase: LoginItemsPhase = .intro
    @Published public private(set) var sections: [LoginItemSection] = []
    @Published public private(set) var selection = ItemSelection()

    private let scanner: any LoginItemScanning
    private let cleanupService: CleanupService
    private let settingsOpener: any LoginItemsSettingsOpening
    private var activeTask: Task<Void, Never>?

    public init(
        scanner: any LoginItemScanning,
        cleanupService: CleanupService,
        settingsOpener: any LoginItemsSettingsOpening
    ) {
        self.scanner = scanner
        self.cleanupService = cleanupService
        self.settingsOpener = settingsOpener
    }

    // MARK: Derived state

    public var items: [LoginItem] { sections.flatMap(\.items) }
    public var orphanedCount: Int { items.count(where: \.isOrphaned) }

    /// Property lists that `remove()` would move to the Trash.
    public var selectedItems: [CleanableItem] {
        selection.selectedItems(in: items.filter(\.isRemovable).map(\.item))
    }

    public var selectedCount: Int { selectedItems.count }
    public var hasSelection: Bool { !selectedItems.isEmpty }

    // MARK: Actions

    @discardableResult
    public func startLoading() -> Task<Void, Never> {
        activeTask?.cancel()
        sections = []
        selection = ItemSelection()
        phase = .loading
        let task = Task {
            let items = await scanner.scan()
            guard !Task.isCancelled else { return }
            sections = LoginItemSection.sections(of: items)
            phase = .browsing
        }
        activeTask = task
        return task
    }

    /// Moves the selected agents to the Trash. They keep running until the next login.
    @discardableResult
    public func remove() -> Task<Void, Never>? {
        guard phase == .browsing else { return nil }
        let items = selectedItems
        guard !items.isEmpty else { return nil }
        phase = .removing
        let task = Task {
            let report = await cleanupService.clean(items)
            guard !Task.isCancelled else { return }
            phase = .finished(report)
        }
        activeTask = task
        return task
    }

    /// Leaves the finished screen and lists the items again.
    @discardableResult
    public func done() -> Task<Void, Never> {
        startLoading()
    }

    public func openLoginItemsSettings() {
        settingsOpener.openLoginItemsSettings()
    }

    // MARK: Selection

    public func isSelected(_ item: LoginItem) -> Bool {
        item.isRemovable && selection.contains(item.item)
    }

    public func toggle(_ item: LoginItem) {
        guard item.isRemovable else { return }
        selection.toggle(item.item)
    }

    /// State of a section's checkbox, over the items that can be removed.
    public func selectionState(of section: LoginItemSection) -> ItemSelection.State {
        selection.state(of: removableItems(in: section))
    }

    public func toggleAll(in section: LoginItemSection) {
        selection.toggleAll(removableItems(in: section))
    }

    private func removableItems(in section: LoginItemSection) -> [CleanableItem] {
        section.items.filter(\.isRemovable).map(\.item)
    }
}
