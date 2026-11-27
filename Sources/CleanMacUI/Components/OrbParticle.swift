import Foundation

/// One of the particles that drift in toward the ring of a scan.
///
/// Where a particle is depends only on the time, so the orb keeps no state to animate them.
/// Each one takes `lifetime` seconds to drift from the edge of the orb to the ring, a fraction
/// of that time behind the one before it, and starts each trip from a different angle so the
/// trips never look the same.
struct OrbParticle: Equatable {
    /// Where a particle is at a given moment, and how it looks there.
    struct Position: Equatable {
        /// How far along its trip the particle is, from 0 at the edge of the orb to 1 at the ring.
        let progress: Double
        /// The angle from the center of the orb, in radians.
        let angle: Double
        /// How much of the way between the ring and the edge is still ahead, from 1 at the edge
        /// to 0 at the ring. It shrinks faster as the particle gets closer, as if pulled in.
        let distance: Double
        /// How visible the particle is: it fades in as it sets off and out as it reaches the ring.
        let opacity: Double
        /// How big the particle is compared to when it sets off.
        let scale: Double
    }

    /// How many particles drift at once: few, so drawing them stays light on older Macs.
    static let count = 12
    /// Seconds a particle takes to drift from the edge of the orb to the ring.
    static let lifetime: TimeInterval = 2.8
    /// How far a particle turns around the center on its way in, in radians.
    static let swirl = 0.9

    /// Spreads the particles evenly around the center, whatever their number.
    private static let goldenAngle = Double.pi * (3 - 5.squareRoot())
    /// How far each new trip turns the angle a particle sets off from, in radians.
    private static let tripTurn = 2.2
    /// Shares of the trip spent fading in and fading out.
    private static let fadeIn = 0.2
    private static let fadeOut = 0.25
    /// The size of a particle reaching the ring, compared to when it sets off.
    private static let finalScale = 0.45

    let index: Int

    /// Where the particle is at `time`, in seconds since any fixed moment.
    func position(at time: TimeInterval) -> Position {
        let laps = time / Self.lifetime + Double(index) / Double(Self.count)
        let trip = laps.rounded(.down)
        let progress = laps - trip
        let tripAngle = (trip * Self.tripTurn).truncatingRemainder(dividingBy: 2 * .pi)
        return Position(
            progress: progress,
            angle: Double(index) * Self.goldenAngle + tripAngle + Self.swirl * progress,
            distance: 1 - pow(progress, 1.6),
            opacity: max(0, min(progress / Self.fadeIn, 1) * min((1 - progress) / Self.fadeOut, 1)),
            scale: 1 - (1 - Self.finalScale) * progress
        )
    }
}
