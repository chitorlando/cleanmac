import Foundation
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
    var section: FeatureSection { get }

    func makeView() -> AnyView

    /// Shows the item at `url` when another feature opens this one for it, such as an app
    /// sent to the uninstaller. Features that can't show items ignore it.
    func show(itemAt url: URL)
}

public extension FeatureModule {
    func show(itemAt url: URL) {}
}
