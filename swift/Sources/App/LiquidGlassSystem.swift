// LiquidGlassSystem.swift
// Liquid Glass design system for navigation and controls
//
// Written by Claude Code on 2025-10-24
//
// Follows Apple's iOS 26/macOS 26 Liquid Glass guidelines:
// - Use ONLY for navigation (tab bars, sidebars, toolbars)
// - Use ONLY for controls (buttons, pickers, segmented controls)
// - DO NOT use for content layer (cards, list rows, reading surfaces)
//
// References:
// - https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)
// - https://developer.apple.com/design/human-interface-guidelines/materials

import SwiftUI

/// Liquid Glass styling for navigation and controls
///
/// **Apple HIG Compliance**:
/// Liquid Glass creates depth through translucency in navigation elements.
/// This system provides type-safe access to iOS 26's native `.glassEffect()` API.
///
/// **Usage Guidelines**:
/// - ✅ Navigation (sidebars, tab bars, toolbars)
/// - ✅ Controls (buttons, pickers, segmented controls)
/// - ❌ Content layer (use ContentMaterials instead)
@MainActor
public enum LiquidGlassSystem {

    // MARK: - Materials (iOS 26 Compatibility Layer)

    /// Standard materials for glass effects
    ///
    /// **Note**: iOS 26's `.glassEffect()` API uses these materials internally.
    /// We expose them as semantic tokens for consistency.
    public enum GlassMaterial {
        /// Regular glass - Standard translucency for navigation
        case regular

        /// Clear glass - Lighter translucency for controls
        case clear

        /// Thick glass - Heavier translucency (rarely used)
        case thick

        var material: Material {
            switch self {
            case .regular: return .regularMaterial
            case .clear: return .thinMaterial
            case .thick: return .thickMaterial
            }
        }
    }

    // MARK: - Navigation Glass

    /// Material for sidebar navigation
    ///
    /// **Usage**:
    /// ```swift
    /// NavigationSplitView {
    ///     SidebarView()
    /// } detail: {
    ///     DetailView()
    /// }
    /// .navigationGlass()
    /// ```
    public static func navigationMaterial(
        variant: GlassMaterial = .regular
    ) -> Material {
        variant.material
    }

    /// Material for tab bars
    ///
    /// **Usage**:
    /// ```swift
    /// TabView { }
    ///     .tabViewStyle(.sidebarAdaptable)
    /// ```
    public static func tabBarMaterial(
        variant: GlassMaterial = .regular
    ) -> Material {
        variant.material
    }

    /// Material for toolbars
    ///
    /// **Usage**:
    /// ```swift
    /// .toolbar { }
    /// ```
    public static func toolbarMaterial(
        variant: GlassMaterial = .clear
    ) -> Material {
        variant.material
    }

    // MARK: - Control Materials

    /// Material for buttons (primary actions)
    ///
    /// **Usage**:
    /// ```swift
    /// Button("Save") { }
    ///     .buttonGlass(tint: DesignSystem.Colors.actions)
    /// ```
    public static func buttonMaterial(
        variant: GlassMaterial = .clear
    ) -> Material {
        variant.material
    }

    /// Material for pickers and segmented controls
    ///
    /// **Usage**:
    /// ```swift
    /// Picker("Type", selection: $goalType) { }
    /// ```
    public static func pickerMaterial(
        variant: GlassMaterial = .regular
    ) -> Material {
        variant.material
    }

    // MARK: - Shape Styles

    /// Predefined corner radius for glass shapes
    public enum CornerRadius {
        /// Small radius for buttons and controls
        public static let small: CGFloat = 8

        /// Medium radius for cards and containers
        public static let medium: CGFloat = 12

        /// Large radius for modals and sheets
        public static let large: CGFloat = 16
    }
}

// MARK: - View Extensions

extension View {
    /// Apply navigation glass background
    ///
    /// Uses ultra-thin material for navigation elements (sidebars, nav bars).
    ///
    /// **Example**:
    /// ```swift
    /// NavigationSplitView { }
    ///     .navigationGlass()
    /// ```
    public func navigationGlass(
        variant: LiquidGlassSystem.GlassMaterial = .regular
    ) -> some View {
        self.background(LiquidGlassSystem.navigationMaterial(variant: variant))
    }

    /// Apply button glass effect with tint
    ///
    /// **Example**:
    /// ```swift
    /// Button("Save") { }
    ///     .buttonGlass(tint: .blue)
    /// ```
    public func buttonGlass(
        tint: Color,
        variant: LiquidGlassSystem.GlassMaterial = .clear
    ) -> some View {
        self
            .background(
                LiquidGlassSystem.buttonMaterial(variant: variant),
                in: RoundedRectangle(cornerRadius: LiquidGlassSystem.CornerRadius.small)
            )
            .tint(tint)
    }
}
