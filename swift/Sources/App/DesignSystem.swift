// DesignSystem.swift
// Centralized design tokens and reusable components
//
// Written by Claude Code on 2025-10-23
// Updated 2025-10-23: Added zoom support for accessibility

import SwiftUI

// MARK: - Zoom Manager

/// Observable zoom manager for app-wide zoom state
///
/// Thread-safe singleton that manages zoom level across the app.
/// The zoomLevel property is accessed synchronously but updates trigger
/// SwiftUI view invalidation through @Observable.
@Observable
final class ZoomManager: @unchecked Sendable {
    static let shared = ZoomManager()

    private(set) var zoomLevel: CGFloat = 1.0

    private init() {}

    /// Increase zoom by 10%
    @MainActor
    func zoomIn() {
        zoomLevel = min(2.0, zoomLevel + 0.1)
    }

    /// Decrease zoom by 10%
    @MainActor
    func zoomOut() {
        zoomLevel = max(0.5, zoomLevel - 0.1)
    }

    /// Reset to 100%
    @MainActor
    func resetZoom() {
        zoomLevel = 1.0
    }
}

// MARK: - Design Tokens

/// Central design system for consistent styling across the app
enum DesignSystem {

    // MARK: - Spacing

    enum Spacing {
        // Base values (at 100% zoom)
        private static let baseXXS: CGFloat = 4
        private static let baseXS: CGFloat = 8
        private static let baseSM: CGFloat = 12
        private static let baseMD: CGFloat = 16
        private static let baseLG: CGFloat = 24
        private static let baseXL: CGFloat = 32
        private static let baseXXL: CGFloat = 48
        private static let baseFormPadding: CGFloat = 20
        private static let baseSheetPadding: CGFloat = 24

        // Computed properties that scale with zoom
        private static var zoom: CGFloat {
            ZoomManager.shared.zoomLevel
        }

        static var xxs: CGFloat { baseXXS * zoom }
        static var xs: CGFloat { baseXS * zoom }
        static var sm: CGFloat { baseSM * zoom }
        static var md: CGFloat { baseMD * zoom }
        static var lg: CGFloat { baseLG * zoom }
        static var xl: CGFloat { baseXL * zoom }
        static var xxl: CGFloat { baseXXL * zoom }

        /// Form padding (comfortable breathing room)
        static var formPadding: CGFloat { baseFormPadding * zoom }

        /// Sheet padding (extra space for modals)
        static var sheetPadding: CGFloat { baseSheetPadding * zoom }
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        // Base values (at 100% zoom)
        private static let baseXS: CGFloat = 4
        private static let baseSM: CGFloat = 8
        private static let baseMD: CGFloat = 12
        private static let baseLG: CGFloat = 16
        private static let baseXL: CGFloat = 20

        // Computed properties that scale with zoom
        private static var zoom: CGFloat {
            ZoomManager.shared.zoomLevel
        }

        static var xs: CGFloat { baseXS * zoom }
        static var sm: CGFloat { baseSM * zoom }
        static var md: CGFloat { baseMD * zoom }
        static var lg: CGFloat { baseLG * zoom }
        static var xl: CGFloat { baseXL * zoom }
        static let round: CGFloat = .infinity // Never scales
    }

    // MARK: - Typography

    enum Typography {
        // Base font sizes (at 100% zoom)
        private static let baseTitle: CGFloat = 28
        private static let baseTitle2: CGFloat = 22
        private static let baseTitle3: CGFloat = 20
        private static let baseHeadline: CGFloat = 17
        private static let baseBody: CGFloat = 17
        private static let baseCallout: CGFloat = 16
        private static let baseSubheadline: CGFloat = 15
        private static let baseFootnote: CGFloat = 13
        private static let baseCaption: CGFloat = 12
        private static let baseCaption2: CGFloat = 11

        // Computed properties that scale with zoom
        private static var zoom: CGFloat {
            ZoomManager.shared.zoomLevel
        }

        static var title: Font { .system(size: baseTitle * zoom) }
        static var title2: Font { .system(size: baseTitle2 * zoom) }
        static var title3: Font { .system(size: baseTitle3 * zoom) }
        static var headline: Font { .system(size: baseHeadline * zoom, weight: .semibold) }
        static var body: Font { .system(size: baseBody * zoom) }
        static var callout: Font { .system(size: baseCallout * zoom) }
        static var subheadline: Font { .system(size: baseSubheadline * zoom) }
        static var footnote: Font { .system(size: baseFootnote * zoom) }
        static var caption: Font { .system(size: baseCaption * zoom) }
        static var caption2: Font { .system(size: baseCaption2 * zoom, weight: .medium) }

        // Semantic aliases for backwards compatibility
        static var sectionHeader: Font { headline }
        static var sectionFooter: Font { caption }
        static var formLabel: Font { body }
        static var formValue: Font { .system(size: baseBody * zoom).monospacedDigit() }
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
