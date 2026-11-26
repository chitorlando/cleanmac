import CleanMacUI
import SwiftUI

extension UninstallConfirmation {
    /// Most apps the title names. With more, it counts them instead.
    private static let maximumNamedApps = 3

    /// The question, such as “Uninstall Notes and Zoom?”.
    var title: Text {
        if appNames.isEmpty {
            return Text(
                "Move \(leftoverCount) leftover items to the Trash?",
                bundle: .module,
                comment: "Title of the dialog that asks before uninstalling, when only leftover files of apps are selected. The argument is how many."
            )
        }
        if appNames.count > Self.maximumNamedApps {
            return Text(
                "Uninstall \(appNames.count) apps?",
                bundle: .module,
                comment: "Title of the dialog that asks before uninstalling more than three apps. The argument is how many."
            )
        }
        return Text(
            "Uninstall \(appNames.formatted(.list(type: .and)))?",
            bundle: .module,
            comment: "Title of the dialog that asks before uninstalling a few apps. The argument lists their names, such as “Notes and Zoom”."
        )
    }

    /// What goes to the Trash with the apps, the space it all takes up, and that it can be put back.
    var message: Text {
        guard !appNames.isEmpty, leftoverCount > 0 else {
            return Text(
                "That’s \(size.formattedByteCount) in all. You can put everything back from the Trash.",
                bundle: .module,
                comment: "Message of the dialog that asks before uninstalling, when there are no leftovers besides the apps or only leftovers. The argument is a size, such as “1.2 GB”."
            )
        }
        return Text(
            "\(leftoverCount) leftover items will also be moved to the Trash, \(size.formattedByteCount) in all. You can put everything back from there.",
            bundle: .module,
            comment: "Message of the dialog that asks before uninstalling apps. The arguments are how many of their leftover files go to the Trash with them, and the size of everything, such as “1.2 GB”."
        )
    }
}
