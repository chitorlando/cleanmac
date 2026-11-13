import SwiftUI

/// The entries of the context menu of an item, with a line between its groups.
struct DiskMapItemMenuItems: View {
    let menu: DiskMapItemMenu
    /// Carries out the entry the user chose.
    let perform: (DiskMapItemCommand) -> Void

    var body: some View {
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
