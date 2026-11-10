import SwiftUI

/// Tells the user that running the chosen tasks asks for the administrator password, once.
struct AdministratorPasswordNotice: View {
    var body: some View {
        Label {
            Text(
                "You’ll be asked for your administrator password once.",
                bundle: .module,
                comment: "Notice shown when the chosen maintenance tasks need the administrator password."
            )
        } icon: {
            Image(systemName: "lock.fill")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }
}
