@testable import DiskMapFeature
import Testing

@MainActor
struct SunburstSliceEqualityTests {
    private func segment(
        _ name: String = "notes.txt",
        ring: Int = 0,
        endDegrees: Double = 90,
        branch: Int = 0
    ) -> RingSegment {
        RingSegment(
            content: .item(DiskMapFixtures.file(name, 30)),
            ring: ring,
            startDegrees: 0,
            endDegrees: endDegrees,
            branch: branch
        )
    }

    private func slice(_ segment: RingSegment, ringCount: Int = 3, isDimmed: Bool = false) -> SunburstSlice {
        SunburstSlice(segment: segment, ringCount: ringCount, isDimmed: isDimmed, onHover: { _ in }, onOpen: {})
    }

    @Test func slicesThatLookTheSameAreEqualWhateverTheirActions() {
        let first = slice(segment())
        let second = slice(segment())

        #expect(first == second)
    }

    @Test func tellsSlicesApartByWhetherTheyAreDimmed() {
        let plain = slice(segment())
        let dimmed = slice(segment(), isDimmed: true)

        #expect(plain != dimmed)
    }

    @Test func tellsSlicesApartByTheirItem() {
        let notes = slice(segment("notes.txt"))
        let other = slice(segment("other.txt"))

        #expect(notes != other)
    }

    @Test func tellsSlicesApartByTheirPlaceInTheRings() {
        let plain = slice(segment())

        #expect(plain != slice(segment(ring: 1)))
        #expect(plain != slice(segment(endDegrees: 45)))
        #expect(plain != slice(segment(branch: 2)))
    }

    @Test func tellsSlicesApartByTheNumberOfRings() {
        let ofThree = slice(segment(), ringCount: 3)
        let ofFour = slice(segment(), ringCount: 4)

        #expect(ofThree != ofFour)
    }
}
