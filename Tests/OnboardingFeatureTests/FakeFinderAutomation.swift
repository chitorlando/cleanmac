import CleanMacCore

/// Starts with a status and answers a request with another, never asking anyone.
final class FakeFinderAutomation: FinderAutomationAuthorizing, @unchecked Sendable {
    var current: PermissionStatus
    let answer: PermissionStatus
    private(set) var requests = 0

    init(current: PermissionStatus = .notDetermined, answer: PermissionStatus = .granted) {
        self.current = current
        self.answer = answer
    }

    func status() -> PermissionStatus { current }

    func requestAccess() async -> PermissionStatus {
        requests += 1
        current = answer
        return answer
    }
}
