import CleanMacUI

extension FindingLevel {
    /// How a protection set this way looks at a glance.
    init(_ state: ProtectionState) {
        switch state {
        case .on: self = .fine
        case .off, .partial, .outdated: self = .attention
        case .unknown: self = .unknown
        }
    }
}
