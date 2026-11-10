import CleanMacUI
import SwiftUI

/// Feature module with only the data the sidebar reads.
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

    func makeView() -> AnyView {
        AnyView(EmptyView())
    }
}
