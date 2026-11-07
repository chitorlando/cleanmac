import SwiftUI

/// Checkbox that can also show a mixed state for partially selected groups.
public struct TriStateCheckbox: View {
    private let state: CheckState
    private let tint: Color
    private let label: Text
    private let action: () -> Void

    /// - Parameter label: What the checkbox selects, read by VoiceOver, such as the item's name.
    public init(state: CheckState, tint: Color, label: Text, action: @escaping () -> Void) {
        self.state = state
        self.tint = tint
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(state == .unchecked ? Color.secondary : tint)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(.isToggle)
    }

    private var symbolName: String {
        switch state {
        case .checked: "checkmark.circle.fill"
        case .mixed: "minus.circle.fill"
        case .unchecked: "circle"
        }
    }

    private var accessibilityValue: Text {
        switch state {
        case .checked: Text("Selected", bundle: .module)
        case .mixed: Text("Partially selected", bundle: .module)
        case .unchecked: Text("Not selected", bundle: .module)
        }
    }
}
