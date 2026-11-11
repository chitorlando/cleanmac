import CleanMacUI
import Foundation
import SwiftUI

/// Feature module with only the data the sidebar reads, which records the items it's asked to show.
@MainActor
final class FakeFeature: FeatureModule {
    let id: String
    let title: String
    let symbolName = "circle"
    let theme = FeatureTheme.neutral
    let section: FeatureSection

    init(_ id: String, in section: FeatureSection) {
        self.id = id
        self.title = id
        self.section = section
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
