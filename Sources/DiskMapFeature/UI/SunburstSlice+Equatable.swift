import SwiftUI

/// Slices are equal when they stand for the same thing and look the same.
///
/// Every move of the highlight, and of the mouse from one slice to the next, evaluates the
/// rings again, and a slice holds closures, which SwiftUI can't compare, so it used to
/// evaluate every slice again: hundreds of them in a full map. With this it skips the ones
/// that didn't change, which a move of the highlight leaves as all but two branches. Their
/// actions are left out of the comparison: those of a slice always act on its own segment.
extension SunburstSlice: Equatable {
    nonisolated static func == (lhs: SunburstSlice, rhs: SunburstSlice) -> Bool {
        lhs.isDimmed == rhs.isDimmed
            && lhs.ringCount == rhs.ringCount
            && lhs.segment == rhs.segment
    }
}
