import Foundation

/// Removes items with a primary strategy and retries with a fallback only when
/// the primary one was denied permission.
public struct FallbackItemRemover: ItemRemoving {
    private let primary: any ItemRemoving
    private let fallback: any ItemRemoving

    public init(primary: any ItemRemoving, fallback: any ItemRemoving) {
        self.primary = primary
        self.fallback = fallback
    }

    public func remove(_ url: URL) async throws {
        do {
            try await primary.remove(url)
        } catch where error.isPermissionDenied {
            try await fallback.remove(url)
        }
    }
}
