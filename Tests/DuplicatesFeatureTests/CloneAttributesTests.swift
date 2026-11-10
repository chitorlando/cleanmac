import Darwin
@testable import DuplicatesFeature
import Testing

/// How the attributes of a volume are read, with and without the count of clones that
/// macOS 13 can't give. The flags are the ones each system returns for real files.
struct CloneAttributesTests {
    private let noExtendedAttributes = UInt64(EF_NO_XATTRS)
    private let mayShareBlocks = UInt64(EF_MAY_SHARE_BLOCKS)
    private let sharesAllBlocks = UInt64(EF_SHARES_ALL_BLOCKS)

    private func info(
        flags: UInt64,
        referenceCount: Int?,
        allocatedSize: Int64? = nil,
        privateSize: Int64? = nil
    ) -> CloneInfo? {
        CloneAttributes(
            device: 3,
            cloneID: 42,
            flags: flags,
            referenceCount: referenceCount,
            allocatedSize: allocatedSize,
            privateSize: privateSize
        ).cloneInfo
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

    // MARK: Space that is the file's own

    @Test func withoutACountAFormerCloneThatKeepsAllItsSpaceStandsAlone() {
        // The flag outlives the clones: once they are gone, all of the file's space is its own.
        let info = info(
            flags: mayShareBlocks | noExtendedAttributes,
            referenceCount: nil,
            allocatedSize: 303_104,
            privateSize: 303_104
        )

        #expect(info?.cloneCount == 1)
        #expect(info?.mayShareSomeData == false)
    }

    @Test func withoutACountAFileThatSharesItsSpaceHasAnUnknownNumberOfClones() {
        let clone = info(flags: mayShareBlocks, referenceCount: nil, allocatedSize: 303_104, privateSize: 0)
        let partlyRewritten = info(flags: mayShareBlocks, referenceCount: nil, allocatedSize: 303_104, privateSize: 4_096)

        for shared in [clone, partlyRewritten] {
            #expect(shared != nil)
            #expect(shared?.cloneCount == nil)
            #expect(shared?.mayShareSomeData == true)
        }
    }

    @Test func withoutACountAFileThatTakesUpNoSpaceProvesNothing() {
        let info = info(flags: mayShareBlocks, referenceCount: nil, allocatedSize: 0, privateSize: 0)

        #expect(info != nil)
        #expect(info?.cloneCount == nil)
        #expect(info?.mayShareSomeData == true)
    }

    @Test func withoutACountAMissingSizeProvesNothing() {
        let info = info(flags: mayShareBlocks, referenceCount: nil, allocatedSize: 303_104, privateSize: nil)

        #expect(info != nil)
        #expect(info?.cloneCount == nil)
        #expect(info?.mayShareSomeData == true)
    }

    @Test func theSizesNeverChangeWhatACountSays() {
        // A modified clone that counts one file keeps saying it may share part of its data.
        let modified = info(flags: mayShareBlocks, referenceCount: 1, allocatedSize: 303_104, privateSize: 303_104)
        let clones = info(flags: mayShareBlocks | sharesAllBlocks, referenceCount: 3, allocatedSize: 303_104, privateSize: 0)

        #expect(modified?.cloneCount == 1)
        #expect(modified?.mayShareSomeData == true)
        #expect(clones?.cloneCount == 3)
        #expect(clones?.mayShareSomeData == false)
    }
}
