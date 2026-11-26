import CleanMacUI
import Foundation
import SwiftUI

/// The next steps for an item the review found: showing it in Finder and what the other
/// features of the app offer for the app it belongs to, such as showing it in the Uninstaller.
///
/// The other features are asked when the buttons are drawn. Only findings that need
/// attention show them, so that is a handful of apps at most.
struct NextStepButtons: View {
    let itemURL: URL
    /// The app the item belongs to, or the item itself when it is an app.
    let appURL: URL?

    @Environment(\.fileActions) private var files
    @Environment(\.openFeature) private var openFeature
    @Environment(\.featureItemActions) private var featureItemActions

    var body: some View {
        HStack(spacing: 16) {
            Button {
                files.showInFinder(itemURL)
            } label: {
                Text("Show in Finder", bundle: .module, comment: "Button that reveals an item found by the security review in Finder.")
            }
            if let appURL {
                ForEach(featureItemActions.offered(for: .app, at: appURL)) { action in
                    Button {
                        openFeature(action.featureID, showing: appURL)
                    } label: {
                        Text(verbatim: action.title)
                    }
                }
            }
        }
        .buttonStyle(.link)
        .font(.callout)
    }
}
