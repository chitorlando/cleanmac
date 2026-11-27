import SwiftUI

/// What motion and translucency a view may use, following the accessibility settings.
///
/// With Reduce Motion on, nothing travels, pops, bursts or drifts: views only fade. With
/// Reduce Transparency on, glows give way to plain shapes. Views read it from the environment,
/// as `@Environment(\.motionPolicy)`.
public struct MotionPolicy: Equatable, Sendable {
    public let reducesMotion: Bool
    public let reducesTransparency: Bool

    public init(reducesMotion: Bool, reducesTransparency: Bool) {
        self.reducesMotion = reducesMotion
        self.reducesTransparency = reducesTransparency
    }

    /// Whether decorations may move on their own, such as particles, bursts and a breathing glow.
    public var animatesDecorations: Bool { !reducesMotion }

    /// Whether views may travel, grow or count between states, rather than only fade.
    public var allowsTravel: Bool { !reducesMotion }

    /// Whether soft glows may be drawn around shapes and symbols.
    public var drawsGlows: Bool { !reducesTransparency }

    /// How far a row rises as it enters a list.
    public var entranceRise: CGFloat {
        allowsTravel ? Motion.entranceRise : 0
    }

    /// How long the row at `index` waits before entering a list: a little longer than the one
    /// before it, up to `Motion.maxStaggeredRows` rows. With Reduce Motion on, every row fades
    /// in at once.
    public func entranceDelay(forRowAt index: Int) -> TimeInterval {
        guard allowsTravel else { return 0 }
        return Double(min(max(index, 0), Motion.maxStaggeredRows)) * Motion.staggerStep
    }
}

public extension EnvironmentValues {
    /// What motion and translucency views may use, following the accessibility settings.
    var motionPolicy: MotionPolicy {
        MotionPolicy(
            reducesMotion: accessibilityReduceMotion,
            reducesTransparency: accessibilityReduceTransparency
        )
    }
}
