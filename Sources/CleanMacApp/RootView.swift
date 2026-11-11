import CleanMacUI
import SwiftUI

/// Main window: sidebar with features and the selected feature on the right.
///
/// Opens on the available feature at the top of the sidebar, whatever the order
/// in which the features were registered. Features can open each other through
/// the `openFeature` environment value.
struct RootView: View {
    let sections: SidebarSections

    @StateObject private var navigator: FeatureNavigator

    init(modules: [any FeatureModule], upcoming: [UpcomingFeature]) {
        let sections = SidebarSections(modules: modules, upcoming: upcoming)
        self.sections = sections
        _navigator = StateObject(wrappedValue: FeatureNavigator(modules: modules, selectedID: sections.firstModule?.id))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(sections: sections, selection: $navigator.selectedID)
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
        } detail: {
            detail
                .environment(\.openFeature, navigator.openFeatureAction)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let module = navigator.selectedModule {
            module.makeView()
                .id(module.id)
        } else {
            FeatureBackground(theme: .neutral)
        }
    }
}
