import CleanMacCore
import Foundation

/// Remembers what was worked out from the selection for each app of a list, so that a change
/// to a few items only repeats the work for the apps that list them.
///
/// Asking an `ItemSelection` about an item hashes its URL. Over the thousands of items of a
/// few hundred apps that takes most of a frame, too long to repeat on every toggle.
///
/// It doesn't watch the selection: whoever changes it says which items changed with
/// `forget(appsListing:)`, and calls `forgetEverything()` when the answers change for
/// any other reason.
struct AppSelectionMemo {
    /// Where each app is in the list.
    private let positions: [InstalledApp.ID: Int]
    /// Positions of the apps that list each item. Shared leftovers have more than one.
    private let owners: [CleanableItem.ID: [Int]]
    /// The items each app is the first to list, so that joining them repeats none.
    private let firstListedItems: [[CleanableItem]]
    private var states: [ItemSelection.State?]
    private var selectedItems: [[CleanableItem]?]

    init(apps: [InstalledApp]) {
        var positions: [InstalledApp.ID: Int] = [:]
        var owners: [CleanableItem.ID: [Int]] = [:]
        var firstListedItems: [[CleanableItem]] = []
        for (position, app) in apps.enumerated() {
            if positions[app.id] == nil {
                positions[app.id] = position
            }
            var firstListed: [CleanableItem] = []
            for item in app.allItems {
                if owners[item.id] == nil {
                    firstListed.append(item)
                }
                owners[item.id, default: []].append(position)
            }
            firstListedItems.append(firstListed)
        }
        self.positions = positions
        self.owners = owners
        self.firstListedItems = firstListedItems
        states = Array(repeating: nil, count: apps.count)
        selectedItems = Array(repeating: nil, count: apps.count)
    }

    /// The state of each of `apps`, asking `state` only about the ones it doesn't remember.
    mutating func states(
        of apps: [InstalledApp],
        computedBy state: (InstalledApp) -> ItemSelection.State
    ) -> [ItemSelection.State] {
        apps.map { app in
            guard let position = positions[app.id] else { return state(app) }
            if let remembered = states[position] { return remembered }
            let computed = state(app)
            states[position] = computed
            return computed
        }
    }

    /// The items of the list that `isSelected` accepts, in the order of the list and once each.
    /// It only asks about the items of the apps it doesn't remember.
    mutating func selectedItems(where isSelected: (CleanableItem) -> Bool) -> [CleanableItem] {
        for position in selectedItems.indices where selectedItems[position] == nil {
            selectedItems[position] = firstListedItems[position].filter(isSelected)
        }
        return selectedItems.flatMap { $0 ?? [] }
    }

    /// Forgets what it remembers about the apps that list any of `items`.
    mutating func forget(appsListing items: [CleanableItem]) {
        for item in items {
            for position in owners[item.id] ?? [] {
                states[position] = nil
                selectedItems[position] = nil
            }
        }
    }

    mutating func forgetEverything() {
        states = Array(repeating: nil, count: states.count)
        selectedItems = Array(repeating: nil, count: selectedItems.count)
    }
}
