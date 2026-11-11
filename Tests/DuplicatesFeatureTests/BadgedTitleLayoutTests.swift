@testable import DuplicatesFeature
import SwiftUI
import Testing

@MainActor
struct BadgedTitleLayoutTests {
    private let layout = BadgedTitleLayout(spacing: 6, lineSpacing: 4, minimumTitleWidth: 72)

    // Two badges take 46 and 66 with the space before each, which leaves the title 72 out of 184.
    @Test func keepsTheBadgesBesideTheTitleWhileItKeepsItsMinimumWidth() {
        #expect(layout.sharesLine(titleWidth: 150, badgeWidths: [40, 60], in: 184))
    }

    @Test func movesTheBadgesBelowOnceTheTitleWouldLoseItsMinimumWidth() {
        #expect(!layout.sharesLine(titleWidth: 150, badgeWidths: [40, 60], in: 183))
    }

    @Test func aTitleShorterThanTheMinimumOnlyNeedsItsOwnWidth() {
        #expect(layout.sharesLine(titleWidth: 30, badgeWidths: [60], in: 96))
        #expect(!layout.sharesLine(titleWidth: 30, badgeWidths: [60], in: 95))
    }

    @Test func keepsEverythingOnOneLineWhenTheWidthHasNoLimit() {
        #expect(layout.sharesLine(titleWidth: 150, badgeWidths: [40, 60], in: .infinity))
    }

    @Test func putsTheBadgesOnOneLineWhenTheyFit() {
        #expect(layout.lines(ofBadgeWidths: [68, 38, 75], in: 193) == [0..<3])
    }

    @Test func startsANewLineAtTheBadgeThatDoesNotFit() {
        #expect(layout.lines(ofBadgeWidths: [68, 38, 75], in: 192) == [0..<2, 2..<3])
        #expect(layout.lines(ofBadgeWidths: [68, 38, 75], in: 100) == [0..<1, 1..<2, 2..<3])
    }

    @Test func givesALineToABadgeWiderThanTheWidth() {
        #expect(layout.lines(ofBadgeWidths: [120], in: 100) == [0..<1])
        #expect(layout.lines(ofBadgeWidths: [120, 30, 30], in: 100) == [0..<1, 1..<3])
    }

    @Test func needsNoLineWithoutBadges() {
        #expect(layout.lines(ofBadgeWidths: [], in: 100).isEmpty)
    }
}
