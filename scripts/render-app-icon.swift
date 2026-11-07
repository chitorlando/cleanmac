#!/usr/bin/env swift
// Renders the 1024 px master of the app icon as a PNG.
//
// Usage: swift scripts/render-app-icon.swift <output.png>
//
// The icon follows the app's visual language: a dark canvas lit by teal
// and green glows, with an open ring (a "C") that echoes the progress
// ring and a sparkle where the ring opens. Colors match FeatureTheme.systemJunk.
import AppKit
import SwiftUI

enum IconColors {
    static let primary = Color(red: 0.30, green: 0.87, blue: 0.62)
    static let secondary = Color(red: 0.05, green: 0.52, blue: 0.70)
    static let canvasTop = Color(red: 0.13, green: 0.12, blue: 0.24)
    static let canvasBottom = Color(red: 0.05, green: 0.045, blue: 0.10)
    static let gradient = LinearGradient(
        colors: [primary, secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Four-pointed star with concave sides.
struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let pinch = radius * 0.16
        let tips = [
            CGPoint(x: center.x, y: center.y - radius),
            CGPoint(x: center.x + radius, y: center.y),
            CGPoint(x: center.x, y: center.y + radius),
            CGPoint(x: center.x - radius, y: center.y)
        ]
        let controls = [
            CGPoint(x: center.x + pinch, y: center.y - pinch),
            CGPoint(x: center.x + pinch, y: center.y + pinch),
            CGPoint(x: center.x - pinch, y: center.y + pinch),
            CGPoint(x: center.x - pinch, y: center.y - pinch)
        ]
        var path = Path()
        path.move(to: tips[0])
        for index in tips.indices {
            path.addQuadCurve(to: tips[(index + 1) % tips.count], control: controls[index])
        }
        path.closeSubpath()
        return path
    }
}

/// Rounded square body on the standard macOS icon grid: 824 pt inside a 1024 pt canvas.
struct IconBody: View {
    private let shape = RoundedRectangle(cornerRadius: 185, style: .continuous)

    var body: some View {
        ZStack {
            LinearGradient(colors: [IconColors.canvasTop, IconColors.canvasBottom], startPoint: .top, endPoint: .bottom)
            glow(IconColors.primary, at: .topTrailing, radius: 640, opacity: 0.55)
            glow(IconColors.secondary, at: .bottomLeading, radius: 700, opacity: 0.6)
            Mark()
        }
        .frame(width: 824, height: 824)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white.opacity(0.12), lineWidth: 2))
        .shadow(color: .black.opacity(0.35), radius: 14, y: 10)
    }

    private func glow(_ color: Color, at center: UnitPoint, radius: CGFloat, opacity: Double) -> some View {
        RadialGradient(colors: [color.opacity(opacity), .clear], center: center, startRadius: 10, endRadius: radius)
    }
}

/// Open ring with a sparkle at its upper end.
struct Mark: View {
    var body: some View {
        ZStack {
            ring.blur(radius: 36).opacity(0.85)
            ring
            sparkle(size: 220)
                .offset(x: 208, y: -212)
            sparkle(size: 84)
                .offset(x: 285, y: -50)
                .opacity(0.9)
        }
    }

    private var ring: some View {
        Circle()
            .trim(from: 0.14, to: 0.86)
            .stroke(IconColors.gradient, style: StrokeStyle(lineWidth: 92, lineCap: .round))
            .rotationEffect(.degrees(-30))
            .frame(width: 470, height: 470)
    }

    private func sparkle(size: CGFloat) -> some View {
        ZStack {
            Sparkle().fill(IconColors.primary).blur(radius: size * 0.18)
            Sparkle().fill(LinearGradient(colors: [.white, IconColors.primary], startPoint: .top, endPoint: .bottom))
        }
        .frame(width: size, height: size)
    }
}

struct AppIcon: View {
    var body: some View {
        IconBody()
            .frame(width: 1024, height: 1024)
    }
}

@MainActor
func renderIcon(to url: URL) throws {
    let renderer = ImageRenderer(content: AppIcon())
    renderer.scale = 1
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: url)
}

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: render-app-icon.swift <output.png>\n".utf8))
    exit(1)
}
try MainActor.assumeIsolated {
    try renderIcon(to: URL(filePath: arguments[1]))
}
