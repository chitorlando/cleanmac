import SwiftUI

public extension View {
    /// Puts the glow of a scan behind the view, such as the ring of a scan or of a busy view:
    /// it breathes in the feature's colors, and a few particles drift in toward the view from
    /// `reach` points beyond it.
    func scanningOrb(theme: FeatureTheme, reach: CGFloat) -> some View {
        background {
            ScanningOrb(theme: theme, reach: reach)
                .padding(-reach)
        }
    }
}

/// Glow in the feature's colors that breathes around the ring of a scan, with a few particles
/// drifting in toward the ring, as if it gathered what the scan finds.
///
/// It only moves while its window is shown, and at most 30 times a second. The glow breathes
/// by growing and brightening a little, which only moves and fades what's already drawn, and
/// the particles are a handful of small dots, so it stays light on older Macs. With Reduce
/// Motion on, the glow stands still and there are no particles. With Reduce Transparency on,
/// there is no glow.
struct ScanningOrb: View {
    /// Plenty for a slow drift, and half the work of following the display.
    private static let framesPerSecond: Double = 30

    let theme: FeatureTheme
    /// How far beyond the ring the particles set off from.
    let reach: CGFloat
    @Environment(\.motionPolicy) private var motion

    var body: some View {
        GeometryReader { proxy in
            let outer = min(proxy.size.width, proxy.size.height) / 2
            orb(outer: outer, inner: max(outer - reach, 0))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The glow and the particles around a ring of radius `inner`, out to `outer`.
    @ViewBuilder
    private func orb(outer: CGFloat, inner: CGFloat) -> some View {
        if motion.animatesDecorations {
            AnimationFrames(minimumInterval: 1 / Self.framesPerSecond) { date in
                let time = date.timeIntervalSinceReferenceDate
                ZStack {
                    if motion.drawsGlows {
                        halo(outer: outer, inner: inner, breath: OrbBreath.value(at: time))
                    }
                    particles(outer: outer, inner: inner, time: time)
                }
            }
        } else if motion.drawsGlows {
            halo(outer: outer, inner: inner, breath: OrbBreath.still)
        }
    }

    /// A halo that is brightest just around the ring and fades out toward the edge. The middle
    /// stays dark, so the figure inside the ring keeps its contrast.
    private func halo(outer: CGFloat, inner: CGFloat, breath: Double) -> some View {
        let peak = outer > 0 ? min(inner / outer, 0.9) : 0
        let gradient = RadialGradient(
            stops: [
                .init(color: theme.primary.opacity(0), location: peak * 0.6),
                .init(color: theme.primary.opacity(0.32), location: peak),
                .init(color: theme.secondary.opacity(0.13), location: peak + (1 - peak) * 0.45),
                .init(color: theme.secondary.opacity(0), location: 1)
            ],
            center: .center,
            startRadius: 0,
            endRadius: outer
        )
        return Circle()
            .fill(gradient)
            .scaleEffect(CGFloat(0.92 + 0.08 * breath))
            .opacity(0.6 + 0.4 * breath)
    }

    private func particles(outer: CGFloat, inner: CGFloat, time: TimeInterval) -> some View {
        let theme = self.theme
        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            OrbParticleRenderer.draw(in: &context, center: center, inner: inner, outer: outer, time: time, theme: theme)
        }
    }
}

/// The breath of the glow behind a scan.
enum OrbBreath {
    /// How far into a breath a still glow rests: halfway.
    static let still = 0.5

    /// How far into its breath the glow is at `time`: from 0, at its smallest and faintest, to 1
    /// and back, once every `Motion.breathPeriod`.
    static func value(at time: TimeInterval) -> Double {
        0.5 + 0.5 * sin(2 * .pi * time / Motion.breathPeriod)
    }
}

/// Draws the particles of the orb of a scan at a given moment. It keeps no state: what it
/// draws depends only on the time.
enum OrbParticleRenderer {
    /// How far the trail of a particle lags behind it, in seconds.
    private static let trailLag: TimeInterval = 0.07

    /// Draws each particle with a fainter, smaller trail just behind it, alternating the theme's
    /// colors, on its way from `outer` to `inner` points from `center`.
    static func draw(
        in context: inout GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        time: TimeInterval,
        theme: FeatureTheme
    ) {
        guard outer > 0 else { return }
        let dotRadius = max(1.2, outer * 0.014)
        for index in 0..<OrbParticle.count {
            let particle = OrbParticle(index: index)
            let color = index.isMultiple(of: 2) ? theme.primary : theme.secondary
            let trail = particle.position(at: time - trailLag)
            let head = particle.position(at: time)
            // Right after a particle starts a new trip, its trail is still at the end of the old one.
            if trail.progress < head.progress {
                let dot = path(of: trail, center: center, inner: inner, outer: outer, radius: dotRadius * 0.7)
                context.fill(dot, with: .color(color.opacity(trail.opacity * 0.35)))
            }
            let dot = path(of: head, center: center, inner: inner, outer: outer, radius: dotRadius)
            context.fill(dot, with: .color(color.opacity(head.opacity * 0.9)))
        }
    }

    private static func path(
        of position: OrbParticle.Position,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        radius: CGFloat
    ) -> Path {
        let distance = inner + (outer - inner) * CGFloat(position.distance)
        let point = CGPoint(
            x: center.x + CGFloat(cos(position.angle)) * distance,
            y: center.y + CGFloat(sin(position.angle)) * distance
        )
        let size = radius * CGFloat(position.scale)
        return Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2))
    }
}
