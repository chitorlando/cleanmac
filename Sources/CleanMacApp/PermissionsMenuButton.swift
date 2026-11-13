import OnboardingFeature
import SwiftUI

/// Application menu command that opens the permissions screen again.
struct PermissionsMenuButton: View {
    @ObservedObject var permissions: PermissionsViewModel

    var body: some View {
        Button(action: permissions.present) {
            Text("Permissions…", bundle: .module, comment: "Application menu command that opens the permissions screen.")
        }
    }
}
