import MonitorFeature

struct FakeIdentityResolver: ProcessIdentityResolving {
    var identities: [Int32: ProcessIdentity] = [:]
    func identity(of pid: Int32) -> ProcessIdentity? { identities[pid] }
}
