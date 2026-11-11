import CleanMacUI
import SwiftUI

/// A glass card with an icon and a title on top, like every section of the monitor.
struct MonitorCard<Accessory: View, Content: View>: View {
    let title: Text
    let symbolName: String
    let theme: FeatureTheme
    @ViewBuilder let accessory: Accessory
    @ViewBuilder let content: Content

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: symbolName)
                        .foregroundStyle(theme.gradient)
                        .accessibilityHidden(true)
                    title
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 4)
                    accessory
                }
                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

extension MonitorCard where Accessory == EmptyView {
    init(title: Text, symbolName: String, theme: FeatureTheme, @ViewBuilder content: () -> Content) {
        self.init(title: title, symbolName: symbolName, theme: theme, accessory: { EmptyView() }, content: content)
    }
}
