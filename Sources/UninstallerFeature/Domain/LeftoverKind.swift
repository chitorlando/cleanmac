/// What a leftover file is used for, so it can be grouped in the interface.
public enum LeftoverKind: String, CaseIterable, Hashable, Sendable {
    case applicationSupport
    case caches
    case preferences
    case containers
    case groupContainers
    case savedState
    case logs
    case webData
    case launchAgents
    case scripts
}
