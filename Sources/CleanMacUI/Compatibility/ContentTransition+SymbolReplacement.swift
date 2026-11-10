import SwiftUI

extension ContentTransition {
    /// Swaps one SF Symbol for another with the system's replace effect.
    ///
    /// Symbol effects arrived in macOS 14. Earlier systems have nothing like them, so there
    /// the new symbol takes the place of the old one at once.
    static var symbolReplacement: ContentTransition {
        if #available(macOS 14, *) {
            return .symbolEffect(.replace)
        } else {
            return .identity
        }
    }
}
