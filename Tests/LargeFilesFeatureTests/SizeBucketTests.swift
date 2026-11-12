import LargeFilesFeature
import Testing

struct SizeBucketTests {
    @Test(arguments: [
        (Int64(50_000_000), SizeBucket.upTo100MB),
        (99_999_999, .upTo100MB),
        (100_000_000, .from100MBTo1GB),
        (999_999_999, .from100MBTo1GB),
        (1_000_000_000, .over1GB),
        (40_000_000_000, .over1GB)
    ])
    func groupsBySize(size: Int64, bucket: SizeBucket) {
        #expect(SizeBucket(size: size) == bucket)
    }

    @Test func startsTheFirstBucketAtTheMinimumSize() {
        #expect(SizeBucket.upTo100MB.lowerLimit(forMinimumSize: 50_000_000) == 50_000_000)
        #expect(SizeBucket.upTo100MB.lowerLimit(forMinimumSize: 20_000_000) == 20_000_000)
        #expect(SizeBucket.from100MBTo1GB.lowerLimit(forMinimumSize: 50_000_000) == 100_000_000)
    }

    @Test func offersEveryBucketForTheDefaultCriteria() {
        let minimumSize = LargeFileCriteria().minimumSize

        #expect(SizeBucket.buckets(forMinimumSize: minimumSize) == [.upTo100MB, .from100MBTo1GB, .over1GB])
    }

    @Test func dropsBucketsBelowALargerMinimum() {
        #expect(SizeBucket.buckets(forMinimumSize: 100_000_000) == [.from100MBTo1GB, .over1GB])
        #expect(SizeBucket.buckets(forMinimumSize: 2_000_000_000) == [.over1GB])
    }

    @Test func raisesTheLowerLimitToALargerMinimum() {
        #expect(SizeBucket.from100MBTo1GB.lowerLimit(forMinimumSize: 300_000_000) == 300_000_000)
        #expect(SizeBucket.over1GB.lowerLimit(forMinimumSize: 2_000_000_000) == 2_000_000_000)
    }

    @Test func hasNoLimitAboveTheLastBucket() {
        #expect(SizeBucket.upTo100MB.upperLimit == 100_000_000)
        #expect(SizeBucket.over1GB.upperLimit == nil)
    }
}
