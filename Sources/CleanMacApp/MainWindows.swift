import AppKit
import CleanMacUI
import SwiftUI

/// The main windows of the app, each with the navigator of its features, so that something
/// outside them, such as the menu bar, can bring one back and show a feature in it.
///
/// Each main window adds itself once it's in a window. One the user closed is left out, even
/// while AppKit keeps it.
@MainActor
final class MainWindows {
    /// Id of the scene of the main windows, with which `OpenWindowAction` opens one.
    static let sceneID = "main"

    private struct Entry {
        weak var window: NSWindow?
        weak var navigator: FeatureNavigator?

        /// Whether the window is open: on screen, or minimized to the Dock.
        @MainActor var isOpen: Bool {
            guard let window, navigator != nil else { return false }
            return window.isVisible || window.isMiniaturized
        }
    }

    private struct FeatureRequest {
        let featureID: String
        let itemURL: URL?
    }

    private var entries: [Entry] = []
    /// What the next main window shows, asked for while none was open.
    private var pendingRequest: FeatureRequest?

    /// Notes that `window` is a main window whose features `navigator` shows, and shows in it
    /// the feature asked for while no main window was open.
    func add(_ window: NSWindow, navigator: FeatureNavigator) {
        entries.removeAll { $0.window == nil || $0.navigator == nil || $0.window === window }
        entries.append(Entry(window: window, navigator: navigator))
        if let request = pendingRequest {
            pendingRequest = nil
            navigator.open(request.featureID, showing: request.itemURL)
        }
    }

    /// Brings the app to the front with its frontmost main window, or a new one when none is
    /// open, which `openWindow` opens. That window then shows the feature with `featureID`,
    /// when given, and in it the item at `itemURL`.
    func show(featureID: String? = nil, showing itemURL: URL? = nil, openingWith openWindow: OpenWindowAction) {
        NSApp.unhide(nil)
        NSApp.activateAtUserRequest()
        guard let entry = frontmostOpenEntry, let window = entry.window else {
            pendingRequest = featureID.map { FeatureRequest(featureID: $0, itemURL: itemURL) }
            openWindow(id: Self.sceneID)
            return
        }
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        if let featureID {
            entry.navigator?.open(featureID, showing: itemURL)
        }
    }

    /// The action with which features outside the main windows open one of them, through the
    /// window's navigator, as `show(featureID:showing:openingWith:)` does.
    func openFeatureAction(openingWith openWindow: OpenWindowAction) -> OpenFeatureAction {
        let opener = WindowOpener(openWindow)
        return OpenFeatureAction { [weak self] featureID, itemURL in
            self?.show(featureID: featureID, showing: itemURL, openingWith: opener.openWindow)
        }
    }

    /// The open main window nearest the front, those on screen before those minimized.
    private var frontmostOpenEntry: Entry? {
        let open = entries.filter { $0.isOpen }
        let front = NSApp.orderedWindows.first { window in open.contains { $0.window === window } }
        return open.first { $0.window === front } ?? open.last
    }
}

/// Holds the action that opens windows for the actions that must be `Sendable`, which it
/// isn't on every system.
@MainActor
private final class WindowOpener {
    let openWindow: OpenWindowAction

    init(_ openWindow: OpenWindowAction) {
        self.openWindow = openWindow
    }
}
