import Darwin
@testable import DuplicatesFeature
import Testing

/// How the attributes of a volume are read, with and without the count of clones that
/// macOS 13 can't give. The flags are the ones each system returns for real files.
struct CloneAttributesTests {
    private let noExtendedAttributes = UInt64(EF_NO_XATTRS)
    private let mayShareBlocks = UInt64(EF_MAY_SHARE_BLOCKS)
    private let sharesAllBlocks = UInt64(EF_SHARES_ALL_BLOCKS)

    private func info(flags: UInt64, referenceCount: Int?) -> CloneInfo? {
        CloneAttributes(device: 3, cloneID: 42, flags: flags, referenceCount: referenceCount).cloneInfo
    }

    @Test func identifiesTheDataStreamByVolumeAndCloneID() {
        let stream = CloneInfo.StreamID(device: 3, cloneID: 42)

        #expect(info(flags: noExtendedAttributes, referenceCount: 1)?.streamID == stream)
        #expect(info(flags: mayShareBlocks, referenceCount: nil)?.streamID == stream)
    }

    // MARK: Counted clones

    @Test func aCountedFileWithItsOwnDataStandsAlone() {
        let info = info(flags: noExtendedAttributes, referenceCount: 1)

        #expect(info?.cloneCount == 1)
        #expect(info?.mayShareSomeData == false)
    }

    @Test func countedClonesShareAllOfTheirData() {
        let info = info(flags: mayShareBlocks | sharesAllBlocks, referenceCount: 3)

        #expect(info?.cloneCount == 3)
        #expect(info?.mayShareSomeData == false)
    }

    @Test func aCountedCloneThatWasModifiedMayShareSomeData() {
        let info = info(flags: mayShareBlocks, referenceCount: 1)

        #expect(info?.cloneCount == 1)
        #expect(info?.mayShareSomeData == true)
    }

    @Test func aVolumeThatCountsNoFileTellsNothing() {
        #expect(info(flags: noExtendedAttributes, referenceCount: 0) == nil)
    }

    // MARK: Clones that can't be counted

    @Test func withoutACountAFileThatSharesNoBlocksStandsAlone() {
        let info = info(flags: noExtendedAttributes, referenceCount: nil)

        #expect(info?.cloneCount == 1)
        #expect(info?.mayShareSomeData == false)
    }

    @Test func withoutACountAFileThatMayShareBlocksHasAnUnknownNumberOfClones() {
        // What macOS 13 returns for a clone, a modified clone and the last of its clones alike.
        let info = info(flags: mayShareBlocks | noExtendedAttributes, referenceCount: nil)

        #expect(info != nil)
        #expect(info?.cloneCount == nil)
        #expect(info?.mayShareSomeData == true)
    }
}
