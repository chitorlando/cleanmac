import SwiftUI

/// The motion language of the app: how long things take and how they move, so every screen
/// moves the same way.
///
/// Screens, lists and celebrations use these instead of numbers of their own. Whether a view
/// may move at all, given the accessibility settings, is up to ``MotionPolicy``.
public enum Motion {
    // MARK: Durations

    /// Feedback on hover, press and selection.
    public static let quick: TimeInterval = 0.15
    /// A screen changing phase, the same as the root view of each feature animates with.
    public static let standard: TimeInterval = 0.35
    /// A row or card entering a list.
    public static let entranceDuration: TimeInterval = 0.45
    /// Time between rows that enter a list one after the other.
    public static let staggerStep: TimeInterval = 0.045
    /// Rows past this many enter together with the last staggered one, so a long list never
    /// keeps the user waiting.
    public static let maxStaggeredRows = 8
    /// The checkmark of a finished cleanup drawing itself.
    public static let checkmarkDuration: TimeInterval = 0.5
    /// The pause before the checkmark starts drawing, while its badge pops in.
    public static let checkmarkDelay: TimeInterval = 0.15
    /// The freed size counting up to its value.
    public static let countUpDuration: TimeInterval = 1.1
    /// The burst around the badge of a finished cleanup.
    public static let burstDuration: TimeInterval = 0.9
    /// One breath of the glow behind a scan, in and out.
    public static let breathPeriod: TimeInterval = 3.2

    // MARK: Distances and sizes

    /// How far a new phase rises into place.
    public static let phaseRise: CGFloat = 14
    /// How far a row rises as it enters a list.
    public static let entranceRise: CGFloat = 12
    /// How much a glowing button grows under the pointer.
    public static let hoverScale: CGFloat = 1.03
    /// How much a glowing button shrinks while pressed.
    public static let pressScale: CGFloat = 0.95

    // MARK: Animations

    /// A screen changing phase.
    public static var phaseChange: Animation { .smooth(duration: standard) }
    /// Hover and selection feedback.
    public static var feedback: Animation { .snappy(duration: quick) }
    /// A button being pressed or released.
    public static var press: Animation { .snappy(duration: 0.2) }
    /// A total, such as the size of what is selected, changing.
    public static var totals: Animation { .smooth(duration: 0.3) }
    /// A row or card entering a list, before its delay.
    public static var entrance: Animation { .smooth(duration: entranceDuration) }
    /// Something lively settling into place, such as a badge popping in or an icon leaning.
    public static var pop: Animation { .bouncy(duration: 0.5, extraBounce: 0.1) }
    /// The checkmark of a finished cleanup drawing itself.
    public static var checkmark: Animation { .easeOut(duration: checkmarkDuration).delay(checkmarkDelay) }
    /// A number counting up to its value: fast at first, slowing down as it gets there.
    public static var countUp: Animation { .easeOut(duration: countUpDuration) }
    /// The burst around the badge of a finished cleanup.
    public static var burst: Animation { .easeOut(duration: burstDuration) }
}
