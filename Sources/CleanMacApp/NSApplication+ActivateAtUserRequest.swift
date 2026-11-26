import AppKit

extension NSApplication {
    /// Brings the app to the front, as the user asked.
    ///
    /// Activation that cooperates with the app in front arrived in macOS 14. Earlier systems
    /// only have the call that takes the focus outright.
    func activateAtUserRequest() {
        if #available(macOS 14, *) {
            activate()
        } else {
            activate(ignoringOtherApps: true)
        }
    }
}
