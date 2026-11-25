import CleanMacUI
import Foundation
import SwiftUI

/// The entries of the context menu of an item, with a line between its groups.
///
/// The menu is worked out when it opens, not with each row: the other features of the app,
/// read from the environment, are asked then whether they take the item, which may look at
/// the disk. See `DiskMapItemMenu`.
struct DiskMapItemMenuItems: View {
    let url: URL
    let advice: RemovalAdvice
    let canOpen: Bool
    let isSelected: Bool
    /// Carries out the entry the user chose.
    let perform: (DiskMapItemCommand) -> Void

    @Environment(\.featureItemActions) private var featureItemActions

    var body: some View {
        let menu = DiskMapItemMenu(advice: advice, canOpen: canOpen, isSelected: isSelected) { kind in
            featureItemActions.offered(for: kind, at: url)
        }
        ForEach(Array(menu.sections.enumerated()), id: \.offset) { index, commands in
            if index > 0 {
                Divider()
            }
            ForEach(commands) { command in
                Button {
                    perform(command)
                } label: {
                    Label {
                        command.title
                    } icon: {
                        Image(systemName: command.symbolName)
                    }
                }
            }
        }
    }
}
