import AppKit
import CleanMacUI
import OnboardingFeature
import SwiftUI

/// The window's content: the permissions onboarding when it's due or asked for, over the
/// main screen, which keeps its state underneath.
///
/// Full Disk Access is read again whenever the app comes to the front, since the user grants
/// it in System Settings, and a reminder stays under the sidebar while it's off.
struct AppRootView: View {
    let modules: [any FeatureModule]
    let upcoming: [UpcomingFeature]
    @ObservedObject var permissions: PermissionsViewModel

    var body: some View {
        ZStack {
            RootView(modules: modules, upcoming: upcoming, sidebarNotice: notice)
                // Underneath the onboarding, its buttons and shortcuts must not react.
                .disabled(permissions.isPresented)
                .accessibilityHidden(permissions.isPresented)
            if permissions.isPresented {
                PermissionsOnboardingView(viewModel: permissions)
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.3), value: permissions.isPresented)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await permissions.refresh() }
        }
    }

    private var notice: AnyView? {
        guard permissions.showsFullDiskAccessNotice else { return nil }
        return AnyView(FullDiskAccessNotice { permissions.present() })
    }
}
