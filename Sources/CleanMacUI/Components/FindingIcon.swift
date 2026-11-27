import SwiftUI

/// How a finding looks at a glance.
public enum FindingLevel: Hashable, Sendable {
    /// Nothing to do.
    case fine
    /// Worth a look, with a next step.
    case attention
    /// The review couldn't tell.
    case unknown

    /// Orange rather than red: a finding is something to look at, not an alarm.
    public var color: Color {
        switch self {
        case .fine: .green
        case .attention: .orange
        case .unknown: .secondary
        }
    }
}

/// Icon at the start of a finding of a review that tells its level, such as one of the
/// security review.
public struct FindingIcon: View {
    private let level: FindingLevel

    public init(level: FindingLevel) {
        self.level = level
    }

    public var body: some View {
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
