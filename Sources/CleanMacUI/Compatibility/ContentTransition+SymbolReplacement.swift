import SwiftUI

extension ContentTransition {
    /// Swaps one SF Symbol for another with the system's replace effect.
    ///
    /// Symbol effects arrived in macOS 14. Earlier systems have nothing like them, so there
    /// the old symbol fades into the new one.
    ///
    /// Like any content transition, it only plays when the symbol changes within an animation.
    static var symbolReplacement: ContentTransition {
        if #available(macOS 14, *) {
            return .symbolEffect(.replace)
        } else {
            return .opacity
        }
    }
}
