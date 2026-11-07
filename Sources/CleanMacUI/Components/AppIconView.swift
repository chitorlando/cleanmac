import AppKit
import SwiftUI

/// The Finder icon of an app or any other file.
public struct AppIconView: View {
    private let url: URL
    private let size: CGFloat

    public init(url: URL, size: CGFloat = 32) {
        self.url = url
        self.size = size
    }

    public var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path(percentEncoded: false)))
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
