import SwiftUI

/// A horizontal bar split into colored parts, each as wide as its share of the whole.
struct UsageBar: View {
    struct Part: Identifiable {
        let id: Int
        let fraction: Double
        let color: Color
    }

    let parts: [Part]

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                ForEach(parts) { part in
                    Rectangle()
                        .fill(part.color)
                        .frame(width: proxy.size.width * min(max(part.fraction, 0), 1))
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 8)
        .background(Color.white.opacity(0.1))
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}
