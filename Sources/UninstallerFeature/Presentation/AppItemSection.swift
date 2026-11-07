import CleanMacCore

/// A group of an app's items shown together in the detail pane:
/// the app bundle first, then its leftovers grouped by kind.
public struct AppItemSection: Identifiable, Hashable, Sendable {
    public enum Category: Hashable, Sendable {
        case application
        case leftover(LeftoverKind)
    }

    public let category: Category
    public let items: [CleanableItem]

    public var id: Category { category }
    public var totalSize: Int64 { items.totalSize }

    public init(category: Category, items: [CleanableItem]) {
        self.category = category
        self.items = items
    }

    /// The bundle, then one section per leftover kind that has items, in `LeftoverKind` order.
    public static func sections(of app: InstalledApp) -> [AppItemSection] {
        let leftoverSections = LeftoverKind.allCases.compactMap { kind -> AppItemSection? in
            let items = app.leftovers.filter { $0.kind == kind }.map(\.item)
            return items.isEmpty ? nil : AppItemSection(category: .leftover(kind), items: items)
        }
        return [AppItemSection(category: .application, items: [app.bundle])] + leftoverSections
    }
}
