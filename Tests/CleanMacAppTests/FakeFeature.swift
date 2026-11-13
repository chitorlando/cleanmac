import CleanMacUI
import Foundation
import SwiftUI

/// Feature module with only the data the sidebar reads, which records the items it's asked to show
/// and offers the item actions it's given.
@MainActor
final class FakeFeature: FeatureModule {
    let id: String
    let title: String
    let symbolName = "circle"
    let theme = FeatureTheme.neutral
    let section: FeatureSection
    let itemActions: [FeatureItemAction]

    init(_ id: String, in section: FeatureSection, offering itemKinds: [FeatureItemKind] = []) {
        self.id = id
        self.title = id
        self.section = section
        self.itemActions = itemKinds.map {
            FeatureItemAction(featureID: id, itemKind: $0, title: id, symbolName: "circle")
        }
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
