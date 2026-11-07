import LargeFilesFeature
import Testing

struct SizeBucketTests {
    @Test(arguments: [
        (Int64(50_000_000), SizeBucket.from50MBTo100MB),
        (99_999_999, .from50MBTo100MB),
        (100_000_000, .from100MBTo1GB),
        (999_999_999, .from100MBTo1GB),
        (1_000_000_000, .over1GB),
        (40_000_000_000, .over1GB)
    ])
    func groupsBySize(size: Int64, bucket: SizeBucket) {
        #expect(SizeBucket(size: size) == bucket)
    }

    @Test func hasNoBucketBelowFiftyMegabytes() {
        #expect(SizeBucket(size: 49_999_999) == nil)
    }
}
