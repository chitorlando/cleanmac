import SwiftUI

/// How one task ended: an icon, its title and what happened.
struct MaintenanceResultRow: View {
    let result: MaintenanceTaskResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(result.task.title).font(.headline)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var symbolName: String {
        switch result.outcome {
        case .succeeded: "checkmark.circle.fill"
        case .failed(.authorizationCancelled), .failed(.cancelled): "minus.circle.fill"
        case .failed: "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch result.outcome {
        case .succeeded: .green
        case .failed(.authorizationCancelled), .failed(.cancelled): .secondary
        case .failed: .red
        }
    }

    private var detail: String {
        switch result.outcome {
        case .succeeded: result.task.completionNote
        case .failed(let error): error.explanation
        }
    }
}
