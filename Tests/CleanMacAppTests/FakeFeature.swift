import CleanMacUI
import Foundation
import SwiftUI

/// Feature module with only the data the sidebar reads, which records the items it's asked to show
/// and offers the item actions it's given, for any item but those it refuses.
@MainActor
final class FakeFeature: FeatureModule {
    let id: String
    let title: String
    let symbolName = "circle"
    let theme = FeatureTheme.neutral
    let section: FeatureSection
    let itemActions: [FeatureItemAction]
    private let refusedItems: Set<URL>

    init(
        _ id: String,
        in section: FeatureSection,
        offering itemKinds: [FeatureItemKind] = [],
        refusing refusedItems: Set<URL> = []
    ) {
        self.id = id
        self.title = id
        self.section = section
        self.itemActions = itemKinds.map {
            FeatureItemAction(featureID: id, itemKind: $0, title: id, symbolName: "circle")
        }
        self.refusedItems = refusedItems
    }

    func canShow(itemAt url: URL) -> Bool {
        !refusedItems.contains(url)
    }

    /// Items other features asked it to show, in order.
    private(set) var shownItems: [URL] = []

    func makeView() -> AnyView {
        AnyView(EmptyView())
    }

    func show(itemAt url: URL) {
        shownItems.append(url)
    }
}
