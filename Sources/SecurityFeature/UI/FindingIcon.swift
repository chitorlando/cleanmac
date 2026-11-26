import SwiftUI

/// How a finding looks at a glance.
enum FindingLevel {
    /// Nothing to do.
    case fine
    /// Worth a look, with a next step.
    case attention
    /// The review couldn't tell.
    case unknown

    init(_ state: ProtectionState) {
        switch state {
        case .on: self = .fine
        case .off, .partial, .outdated: self = .attention
        case .unknown: self = .unknown
        }
    }

    /// Orange rather than red: a finding is something to look at, not an alarm.
    var color: Color {
        switch self {
        case .fine: .green
        case .attention: .orange
        case .unknown: .secondary
        }
    }
}

/// Icon at the start of a finding that tells its level.
struct FindingIcon: View {
    let level: FindingLevel

    var body: some View {
        Image(systemName: symbolName)
            .font(.title3)
            .foregroundStyle(level.color)
            .frame(width: 24)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch level {
        case .fine: "checkmark.circle.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .unknown: "questionmark.circle"
        }
    }
}
