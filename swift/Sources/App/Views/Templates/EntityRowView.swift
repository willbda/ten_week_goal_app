//
// EntityRowView.swift
// Reusable row component for entity lists
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Provides consistent layout for entity rows across Actions, Goals, Terms, and Values.
// Handles title, subtitle, caption, badges, and optional trailing content.
//
// DESIGN:
// - VStack layout: title → subtitle → badges → caption
// - Optional fields (subtitle, caption) hidden when nil
// - Badge row hidden when badges array is empty
// - Trailing content injected via ViewBuilder (chevron, button, etc.)
// - Truncates long titles gracefully
// - iOS design language consistency
//
// TODO: @Agent1 - Signature may need adjustment when ComponentContracts.swift is created

import SwiftUI

// MARK: - EntityRowView Component

/// Generic row layout for entity lists
///
/// **Features**:
/// - Required: title (String)
/// - Optional: subtitle, caption, badges, trailingContent
/// - Consistent spacing and typography
/// - Graceful handling of long text
/// - Badge row only shown when badges are present
///
/// **Usage**:
/// ```swift
/// EntityRowView(
///     title: "Morning Run",
///     subtitle: "Exercise",
///     caption: "Today at 7:00 AM",
///     badges: [
///         Badge(text: "5.2 km", color: .blue),
///         Badge(text: "Active", color: .green)
///     ]
/// ) {
///     Image(systemName: "chevron.right")
///         .foregroundStyle(.tertiary)
/// }
/// ```
public struct EntityRowView<Content: View>: View {

    // MARK: - Properties

    let title: String
    let subtitle: String?
    let caption: String?
    let badges: [Badge]
    let trailingContent: () -> Content

    // MARK: - Initialization

    /// Create an entity row with optional fields
    ///
    /// - Parameters:
    ///   - title: Primary text (required)
    ///   - subtitle: Secondary text (optional)
    ///   - caption: Tertiary text, often timestamp (optional)
    ///   - badges: Array of badges to display (default: empty)
    ///   - trailingContent: ViewBuilder for trailing content (default: EmptyView)
    public init(
        title: String,
        subtitle: String? = nil,
        caption: String? = nil,
        badges: [Badge] = [],
        @ViewBuilder trailingContent: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.caption = caption
        self.badges = badges
        self.trailingContent = trailingContent
    }

    // MARK: - Body

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Main content
            VStack(alignment: .leading, spacing: 6) {
                // Title (required)
                Text(title)
                    .font(.headline)
                    .lineLimit(2)

                // Subtitle (optional)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Badges (only shown if present)
                if !badges.isEmpty {
                    badgeRow
                }

                // Caption (optional)
                if let caption = caption {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Trailing content (optional)
            trailingContent()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    /// Badge row with horizontal layout
    private var badgeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(badges) { badge in
                    BadgeView(badge: badge)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Minimal - Title Only") {
    List {
        EntityRowView(title: "Simple Action")
        EntityRowView(title: "Another Action")
        EntityRowView(title: "Third Action")
    }
}

#Preview("With Subtitle") {
    List {
        EntityRowView(
            title: "Morning Run",
            subtitle: "Exercise · Cardio"
        )
        EntityRowView(
            title: "Project Planning",
            subtitle: "Work · Strategy"
        )
        EntityRowView(
            title: "Call Mom",
            subtitle: "Personal · Family"
        )
    }
}

#Preview("With Caption (Timestamp)") {
    List {
        EntityRowView(
            title: "Morning Run",
            subtitle: "Exercise",
            caption: "Today at 7:00 AM"
        )
        EntityRowView(
            title: "Project Meeting",
            subtitle: "Work",
            caption: "Yesterday at 2:30 PM"
        )
        EntityRowView(
            title: "Grocery Shopping",
            subtitle: "Errands",
            caption: "2 days ago"
        )
    }
}

#Preview("With Badges") {
    List {
        EntityRowView(
            title: "Morning Run",
            subtitle: "Exercise",
            badges: [
                Badge(text: "5.2 km", color: .blue),
                Badge(text: "Completed", color: .green)
            ]
        )
        EntityRowView(
            title: "Project Planning",
            subtitle: "Work",
            badges: [
                Badge(text: "2 hours", color: .purple),
                Badge(text: "High Priority", color: .red)
            ]
        )
    }
}

#Preview("Full - All Fields") {
    List {
        EntityRowView(
            title: "Morning Run",
            subtitle: "Exercise · Cardio",
            caption: "Today at 7:00 AM",
            badges: [
                Badge(text: "5.2 km", color: .blue),
                Badge(text: "45 min", color: .green),
                Badge(text: "Health", color: .purple)
            ]
        ) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }

        EntityRowView(
            title: "Project Planning Session",
            subtitle: "Work · Strategy",
            caption: "Yesterday at 2:30 PM",
            badges: [
                Badge(text: "2 hours", color: .orange),
                Badge(text: "Completed", color: .green)
            ]
        ) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }
    }
}

#Preview("Long Text Handling") {
    List {
        EntityRowView(
            title: "This is an extremely long title that should truncate gracefully after two lines of text to avoid cluttering the interface",
            subtitle: "This is also a very long subtitle that might need truncation",
            caption: "This is a long caption with timestamp information",
            badges: [
                Badge(text: "Badge One", color: .blue),
                Badge(text: "Badge Two", color: .green),
                Badge(text: "Badge Three", color: .purple),
                Badge(text: "Badge Four", color: .orange)
            ]
        )

        EntityRowView(
            title: "Short Title",
            subtitle: "But a subtitle that goes on and on with lots of information that needs to be truncated",
            badges: [
                Badge(text: "Very Long Badge Text", color: .red)
            ]
        )
    }
}

#Preview("With Trailing Content Variations") {
    List {
        EntityRowView(
            title: "Action with Chevron",
            subtitle: "Tappable"
        ) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.caption)
        }

        EntityRowView(
            title: "Action with Button",
            subtitle: "Interactive"
        ) {
            Button(action: {}) {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }

        EntityRowView(
            title: "Action with Status Icon",
            subtitle: "Completed"
        ) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }

        EntityRowView(
            title: "Action with Value",
            subtitle: "Metric"
        ) {
            Text("5.2")
                .font(.headline)
                .foregroundStyle(.blue)
        }
    }
}

#Preview("Zero Badges vs Multiple Badges") {
    List {
        Section("No Badges") {
            EntityRowView(
                title: "Action Without Badges",
                subtitle: "Should not show badge row"
            )
        }

        Section("One Badge") {
            EntityRowView(
                title: "Action With One Badge",
                subtitle: "Shows badge row",
                badges: [Badge(text: "Solo", color: .blue)]
            )
        }

        Section("Many Badges") {
            EntityRowView(
                title: "Action With Many Badges",
                subtitle: "Should scroll horizontally if needed",
                badges: [
                    Badge(text: "Badge 1", color: .blue),
                    Badge(text: "Badge 2", color: .green),
                    Badge(text: "Badge 3", color: .purple),
                    Badge(text: "Badge 4", color: .orange),
                    Badge(text: "Badge 5", color: .red)
                ]
            )
        }
    }
}

#Preview("Dark Mode") {
    List {
        EntityRowView(
            title: "Morning Run",
            subtitle: "Exercise · Cardio",
            caption: "Today at 7:00 AM",
            badges: [
                Badge(text: "5.2 km", color: .blue),
                Badge(text: "Completed", color: .green)
            ]
        ) {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }

        EntityRowView(
            title: "Project Planning",
            subtitle: "Work · Strategy",
            caption: "Yesterday at 2:30 PM",
            badges: [
                Badge(text: "2 hours", color: .purple),
                Badge(text: "Active", color: .orange)
            ]
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Realistic Data - Actions") {
    List {
        EntityRowView(
            title: "Morning Run",
            subtitle: "Exercise",
            caption: "Today at 7:00 AM",
            badges: [
                Badge(text: "5.2 km", color: .blue),
                Badge(text: "45 min", color: .green)
            ]
        )

        EntityRowView(
            title: "Write Documentation",
            subtitle: "Work",
            caption: "Today at 9:30 AM",
            badges: [
                Badge(text: "2 hours", color: .purple)
            ]
        )

        EntityRowView(
            title: "Team Meeting",
            subtitle: "Work",
            caption: "Yesterday at 2:00 PM",
            badges: [
                Badge(text: "1 hour", color: .orange)
            ]
        )
    }
}
