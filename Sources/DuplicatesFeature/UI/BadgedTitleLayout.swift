import SwiftUI

/// Lays out a title followed by its badges, moving the badges below the title when there is no room beside it.
///
/// The first subview is the title, which can be shortened; the others are badges, which keep their size.
/// They share a line while that leaves the title `minimumTitleWidth`, or its whole width when it is
/// shorter. Otherwise the title gets the first line to itself and the badges follow below, on as
/// many lines as they need.
struct BadgedTitleLayout: Layout {
    /// Space between the title and a badge, and between two badges.
    var spacing: CGFloat = 6
    /// Space between two lines.
    var lineSpacing: CGFloat = 4
    /// Width the title keeps before the badges move below it.
    var minimumTitleWidth: CGFloat = 72

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrangement(of: subviews, in: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrangement(of: subviews, in: bounds.width).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    /// Whether the badges fit beside a title of `titleWidth` without shortening it too much.
    func sharesLine(titleWidth: CGFloat, badgeWidths: [CGFloat], in width: CGFloat) -> Bool {
        titleRoom(beside: badgeWidths, in: width) >= min(titleWidth, minimumTitleWidth)
    }

    /// The badges that go on each line when they flow within `width`, in their order.
    ///
    /// A badge wider than `width` still gets a line, so none is left out.
    func lines(ofBadgeWidths widths: [CGFloat], in width: CGFloat) -> [Range<Int>] {
        var lines: [Range<Int>] = []
        var lineStart = 0
        var lineWidth: CGFloat = 0
        for (index, badgeWidth) in widths.enumerated() {
            let extendedWidth = lineWidth + spacing + badgeWidth
            if index > lineStart && extendedWidth > width {
                lines.append(lineStart..<index)
                lineStart = index
                lineWidth = badgeWidth
            } else {
                lineWidth = index == lineStart ? badgeWidth : extendedWidth
            }
        }
        if lineStart < widths.count {
            lines.append(lineStart..<widths.count)
        }
        return lines
    }

    /// Width left for the title on a line that also holds every badge.
    private func titleRoom(beside badgeWidths: [CGFloat], in width: CGFloat) -> CGFloat {
        width - badgeWidths.reduce(0) { $0 + spacing + $1 }
    }

    /// The frame of every subview, relative to the layout's origin, and the size they take together.
    private func arrangement(of subviews: Subviews, in width: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        guard let title = subviews.first else { return (.zero, []) }
        let badgeSizes = subviews.dropFirst().map { $0.sizeThatFits(.unspecified) }
        let badgeWidths = badgeSizes.map(\.width)
        let wholeTitle = title.sizeThatFits(.unspecified)

        if sharesLine(titleWidth: wholeTitle.width, badgeWidths: badgeWidths, in: width) {
            let titleSize = fitted(title, whole: wholeTitle, in: titleRoom(beside: badgeWidths, in: width))
            return line([titleSize] + badgeSizes, top: 0)
        }

        let titleSize = fitted(title, whole: wholeTitle, in: width)
        var frames = [CGRect(origin: .zero, size: titleSize)]
        for badges in lines(ofBadgeWidths: badgeWidths, in: width) {
            let top = (frames.map(\.maxY).max() ?? 0) + lineSpacing
            frames += line(Array(badgeSizes[badges]), top: top).frames
        }
        return (size(enclosing: frames), frames)
    }

    /// The size of the title in `width`: whole when it fits, shortened otherwise.
    private func fitted(_ title: LayoutSubview, whole: CGSize, in width: CGFloat) -> CGSize {
        guard whole.width > width else { return whole }
        return title.sizeThatFits(ProposedViewSize(width: max(width, 0), height: nil))
    }

    /// Frames of views placed side by side from the leading edge, centered on the tallest.
    private func line(_ sizes: [CGSize], top: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        let height = sizes.map(\.height).max() ?? 0
        var leading: CGFloat = 0
        var frames: [CGRect] = []
        for size in sizes {
            frames.append(CGRect(origin: CGPoint(x: leading, y: top + (height - size.height) / 2), size: size))
            leading += size.width + spacing
        }
        return (size(enclosing: frames), frames)
    }

    private func size(enclosing frames: [CGRect]) -> CGSize {
        CGSize(width: frames.map(\.maxX).max() ?? 0, height: frames.map(\.maxY).max() ?? 0)
    }
}
