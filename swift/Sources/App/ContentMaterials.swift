// ContentMaterials.swift
// Standard materials for content layer
//
// Written by Claude Code on 2025-10-24
//
// Follows Apple's iOS 26/macOS 26 HIG:
// - Liquid Glass is ONLY for navigation/controls (see LiquidGlassSystem)
// - Content uses standard materials (.regularMaterial, .ultraThinMaterial, etc.)
// - Prioritizes readability and accessibility
//
// References:
// - https://developer.apple.com/design/human-interface-guidelines/materials
// - https://developer.apple.com/documentation/swiftui/material

import SwiftUI

/// Standard materials for content layer
///
/// **Apple HIG Compliance**:
/// Content layer should use standard materials for readability and accessibility.
/// This system provides semantic materials for cards, rows, forms, and modals.
///
/// **Usage Guidelines**:
/// - ✅ Content cards (goal cards, action cards)
/// - ✅ List rows (table view cells)
/// - ✅ Forms (input fields, text areas)
/// - ✅ Modals (sheets, popovers)
/// - ❌ Navigation elements (use LiquidGlassSystem instead)
@MainActor
public enum ContentMaterials {

    // MARK: - Material Types

    /// Material for content cards (goal cards, action cards, etc.)
    ///
    /// Uses `.regularMaterial` for balanced translucency and readability.
    ///
    /// **Usage**:
    /// ```swift
    /// VStack {
    ///     GoalDetails()
    /// }
    /// .contentCard()
    /// ```
    public static var card: Material { .regularMaterial }

    /// Material for list rows
    ///
    /// Uses `.ultraThinMaterial` for subtle separation in lists.
    ///
    /// **Usage**:
    /// ```swift
    /// List {
    ///     ForEach(goals) { goal in
    ///         GoalRowView(goal: goal)
    ///             .listRowMaterial()
    ///     }
    /// }
    /// ```
    public static var listRow: Material { .ultraThinMaterial }

    /// Material for forms
    ///
    /// Uses `.regularMaterial` for clear delineation of input areas.
    ///
    /// **Usage**:
    /// ```swift
    /// Form {
    ///     TextField("Name", text: $name)
    /// }
    /// .formMaterial()
    /// ```
    public static var form: Material { .regularMaterial }

    /// Material for modal sheets and popovers
    ///
    /// Uses `.regularMaterial` to distinguish modals from main content.
    ///
    /// **Usage**:
    /// ```swift
    /// .sheet(isPresented: $showingForm) {
    ///     GoalFormView()
    /// }
    /// .presentationBackground(ContentMaterials.modal)
    /// ```
    public static var modal: Material { .regularMaterial }

    // MARK: - Corner Radii

    /// Predefined corner radii for content elements
    public enum CornerRadius {
        /// Small radius for list rows
        public static let small: CGFloat = 8

        /// Medium radius for cards
        public static let medium: CGFloat = 12

        /// Large radius for modals
        public static let large: CGFloat = 16
    }

    // MARK: - Shadows

    /// Shadow configurations for content elements
    public enum Shadow {
        /// Light shadow for cards
        public static let card = ShadowConfig(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )

        /// Elevated shadow for modals
        public static let modal = ShadowConfig(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )

        public struct ShadowConfig: Sendable {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply content card material with shadow
    ///
    /// Creates a card-style container with `.regularMaterial` background,
    /// rounded corners, and subtle shadow.
    ///
    /// **Example**:
    /// ```swift
    /// VStack {
    ///     Text("Goal Title")
    ///     Text("Progress: 75%")
    /// }
    /// .contentCard()
    /// ```
    public func contentCard(
        cornerRadius: CGFloat = ContentMaterials.CornerRadius.medium
    ) -> some View {
        self.modifier(
            ContentCardModifier(cornerRadius: cornerRadius)
        )
    }

    /// Apply list row material
    ///
    /// Sets `.ultraThinMaterial` as the list row background.
    ///
    /// **Example**:
    /// ```swift
    /// List {
    ///     ForEach(goals) { goal in
    ///         GoalRowView(goal: goal)
    ///             .listRowMaterial()
    ///     }
    /// }
    /// ```
    public func listRowMaterial() -> some View {
        self.modifier(ListRowMaterialModifier())
    }

    /// Apply form material
    ///
    /// Sets `.regularMaterial` as the form background.
    ///
    /// **Example**:
    /// ```swift
    /// Form {
    ///     TextField("Name", text: $name)
    /// }
    /// .formMaterial()
    /// ```
    public func formMaterial() -> some View {
        self.modifier(FormMaterialModifier())
    }
}

// MARK: - ViewModifiers

/// Modifier that applies content card styling
@MainActor
private struct ContentCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ContentMaterials.card,
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .shadow(
                color: ContentMaterials.Shadow.card.color,
                radius: ContentMaterials.Shadow.card.radius,
                x: ContentMaterials.Shadow.card.x,
                y: ContentMaterials.Shadow.card.y
            )
    }
}

/// Modifier that applies list row material
@MainActor
private struct ListRowMaterialModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(
                RoundedRectangle(cornerRadius: ContentMaterials.CornerRadius.small)
                    .fill(ContentMaterials.listRow)
            )
    }
}

/// Modifier that applies form material
@MainActor
private struct FormMaterialModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ContentMaterials.form)
    }
}
