import CleanMacUI
import Testing

struct MotionPolicyTests {
    private let full = MotionPolicy(reducesMotion: false, reducesTransparency: false)
    private let reducedMotion = MotionPolicy(reducesMotion: true, reducesTransparency: false)
    private let reducedTransparency = MotionPolicy(reducesMotion: false, reducesTransparency: true)

    @Test func eachRowWaitsALittleLongerThanTheOneBefore() {
        #expect(full.entranceDelay(forRowAt: 0) == 0)
        #expect(full.entranceDelay(forRowAt: 1) == Motion.staggerStep)
        #expect(full.entranceDelay(forRowAt: 3) > full.entranceDelay(forRowAt: 2))
    }

    @Test func rowsPastTheLastStaggeredOneEnterWithIt() {
        let last = full.entranceDelay(forRowAt: Motion.maxStaggeredRows)

        #expect(last == Double(Motion.maxStaggeredRows) * Motion.staggerStep)
        #expect(full.entranceDelay(forRowAt: Motion.maxStaggeredRows + 1) == last)
        #expect(full.entranceDelay(forRowAt: 5_000) == last)
    }

    @Test func aLongListIsFullyInWellUnderASecond() {
        #expect(full.entranceDelay(forRowAt: 5_000) + Motion.entranceDuration < 1)
    }

    @Test func aNegativeIndexDoesNotWait() {
        #expect(full.entranceDelay(forRowAt: -3) == 0)
    }

    @Test func withReduceMotionRowsFadeInTogetherWithoutRising() {
        #expect(reducedMotion.entranceDelay(forRowAt: 4) == 0)
        #expect(reducedMotion.entranceRise == 0)
        #expect(full.entranceRise == Motion.entranceRise)
    }

    @Test func reduceMotionStopsDecorationsAndTravelButKeepsGlows() {
        #expect(!reducedMotion.animatesDecorations)
        #expect(!reducedMotion.allowsTravel)
        #expect(reducedMotion.drawsGlows)
    }

    @Test func reduceTransparencyDropsGlowsButKeepsMotion() {
        #expect(!reducedTransparency.drawsGlows)
        #expect(reducedTransparency.animatesDecorations)
        #expect(reducedTransparency.allowsTravel)
    }

    @Test func withoutReductionsEverythingIsAllowed() {
        #expect(full.animatesDecorations)
        #expect(full.allowsTravel)
        #expect(full.drawsGlows)
    }
}
