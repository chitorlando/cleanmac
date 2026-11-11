import SwiftUI

/// How each scope is introduced in the list.
extension LaunchScope {
    var title: Text {
        switch self {
        case .currentUser:
            Text("Only You", bundle: .module, comment: "Title of the login items that only run for the current user.")
        case .allUsers:
            Text("All Users", bundle: .module, comment: "Title of the login items shared by every user of the Mac.")
        }
    }

    var summary: Text {
        switch self {
        case .currentUser:
            Text(
                "Your own agents. Removed ones stop running at your next login.",
                bundle: .module,
                comment: "Description of the login items that only run for the current user."
            )
        case .allUsers:
            Text(
                "Shared by every user. Removing them needs an administrator, so here you can only show them in Finder.",
                bundle: .module,
                comment: "Description of the login items shared by every user, which CleanMac can't remove."
            )
        }
    }
}
