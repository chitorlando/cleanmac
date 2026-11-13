import SwiftUI

/// Whether a permission is on, as a colored icon and a word, so it isn't told by color alone.
struct PermissionStatusLabel: View {
    enum State {
        case on, off, notSetUp
    }

    let state: State

    var body: some View {
        Label {
            text
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(color)
        }
        .font(.callout.weight(.semibold))
    }

    private var text: Text {
        switch state {
        case .on: Text("On", bundle: .module, comment: "Status of a permission that is granted.")
        case .off: Text("Off", bundle: .module, comment: "Status of a permission that is not granted.")
        case .notSetUp: Text("Not set up yet", bundle: .module, comment: "Status of a permission the user hasn't been asked about.")
        }
    }

    private var symbolName: String {
        switch state {
        case .on: "checkmark.circle.fill"
        case .off: "exclamationmark.circle.fill"
        case .notSetUp: "circle.dashed"
        }
    }

    private var color: Color {
        switch state {
        case .on: .green
        case .off: .orange
        case .notSetUp: .secondary
        }
    }
}
