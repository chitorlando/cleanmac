import CleanMacUI
import SwiftUI

/// Main window: sidebar with features and the selected feature on the right.
///
/// Opens on the available feature at the top of the sidebar, whatever the order
/// in which the features were registered. Features can open each other through
/// the `openFeature` environment value, and find what the others offer to do with
/// their items in `featureItemActions`.
struct RootView: View {
    let sections: SidebarSections
    /// Shown under the sidebar's list, such as a reminder about a missing permission.
    let sidebarNotice: AnyView?

    @StateObject private var navigator: FeatureNavigator

    init(modules: [any FeatureModule], upcoming: [UpcomingFeature], sidebarNotice: AnyView? = nil) {
        let sections = SidebarSections(modules: modules, upcoming: upcoming)
        self.sections = sections
        self.sidebarNotice = sidebarNotice
        _navigator = StateObject(wrappedValue: FeatureNavigator(modules: modules, selectedID: sections.firstModule?.id))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(sections: sections, selection: $navigator.selectedID)
                .safeAreaInset(edge: .bottom, spacing: 0) { sidebarNotice }
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
        } detail: {
            detail
                .environment(\.openFeature, navigator.openFeatureAction)
                .environment(\.featureItemActions, navigator.itemActions)
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
