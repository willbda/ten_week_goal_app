// DesignSystem.swift
// Centralized design tokens and reusable components
//
// Written by Claude Code on 2025-10-23

import SwiftUI

// MARK: - Design Tokens

/// Central design system for consistent styling across the app
enum DesignSystem {

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48

        /// Form padding (comfortable breathing room)
        static let formPadding: CGFloat = 20

        /// Sheet padding (extra space for modals)
        static let sheetPadding: CGFloat = 24
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let round: CGFloat = .infinity
    }

    // MARK: - Typography

    enum Typography {
        static let sectionHeader = Font.headline
        static let sectionFooter = Font.caption
        static let formLabel = Font.body
        static let formValue = Font.body.monospacedDigit()
    }

    // MARK: - Colors

    /// Semantic color system (adapts to light/dark mode)
    enum Colors {
        static let actions = Color.red.opacity(0.8)
        static let goals = Color.orange.opacity(0.8)
        static let values = Color.blue.opacity(0.8)
        static let terms = Color.purple.opacity(0.8)

        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }

    // MARK: - Materials

    enum Materials {
        static let sidebar: Material = .ultraThinMaterial
        static let detail: Material = .regularMaterial
        static let modal: Material = .regularMaterial
    }
}

// MARK: - View Modifiers

/// Custom view modifiers for consistent styling

struct FormSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

struct StandardFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.roundedBorder)
            .padding(.vertical, DesignSystem.Spacing.xxs)
    }
}

struct SheetStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationBackground(DesignSystem.Materials.modal)
            .presentationCornerRadius(DesignSystem.CornerRadius.xl)
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 400)
            .padding(DesignSystem.Spacing.sheetPadding)
            #endif
    }
}

struct CardStyle: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(color.opacity(0.1))
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply form section styling
    func formSectionStyle() -> some View {
        modifier(FormSectionStyle())
    }

    /// Apply standard field styling
    func standardFieldStyle() -> some View {
        modifier(StandardFieldStyle())
    }

    /// Apply sheet styling with proper padding
    func sheetStyle() -> some View {
        modifier(SheetStyle())
    }

    /// Apply card styling with accent color
    func cardStyle(color: Color) -> some View {
        modifier(CardStyle(color: color))
    }
}

// MARK: - Reusable Components

/// Consistent section header across the app
struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(DesignSystem.Typography.sectionHeader)
        }
    }
}

/// Empty state view with consistent styling
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating.speed(0.5))

            VStack(spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(.title2)
                    .bold()

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }
}
