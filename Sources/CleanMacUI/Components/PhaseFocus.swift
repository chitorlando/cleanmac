import SwiftUI

extension View {
    /// Marks the circle a phase of a feature screen centers on, such as the scan button, the ring
    /// of a scan or of a busy view, or the badge of a finished cleanup.
    ///
    /// When the screen changes phase, the circle of the new phase grows out of the one of the old
    /// phase, wherever it was, so the scan button becomes the ring of the scan and the ring that
    /// moved items to the Trash becomes the badge that celebrates it. Only one view of a phase
    /// may be marked. Outside a ``FeatureScreen``, or with Reduce Motion on, nothing travels.
    func phaseFocus() -> some View {
        modifier(PhaseFocus())
    }
}

extension EnvironmentValues {
    /// The namespace of the feature screen the view is on, where the circle each phase centers
    /// on travels from one phase to the next.
    var phaseNamespace: Namespace.ID? {
        get { self[PhaseNamespaceKey.self] }
        set { self[PhaseNamespaceKey.self] = newValue }
    }
}

private struct PhaseNamespaceKey: EnvironmentKey {
    static var defaultValue: Namespace.ID? { nil }
}

/// Matches the circle a phase centers on with the one of the phase before it.
private struct PhaseFocus: ViewModifier {
    private static let id = "phaseFocus"

    @Environment(\.phaseNamespace) private var namespace
    @Environment(\.motionPolicy) private var motion

    func body(content: Content) -> some View {
        if let namespace, motion.allowsTravel {
            content.matchedGeometryEffect(id: Self.id, in: namespace)
        } else {
            content
        }
    }
}
