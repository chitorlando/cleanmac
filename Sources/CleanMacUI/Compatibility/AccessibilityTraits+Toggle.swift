import SwiftUI

extension AccessibilityTraits {
    /// Marks a control that switches between on and off, on the systems that know the trait.
    ///
    /// The toggle trait arrived in macOS 14. Earlier systems get no extra trait: the control
    /// keeps the ones it already has, such as being a button, and its accessibility value
    /// still tells whether it's on.
    static var toggleWhereSupported: AccessibilityTraits {
        if #available(macOS 14, *) {
            return .isToggle
        } else {
            return []
        }
    }
}
