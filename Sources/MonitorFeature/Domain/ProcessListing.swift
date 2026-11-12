/// Lists the processes of the current user.
public protocol ProcessListing: Sendable {
    func processes() -> [ProcessSample]
}
