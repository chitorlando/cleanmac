import SwiftUI

/// Opens System Settings › General › Login Items, where apps also register items without a property list.
struct OpenLoginItemsSettingsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label {
                Text("Open Login Items Settings", bundle: .module, comment: "Button that opens the Login Items pane of System Settings.")
            } icon: {
                Image(systemName: "gearshape")
            }
        }
        .help(Text(
            "Some apps add items that only System Settings lists.",
            bundle: .module,
            comment: "Tooltip of the button that opens the Login Items pane of System Settings."
        ))
    }
}
