import CleanMacCore
import Combine
import Foundation

/// Coordinates listing, selection and removal for the login items screen.
///
/// Nothing is selected after listing, and only the user's own agents can be selected:
/// shared items in `/Library` need an administrator to remove. Removing an agent moves
/// its property list to the Trash without unloading it, so it stops at the next login.
///
/// Another feature can limit the list to the items of one app, until the user lifts the limit.
/// Selected items the limit hides stay selected, but only the listed ones are removed.
@MainActor
public final class LoginItemsViewModel: ObservableObject {
    private static let appExtension = "app"

    @Published public private(set) var phase: LoginItemsPhase = .intro
    /// The listed items, only those of `appFilter` when there is one.
    @Published public private(set) var sections: [LoginItemSection] = []
    @Published public private(set) var selection = ItemSelection()
    /// Whether the user is asked to confirm moving the selected agents to the Trash, which
    /// `remove()` does.
    @Published public private(set) var isConfirmingRemoval = false
    /// The app whose items alone are listed, as another feature asked. `nil` lists every item.
    @Published public private(set) var appFilter: LoginItemOwner?

    /// Every item the last listing found, whatever `appFilter` leaves out.
    private var foundItems: [LoginItem] = []

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

    /// The listed items, only those of `appFilter` when there is one.
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
        foundItems = []
        sections = []
        selection = ItemSelection()
        phase = .loading
        let task = Task {
            let items = await scanner.scan()
            guard !Task.isCancelled else { return }
            foundItems = items
            updateSections()
            phase = .browsing
        }
        activeTask = task
        return task
    }

    /// Asks the user to confirm moving the selected agents to the Trash, and removes nothing.
    ///
    /// The remove button calls it, also when Return presses that button.
    public func requestRemoval() {
        guard phase == .browsing, hasSelection else { return }
        isConfirmingRemoval = true
    }

    /// Stops asking for confirmation, without removing anything.
    public func cancelRemoval() {
        isConfirmingRemoval = false
    }

    /// Moves the selected agents to the Trash, once the user confirmed it (see
    /// `requestRemoval()`). They keep running until the next login.
    @discardableResult
    public func remove() -> Task<Void, Never>? {
        isConfirmingRemoval = false
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

    // MARK: App filter

    /// Whether `showItems(ofAppAt:)` takes the item at `url`: any app bundle, with login items
    /// or not, since an app without any gets a screen that says so. Only its path is looked
    /// at, so it can be asked whenever a menu opens, without reading the disk or the items.
    public func canShowItems(ofAppAt url: URL) -> Bool {
        url.pathExtension.lowercased() == Self.appExtension
    }

    /// Lists only the items of the app at `url`, such as one another feature sends here.
    /// Anything that isn't an app bundle is ignored.
    ///
    /// The items are read first when they weren't yet, starting from the introduction. Items
    /// already read, or being read, aren't read again: the limit applies to them. During a
    /// removal and on its report, it applies to the list shown next.
    ///
    /// - Returns: The listing it starts, if any.
    @discardableResult
    public func showItems(ofAppAt url: URL) -> Task<Void, Never>? {
        guard canShowItems(ofAppAt: url) else { return nil }
        appFilter = LoginItemOwner(appURL: url.standardizedFileURL)
        updateSections()
        return phase == .intro ? startLoading() : nil
    }

    /// Lists every item again, lifting the limit `showItems(ofAppAt:)` set.
    public func showAllItems() {
        appFilter = nil
        updateSections()
    }

    private func updateSections() {
        let listed = appFilter.map { app in foundItems.filter { $0.belongs(toAppAt: app.appURL) } } ?? foundItems
        sections = LoginItemSection.sections(of: listed)
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
