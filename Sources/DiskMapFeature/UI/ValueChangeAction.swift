import SwiftUI

/// Runs an action with the new value each time a value changes.
///
/// The `onChange` that hands over the old and the new value needs macOS 14, and the one it
/// replaced is deprecated from that version on, so each system gets its own.
struct ValueChangeAction<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value) -> Void

    func body(content: Content) -> some View {
        if #available(macOS 14, *) {
            content.onChange(of: value) { _, newValue in action(newValue) }
        } else {
            content.onChange(of: value, perform: action)
        }
    }
}

extension View {
    /// Runs `action` with the new value each time `value` changes, on every supported macOS.
    func onValueChange<Value: Equatable>(of value: Value, perform action: @escaping (Value) -> Void) -> some View {
        modifier(ValueChangeAction(value: value, action: action))
    }
}
