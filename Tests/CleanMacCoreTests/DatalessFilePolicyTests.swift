import CleanMacCore
import Darwin
import Testing

struct DatalessFilePolicyTests {
    private struct Failure: Error {}

    private var threadPolicy: Int32 {
        getiopolicy_np(IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES, IOPOL_SCOPE_THREAD)
    }

    private func setThreadPolicy(_ policy: Int32) {
        setiopolicy_np(IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES, IOPOL_SCOPE_THREAD, policy)
    }

    @Test func turnsMaterializationOffWhileTheBodyRuns() {
        setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_ON)
        defer { setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT) }

        let policyInside = DatalessFilePolicy.withoutMaterializing { threadPolicy }

        #expect(policyInside == IOPOL_MATERIALIZE_DATALESS_FILES_OFF)
    }

    @Test func restoresThePreviousPolicy() {
        setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_ON)
        defer { setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT) }

        DatalessFilePolicy.withoutMaterializing {}

        #expect(threadPolicy == IOPOL_MATERIALIZE_DATALESS_FILES_ON)
    }

    @Test func restoresThePreviousPolicyWhenTheBodyThrows() {
        setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_ON)
        defer { setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT) }

        #expect(throws: Failure.self) {
            try DatalessFilePolicy.withoutMaterializing { throw Failure() }
        }
        #expect(threadPolicy == IOPOL_MATERIALIZE_DATALESS_FILES_ON)
    }

    @Test func walksWithoutMaterializingDatalessFiles() throws {
        let folder = try TemporaryFolder()
        try folder.makeFile("file.bin")
        setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_ON)
        defer { setThreadPolicy(IOPOL_MATERIALIZE_DATALESS_FILES_DEFAULT) }

        var policiesWhileWalking: [Int32] = []
        FileSystemWalker(excludedDirectories: []).walk(folder.root) { _ in
            policiesWhileWalking.append(threadPolicy)
            return true
        }

        #expect(policiesWhileWalking == [IOPOL_MATERIALIZE_DATALESS_FILES_OFF])
        #expect(threadPolicy == IOPOL_MATERIALIZE_DATALESS_FILES_ON)
    }
}
