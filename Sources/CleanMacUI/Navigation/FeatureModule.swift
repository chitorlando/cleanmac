import SwiftUI

/// Contract every feature implements to appear in the app.
///
/// New features are added by creating a module that conforms to this protocol
/// and registering it in the composition root, without touching other features.
@MainActor
public protocol FeatureModule: AnyObject {
    var id: String { get }
    var title: String { get }
    var symbolName: String { get }
    var theme: FeatureTheme { get }

    func makeView() -> AnyView
}
