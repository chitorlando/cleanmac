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

    /// Whether `show(itemAt:)` would do something with the item at `url`, so that other
    /// features offer this one's actions only for the items it takes. Features that take any
    /// item of the kinds they offer actions for keep the default, `true`.
    ///
    /// Asked when a menu opens, so it may look at the disk, but it shouldn't take long.
    func canShow(itemAt url: URL) -> Bool

    /// What the feature offers to do with items shown by other features, each carried out
    /// by `show(itemAt:)` on the items `canShow(itemAt:)` accepts. Features that take no items
    /// offer nothing.
    var itemActions: [FeatureItemAction] { get }
}

public extension FeatureModule {
    func show(itemAt url: URL) {}

    func canShow(itemAt url: URL) -> Bool { true }

    var itemActions: [FeatureItemAction] { [] }
}
