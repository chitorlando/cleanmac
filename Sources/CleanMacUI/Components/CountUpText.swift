import SwiftUI

/// Text that counts up from zero to a number the first time it appears, such as the space a
/// cleanup freed: quickly at first, slowing down as it gets there. Its digits keep a fixed
/// width, so the text doesn't jitter as they change.
///
/// VoiceOver reads the final text straight away. With Reduce Motion on, the final text shows
/// without counting.
public struct CountUpText: View {
    private let value: Int64
    private let format: (Int64) -> String
    @Environment(\.motionPolicy) private var motion
    @State private var hasCounted = false

    /// - Parameters:
    ///   - value: The number to count up to, such as a number of bytes.
    ///   - format: The text for a number along the way, such as “1.2 GB freed” for the bytes freed.
    public init(_ value: Int64, format: @escaping (Int64) -> String) {
        self.value = value
        self.format = format
    }

    public var body: some View {
        CountingText(count: isCounted ? Double(value) : 0, target: value, format: format)
            .accessibilityLabel(Text(verbatim: format(value)))
            .onAppear {
                guard !hasCounted else { return }
                withAnimation(Motion.countUp) { hasCounted = true }
            }
    }

    /// Whether the number has reached its value, or skips counting with Reduce Motion on.
    private var isCounted: Bool {
        hasCounted || !motion.allowsTravel
    }
}

/// Text that shows a number while it's animated toward its target, as the whole number it has
/// reached so far.
struct CountingText: View, Animatable {
    var count: Double
    let target: Int64
    let format: (Int64) -> String

    nonisolated var animatableData: Double {
        get { count }
        set { count = newValue }
    }

    var body: some View {
        Text(verbatim: format(CountUp.shownValue(for: count, target: target)))
            .monospacedDigit()
    }
}

/// How a number counting up from zero is shown along the way.
enum CountUp {
    /// The whole number to show when the count has reached `count` on its way from zero to
    /// `target`: rounded, and never outside the way, even when the animation overshoots.
    static func shownValue(for count: Double, target: Int64) -> Int64 {
        let start = min(0, target)
        let end = max(0, target)
        guard count.isFinite else { return target }
        let rounded = count.rounded()
        if rounded <= Double(start) { return start }
        if rounded >= Double(end) { return end }
        return Int64(rounded)
    }
}
