import Foundation

/// `OnboardingStoring` in the user defaults.
public final class UserDefaultsOnboardingStore: OnboardingStoring {
    private static let completedKey = "onboarding.completed"
    private static let hadFullDiskAccessKey = "onboarding.hadFullDiskAccess"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var isCompleted: Bool {
        get { defaults.bool(forKey: Self.completedKey) }
        set { defaults.set(newValue, forKey: Self.completedKey) }
    }

    public var hadFullDiskAccess: Bool {
        get { defaults.bool(forKey: Self.hadFullDiskAccessKey) }
        set { defaults.set(newValue, forKey: Self.hadFullDiskAccessKey) }
    }
}
