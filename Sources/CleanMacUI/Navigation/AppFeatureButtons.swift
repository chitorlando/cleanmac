import Foundation
import SwiftUI

/// A button for each thing the other features of the app offer to do with an app, such as
/// showing it in the Uninstaller, titled as they name it. Features that wouldn't take the app
/// get no button, and outside the app shell there is none.
///
/// The features are asked when the buttons are drawn, so show them for a handful of apps at
/// most, such as the findings of a review. Put them in a stack, which lays them out with its
/// other buttons.
public struct AppFeatureButtons: View {
    private let appURL: URL

    @Environment(\.openFeature) private var openFeature
    @Environment(\.featureItemActions) private var featureItemActions

    public init(appURL: URL) {
        self.appURL = appURL
    }

    public var body: some View {
        ForEach(featureItemActions.offered(for: .app, at: appURL)) { action in
            Button {
                openFeature(action.featureID, showing: appURL)
            } label: {
                Text(verbatim: action.title)
            }
        }
    }
}
