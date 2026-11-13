/// When the permissions onboarding opens by itself at launch.
public enum OnboardingPolicy {
    /// On the first launch, and again when Full Disk Access was on before and is off now,
    /// as happens when an update changes the app's signature and macOS forgets the grant.
    public static func showsAtLaunch(isCompleted: Bool, hadFullDiskAccess: Bool, hasFullDiskAccess: Bool) -> Bool {
        !isCompleted || (hadFullDiskAccess && !hasFullDiskAccess)
    }
}
