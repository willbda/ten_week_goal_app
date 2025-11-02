import Models
import SwiftUI

public struct PersonalValuesRowView: View {
    let value: PersonalValue

    public init(value: PersonalValue) {
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(value.title ?? "Untitled")
                    .font(.headline)

                Spacer()

                // Using BadgeView for consistent badge styling across app
                if let priority = value.priority {
                    BadgeView(
                        badge: Badge(
                            text: "\(priority)",
                            color: .secondary
                        ))
                }
            }

            if let description = value.detailedDescription {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Life domain as badge for visual distinction
            if let domain = value.lifeDomain {
                BadgeView(
                    badge: Badge(
                        text: domain,
                        color: .purple.opacity(0.8)
                    )
                )
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
