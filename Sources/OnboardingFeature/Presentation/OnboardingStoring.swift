/// Remembers what the permissions onboarding needs across launches.
public protocol OnboardingStoring: AnyObject {
    /// The user went through the onboarding once, by continuing or skipping it.
    var isCompleted: Bool { get set }
    /// Full Disk Access was on at some point, so losing it later is worth telling.
    var hadFullDiskAccess: Bool { get set }
}
