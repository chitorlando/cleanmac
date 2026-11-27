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
/// It only moves while its window is shown, and draws at most 30 times a second. With Reduce
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
        Group {
            if motion.animatesDecorations {
                AnimationFrames(minimumInterval: 1 / Self.framesPerSecond) { date in
                    canvas(at: date.timeIntervalSinceReferenceDate)
                }
            } else if motion.drawsGlows {
                canvas(at: 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func canvas(at time: TimeInterval) -> some View {
        let theme = self.theme
        let reach = self.reach
        let policy = self.motion
        return Canvas { context, size in
            ScanningOrbRenderer.draw(in: &context, size: size, reach: reach, time: time, theme: theme, policy: policy)
        }
    }
}

/// Draws the orb of a scan at a given moment. It keeps no state: what it draws depends only on
/// the time.
enum ScanningOrbRenderer {
    /// How far the trail of a particle lags behind it, in seconds.
    private static let trailLag: TimeInterval = 0.07

    /// Draws the glow and the particles in `size`, around a ring that ends `reach` points
    /// inside its edges.
    static func draw(
        in context: inout GraphicsContext,
        size: CGSize,
        reach: CGFloat,
        time: TimeInterval,
        theme: FeatureTheme,
        policy: MotionPolicy
    ) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let outer = min(size.width, size.height) / 2
        let inner = max(outer - reach, 0)
        guard outer > 0 else { return }

        // From 0 to 1 and back once a breath. A still orb rests halfway.
        let breath = policy.animatesDecorations ? 0.5 + 0.5 * sin(2 * .pi * time / Motion.breathPeriod) : 0.5
        if policy.drawsGlows {
            drawGlow(in: &context, center: center, inner: inner, outer: outer, breath: breath, theme: theme)
        }
        if policy.animatesDecorations {
            drawParticles(in: &context, center: center, inner: inner, outer: outer, time: time, theme: theme)
        }
    }

    /// A halo that is brightest just around the ring and fades out toward the edge. The middle
    /// stays dark, so the figure inside the ring keeps its contrast.
    private static func drawGlow(
        in context: inout GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        breath: Double,
        theme: FeatureTheme
    ) {
        let radius = outer * CGFloat(0.9 + 0.1 * breath)
        let peak = min(inner / radius, 0.9)
        let gradient = Gradient(stops: [
            .init(color: theme.primary.opacity(0), location: peak * 0.6),
            .init(color: theme.primary.opacity(0.2 + 0.12 * breath), location: peak),
            .init(color: theme.secondary.opacity(0.07 + 0.06 * breath), location: peak + (1 - peak) * 0.45),
            .init(color: theme.secondary.opacity(0), location: 1)
        ])
        let disc = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(disc, with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: radius))
    }

    /// Each particle with a fainter, smaller trail just behind it, alternating the theme's colors.
    private static func drawParticles(
        in context: inout GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        time: TimeInterval,
        theme: FeatureTheme
    ) {
        let dotRadius = max(1.2, outer * 0.014)
        for index in 0..<OrbParticle.count {
            let particle = OrbParticle(index: index)
            let color = index.isMultiple(of: 2) ? theme.primary : theme.secondary
            let trail = particle.position(at: time - trailLag)
            let head = particle.position(at: time)
            // Right after a particle starts a new trip, its trail is still at the end of the old one.
            if trail.progress < head.progress {
                drawDot(trail, in: &context, center: center, inner: inner, outer: outer, radius: dotRadius * 0.7, color: color.opacity(trail.opacity * 0.35))
            }
            drawDot(head, in: &context, center: center, inner: inner, outer: outer, radius: dotRadius, color: color.opacity(head.opacity * 0.9))
        }
    }

    private static func drawDot(
        _ position: OrbParticle.Position,
        in context: inout GraphicsContext,
        center: CGPoint,
        inner: CGFloat,
        outer: CGFloat,
        radius: CGFloat,
        color: Color
    ) {
        let distance = inner + (outer - inner) * CGFloat(position.distance)
        let point = CGPoint(
            x: center.x + CGFloat(cos(position.angle)) * distance,
            y: center.y + CGFloat(sin(position.angle)) * distance
        )
        let size = radius * CGFloat(position.scale)
        let dot = Path(ellipseIn: CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2))
        context.fill(dot, with: .color(color))
    }
}
