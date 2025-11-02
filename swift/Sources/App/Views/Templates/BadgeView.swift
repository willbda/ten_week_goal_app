//
// BadgeView.swift
// Reusable badge/chip component for entity metadata
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Provides compact, colored badges for displaying entity metadata
// (status, categories, tags, metrics, etc.) across all views.
//
// DESIGN:
// - Capsule-shaped badge with colored background (20% opacity)
// - Text color matches badge color for consistency
// - Compact size (caption2 font) to avoid visual clutter
// - Works in both light and dark mode
//
// TODO: @Agent1 - Badge struct may move to ComponentContracts.swift when created

import SwiftUI

// MARK: - Badge Model

/// A badge with text and color for display
///
/// Used to show metadata like status, categories, or tags on entity rows.
///
/// **Usage**:
/// ```swift
/// let statusBadge = Badge(text: "Active", color: .green)
/// let metricBadge = Badge(text: "5.2 km", color: .blue)
/// ```
public struct Badge: Identifiable {
    public let id: UUID
    public let text: String
    public let color: Color

    public init(text: String, color: Color) {
        self.id = UUID()
        self.text = text
        self.color = color
    }
}

// MARK: - BadgeView Component

/// Renders a badge as a colored capsule with text
///
/// **Features**:
/// - Capsule shape with rounded ends
/// - Background: badge color at 20% opacity
/// - Text: badge color at 100% opacity
/// - Compact padding for minimal footprint
///
/// **Usage**:
/// ```swift
/// BadgeView(badge: Badge(text: "Completed", color: .green))
/// ```
public struct BadgeView: View {
    let badge: Badge

    public init(badge: Badge) {
        self.badge = badge
    }

    public var body: some View {
        Text(badge.text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badge.color.opacity(0.2))
            .foregroundStyle(badge.color)
            .clipShape(Capsule())
    }
}

// MARK: - Previews

#Preview("Single Badge") {
    VStack(spacing: 12) {
        BadgeView(badge: Badge(text: "Active", color: .green))
        BadgeView(badge: Badge(text: "Planned", color: .blue))
        BadgeView(badge: Badge(text: "Delayed", color: .orange))
        BadgeView(badge: Badge(text: "Completed", color: .gray))
    }
    .padding()
}

#Preview("Multiple Badges in Row") {
    HStack(spacing: 8) {
        BadgeView(badge: Badge(text: "5.2 km", color: .blue))
        BadgeView(badge: Badge(text: "Running", color: .green))
        BadgeView(badge: Badge(text: "Exercise", color: .purple))
    }
    .padding()
}

#Preview("Long Text Handling") {
    VStack(spacing: 12) {
        BadgeView(badge: Badge(text: "Very Long Badge Text That Wraps", color: .red))
        BadgeView(badge: Badge(text: "This is an extremely long badge with lots of text", color: .orange))

        // Multiple long badges in a row (should wrap naturally)
        HStack(spacing: 8) {
            BadgeView(badge: Badge(text: "Long Text One", color: .blue))
            BadgeView(badge: Badge(text: "Long Text Two", color: .purple))
            BadgeView(badge: Badge(text: "Long Text Three", color: .green))
        }
    }
    .padding()
}

#Preview("Color Variations") {
    VStack(spacing: 12) {
        BadgeView(badge: Badge(text: "Red", color: .red))
        BadgeView(badge: Badge(text: "Orange", color: .orange))
        BadgeView(badge: Badge(text: "Yellow", color: .yellow))
        BadgeView(badge: Badge(text: "Green", color: .green))
        BadgeView(badge: Badge(text: "Blue", color: .blue))
        BadgeView(badge: Badge(text: "Purple", color: .purple))
        BadgeView(badge: Badge(text: "Pink", color: .pink))
        BadgeView(badge: Badge(text: "Gray", color: .gray))
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 12) {
        HStack(spacing: 8) {
            BadgeView(badge: Badge(text: "Active", color: .green))
            BadgeView(badge: Badge(text: "5.2 km", color: .blue))
            BadgeView(badge: Badge(text: "Running", color: .purple))
        }

        HStack(spacing: 8) {
            BadgeView(badge: Badge(text: "Delayed", color: .orange))
            BadgeView(badge: Badge(text: "Completed", color: .gray))
            BadgeView(badge: Badge(text: "Planned", color: .cyan))
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}

#Preview("Empty Text Edge Case") {
    VStack(spacing: 12) {
        BadgeView(badge: Badge(text: "", color: .gray))
        BadgeView(badge: Badge(text: " ", color: .blue))
        BadgeView(badge: Badge(text: "A", color: .green))
    }
    .padding()
}
