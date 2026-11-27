import CleanMacCore
import CleanMacUI
import SwiftUI

/// The apps allowed each sensitive permission, or the way to Full Disk Access when the
/// privacy databases can't be read.
struct PermissionsCard: View {
    let review: PermissionsReview
    @Environment(\.permissionSettings) private var permissionSettings

    var body: some View {
        ReviewCard(
            title: Text("Sensitive Permissions", bundle: .module, comment: "Title of the part of the security review about the apps allowed permissions such as Full Disk Access."),
            summary: Text(
                "Apps you allowed to see or control more than usual. There’s nothing to fix unless you don’t recognize one.",
                bundle: .module,
                comment: "Subtitle of the Sensitive Permissions part of the security review."
            )
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if review.availability != .complete {
                    fullDiskAccessNote
                }
                if review.availability != .unavailable {
                    if review.groups.isEmpty {
                        HStack(spacing: 12) {
                            FindingIcon(level: .fine)
                            Text("No app has any of these permissions.", bundle: .module, comment: "Shown when no app is allowed any of the sensitive permissions the security review lists.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(review.groups) { group in
                        PermissionGroupRow(group: group)
                    }
                }
            }
        }
    }

    private var fullDiskAccessNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                noteText
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    permissionSettings.open(.fullDiskAccess)
                } label: {
                    Text("Open Privacy & Security", bundle: .module, comment: "Button that opens the Privacy & Security pane of System Settings.")
                }
                .buttonStyle(.link)
            }
        }
    }

    private var noteText: Text {
        review.availability == .unavailable
            ? Text("macOS only lets apps with Full Disk Access read which apps have these permissions. Give CleanMac Full Disk Access to see them, then review again.", bundle: .module, comment: "Shown instead of the sensitive permissions when CleanMac doesn't have Full Disk Access.")
            : Text("Some permissions couldn’t be read. Give CleanMac Full Disk Access to see them all, then review again.", bundle: .module, comment: "Shown above the sensitive permissions when only part of them could be read.")
    }
}

/// One permission with the apps allowed it.
struct PermissionGroupRow: View {
    let group: PermissionGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                group.permission.title
                    .font(.body.weight(.semibold))
                group.permission.explanation
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                if let url = group.permission.settingsURL {
                    OpenSettingsButton(url: url)
                        .buttonStyle(.link)
                        .font(.callout)
                }
            }
            ForEach(group.clients) { client in
                PermissionClientRow(client: client)
            }
        }
    }
}

/// An app allowed a permission, flagged only when its signature is missing or damaged.
struct PermissionClientRow: View {
    let client: PermissionClient

    var body: some View {
        HStack(spacing: 8) {
            if let url = client.url {
                AppIconView(url: url, size: 20)
            } else {
                Image(systemName: "app.dashed")
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
            Text(verbatim: client.name)
                .lineLimit(1)
            if client.isRisky, let signature = client.signature {
                StatusBadge(signature.title, color: FindingLevel.attention.color)
            }
            Spacer(minLength: 0)
        }
        .font(.callout)
        .padding(.leading, 8)
        .help(Text(verbatim: client.identifier))
        .contextMenu {
            if let url = client.url {
                ItemContextMenu(url: url, selection: .unavailable)
            }
        }
    }
}
