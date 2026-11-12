import CleanMacUI
import SwiftUI

/// The owner app's icon or, without an owner, a symbol for agents and daemons.
struct LoginItemIcon: View {
    let item: LoginItem

    var body: some View {
        if let owner = item.owner {
            AppIconView(url: owner.appURL, size: 32)
        } else {
            Image(systemName: item.kind == .daemon ? "gearshape.2.fill" : "gearshape.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
        }
    }
}
