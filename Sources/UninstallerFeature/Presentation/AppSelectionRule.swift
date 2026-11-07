import CleanMacCore

/// Selects whole apps without ever picking a shared leftover automatically.
///
/// Choosing an app marks its bundle and the leftovers no other installed app uses.
/// Shared leftovers can only be marked one by one, on purpose.
public struct AppSelectionRule: Sendable {
    public let shared: SharedLeftovers

    public init(shared: SharedLeftovers) {
        self.shared = shared
    }

    /// The bundle followed by every leftover that is not shared.
    public func automaticItems(of app: InstalledApp) -> [CleanableItem] {
        app.allItems.filter { !shared.contains($0) }
    }

    public func state(of app: InstalledApp, in selection: ItemSelection) -> ItemSelection.State {
        let state = selection.state(of: automaticItems(of: app))
        if state == .none, app.allItems.contains(where: selection.contains) {
            return .some
        }
        return state
    }

    /// Clears every item of a fully selected app; otherwise selects its automatic items.
    public func toggle(_ app: InstalledApp, in selection: inout ItemSelection) {
        toggle([app], in: &selection)
    }

    public func state(of apps: [InstalledApp], in selection: ItemSelection) -> ItemSelection.State {
        let states = Set(apps.map { state(of: $0, in: selection) })
        switch states {
        case [.all]: return .all
        case [], [.none]: return .none
        default: return .some
        }
    }

    /// Clears every item when all the apps are fully selected; otherwise selects their automatic items.
    public func toggle(_ apps: [InstalledApp], in selection: inout ItemSelection) {
        if state(of: apps, in: selection) == .all {
            selection.deselect(apps.flatMap(\.allItems))
        } else {
            selection.select(apps.flatMap(automaticItems(of:)))
        }
    }
}
