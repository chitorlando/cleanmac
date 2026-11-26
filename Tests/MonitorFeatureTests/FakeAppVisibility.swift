/// Whether the app can be seen, as the test says, counting the checks made while it can't.
@MainActor
final class FakeAppVisibility {
    var isHidden = false
    private(set) var checksWhileHidden = 0

    func isVisible() -> Bool {
        if isHidden {
            checksWhileHidden += 1
        }
        return !isHidden
    }
}
