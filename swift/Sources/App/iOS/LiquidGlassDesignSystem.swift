// LiquidGlassDesignSystem.swift
// Liquid Glass Design System for iOS 26+
//
// Written by Claude Code on 2025-10-24

import SwiftUI

// MARK: - Design System

/// Liquid Glass Design System
/// A comprehensive design language emphasizing depth, translucency, and fluid motion
@available(iOS 18.0, *)
public enum LiquidGlass {

    // MARK: - Elevation System

    /// Z-axis elevation levels for depth hierarchy
    public enum Elevation {
        case surface    // Z-0: Flush with background
        case raised     // Z-1: Slightly elevated (4pt)
        case floating   // Z-2: Clearly elevated (8pt)
        case overlay    // Z-3: Above content (16pt)
        case modal      // Z-4: Top layer (32pt)

        var offset: CGFloat {
            switch self {
            case .surface: return 0
            case .raised: return 4
            case .floating: return 8
            case .overlay: return 16
            case .modal: return 32
            }
        }

        var shadowRadius: CGFloat {
            offset * 1.5
        }

        var shadowOpacity: Double {
            switch self {
            case .surface: return 0.05
            case .raised: return 0.08
            case .floating: return 0.12
            case .overlay: return 0.16
            case .modal: return 0.24
            }
        }
    }

    // MARK: - Corner Radius

    /// Continuous corner radii for glass surfaces
    public enum CornerRadius {
        case small      // 12pt - Small cards, buttons
        case medium     // 20pt - Standard cards
        case large      // 28pt - Large cards, sheets
        case xlarge     // 36pt - Full-screen modals
        case pill       // Capsule - Pills, tab indicators

        var value: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 20
            case .large: return 28
            case .xlarge: return 36
            case .pill: return 1000 // Effectively infinite for capsule
            }
        }
    }

    // MARK: - Spacing

    /// Consistent spacing scale
    public enum Spacing {
        case xxs   // 4pt
        case xs    // 8pt
        case sm    // 12pt
        case md    // 16pt
        case lg    // 24pt
        case xl    // 32pt
        case xxl   // 48pt

        var value: CGFloat {
            switch self {
            case .xxs: return 4
            case .xs: return 8
            case .sm: return 12
            case .md: return 16
            case .lg: return 24
            case .xl: return 32
            case .xxl: return 48
            }
        }
    }

    // MARK: - Animation Curves

    /// Fluid animation curves
    public enum AnimationCurve {
        /// Standard spring - natural, slightly bouncy
        case standard
        /// Fluid spring - liquid-like with smooth overshoot
        case fluid
        /// Snap - quick and confident
        case snap
        /// Gentle - slow and smooth
        case gentle

        var animation: Animation {
            switch self {
            case .standard:
                return .spring(response: 0.5, dampingFraction: 0.75)
            case .fluid:
                return .interpolatingSpring(mass: 1, stiffness: 100, damping: 15)
            case .snap:
                return .spring(response: 0.3, dampingFraction: 0.9)
            case .gentle:
                return .spring(response: 0.7, dampingFraction: 0.8)
            }
        }
    }

    // MARK: - Section Colors

    /// Semantic colors for app sections
    public enum SectionColor {
        case actions
        case goals
        case values
        case terms
        case assistant

        var color: Color {
            switch self {
            case .actions: return .red
            case .goals: return .orange
            case .values: return .blue
            case .terms: return .purple
            case .assistant: return .indigo
            }
        }

        var tint: Color {
            color.opacity(0.08)
        }
    }
}

// MARK: - Liquid Glass Card

/// A translucent glass card with depth and elevation
@available(iOS 18.0, *)
public struct LiquidGlassCard<Content: View>: View {
    let elevation: LiquidGlass.Elevation
    let cornerRadius: LiquidGlass.CornerRadius
    let tintColor: Color?
    let content: Content

    public init(
        elevation: LiquidGlass.Elevation = .raised,
        cornerRadius: LiquidGlass.CornerRadius = .medium,
        tintColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.cornerRadius = cornerRadius
        self.tintColor = tintColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding(LiquidGlass.Spacing.md.value)
            .background {
                glassBackground
            }
            .shadow(
                color: .black.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                y: elevation.offset
            )
    }

    @ViewBuilder
    private var glassBackground: some View {
        ZStack {
            // Base glass material
            RoundedRectangle(
                cornerRadius: cornerRadius.value,
                style: .continuous
            )
            .fill(.ultraThinMaterial)

            // Tint overlay
            if let tint = tintColor {
                RoundedRectangle(
                    cornerRadius: cornerRadius.value,
                    style: .continuous
                )
                .fill(tint)
            }

            // Light edge border (simulates light from above)
            RoundedRectangle(
                cornerRadius: cornerRadius.value,
                style: .continuous
            )
            .strokeBorder(
                LinearGradient(
                    colors: [
                        .white.opacity(0.3),
                        .white.opacity(0.0),
                        .black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.5
            )
        }
    }
}

// MARK: - Liquid Glass Button

/// A pressable glass button with fluid animations
@available(iOS 18.0, *)
public struct LiquidGlassButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void

    @State private var isPressed = false

    public enum ButtonStyle {
        case primary
        case secondary
        case tertiary
        case destructive

        var material: Material {
            switch self {
            case .primary: return .thick
            case .secondary: return .regular
            case .tertiary: return .thin
            case .destructive: return .regular
            }
        }

        var tintColor: Color? {
            switch self {
            case .primary: return .accentColor.opacity(0.15)
            case .secondary: return nil
            case .tertiary: return nil
            case .destructive: return .red.opacity(0.15)
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .primary
            case .tertiary: return .secondary
            case .destructive: return .red
            }
        }
    }

    public init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button {
            // Haptic feedback
            #if os(iOS)
            let haptic = UIImpactFeedbackGenerator(style: .soft)
            haptic.impactOccurred()
            #endif

            action()
        } label: {
            HStack(spacing: LiquidGlass.Spacing.xs.value) {
                if let icon {
                    Image(systemName: icon)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, LiquidGlass.Spacing.md.value)
            .padding(.vertical, LiquidGlass.Spacing.sm.value)
            .background {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: LiquidGlass.CornerRadius.small.value,
                        style: .continuous
                    )
                    .fill(style.material)

                    if let tint = style.tintColor {
                        RoundedRectangle(
                            cornerRadius: LiquidGlass.CornerRadius.small.value,
                            style: .continuous
                        )
                        .fill(tint)
                    }

                    RoundedRectangle(
                        cornerRadius: LiquidGlass.CornerRadius.small.value,
                        style: .continuous
                    )
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Pressable Button Style

/// Custom button style with scale and blur effects on press
@available(iOS 18.0, *)
private struct PressableButtonStyle: SwiftUI.ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(
                LiquidGlass.AnimationCurve.snap.animation,
                value: configuration.isPressed
            )
    }
}

// MARK: - Adaptive Gradient Background

/// Adaptive gradient background that responds to color scheme
@available(iOS 18.0, *)
public struct AdaptiveGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        if colorScheme == .dark {
            darkGradient
        } else {
            lightGradient
        }
    }

    private var darkGradient: some View {
        LinearGradient(
            colors: [
                Color(white: 0.05),
                Color(white: 0.08),
                Color(white: 0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var lightGradient: some View {
        LinearGradient(
            colors: [
                Color(white: 0.95),
                Color(white: 0.98),
                Color(white: 0.92)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass Text Field

/// A glass-styled text field with focus states
@available(iOS 18.0, *)
public struct LiquidGlassTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    @FocusState private var isFocused: Bool

    public init(
        _ title: String,
        text: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default
    ) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: LiquidGlass.Spacing.xs.value) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .padding(LiquidGlass.Spacing.sm.value)
                .background {
                    RoundedRectangle(
                        cornerRadius: LiquidGlass.CornerRadius.small.value,
                        style: .continuous
                    )
                    .fill(isFocused ? .regularMaterial : .thinMaterial)
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: LiquidGlass.CornerRadius.small.value,
                            style: .continuous
                        )
                        .strokeBorder(
                            isFocused ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.2),
                            lineWidth: isFocused ? 1.5 : 0.5
                        )
                    }
                }
                .animation(LiquidGlass.AnimationCurve.snap.animation, value: isFocused)
        }
    }
}

// MARK: - Depth Scroll View

/// ScrollView with parallax depth effects
@available(iOS 18.0, *)
public struct DepthScrollView<Content: View>: View {
    let content: Content
    @State private var scrollOffset: CGFloat = 0

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
            .frame(height: 0)

            content
                .offset(y: scrollOffset * 0.2) // Parallax effect (20% slower)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
        }
    }
}

// MARK: - Scroll Offset Preference Key

@available(iOS 18.0, *)
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Modifiers

@available(iOS 18.0, *)
public extension View {
    /// Apply liquid glass card styling
    func liquidGlassCard(
        elevation: LiquidGlass.Elevation = .raised,
        cornerRadius: LiquidGlass.CornerRadius = .medium,
        tintColor: Color? = nil
    ) -> some View {
        modifier(LiquidGlassCardModifier(
            elevation: elevation,
            cornerRadius: cornerRadius,
            tintColor: tintColor
        ))
    }

    /// Apply liquid glass container background
    func liquidGlassContainer() -> some View {
        background {
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

@available(iOS 18.0, *)
private struct LiquidGlassCardModifier: ViewModifier {
    let elevation: LiquidGlass.Elevation
    let cornerRadius: LiquidGlass.CornerRadius
    let tintColor: Color?

    func body(content: Content) -> some View {
        content
            .padding(LiquidGlass.Spacing.md.value)
            .background {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: cornerRadius.value,
                        style: .continuous
                    )
                    .fill(.ultraThinMaterial)

                    if let tint = tintColor {
                        RoundedRectangle(
                            cornerRadius: cornerRadius.value,
                            style: .continuous
                        )
                        .fill(tint)
                    }

                    RoundedRectangle(
                        cornerRadius: cornerRadius.value,
                        style: .continuous
                    )
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .white.opacity(0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
                }
            }
            .shadow(
                color: .black.opacity(elevation.shadowOpacity),
                radius: elevation.shadowRadius,
                y: elevation.offset
            )
    }
}

// MARK: - Preview Helpers

@available(iOS 18.0, *)
#Preview("Liquid Glass Card") {
    ZStack {
        AdaptiveGradientBackground()

        VStack(spacing: 24) {
            LiquidGlassCard(
                elevation: .raised,
                tintColor: .blue.opacity(0.1)
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal Progress")
                        .font(.headline)

                    Text("Complete 50km running")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ProgressView(value: 0.52)
                        .tint(.blue)
                }
            }

            LiquidGlassCard(
                elevation: .floating,
                tintColor: .orange.opacity(0.1)
            ) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading) {
                        Text("Today's Actions")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("5 logged")
                            .font(.title2.bold())
                    }

                    Spacer()
                }
            }
        }
        .padding()
    }
}

@available(iOS 18.0, *)
#Preview("Buttons") {
    ZStack {
        AdaptiveGradientBackground()

        VStack(spacing: 16) {
            LiquidGlassButton(
                "Primary Action",
                icon: "checkmark.circle.fill",
                style: .primary
            ) {}

            LiquidGlassButton(
                "Secondary Action",
                icon: "pencil",
                style: .secondary
            ) {}

            LiquidGlassButton(
                "Delete",
                icon: "trash",
                style: .destructive
            ) {}
        }
        .padding()
    }
}

@available(iOS 18.0, *)
#Preview("Text Fields") {
    ZStack {
        AdaptiveGradientBackground()

        VStack(spacing: 24) {
            LiquidGlassTextField(
                "Goal Title",
                text: .constant(""),
                placeholder: "Enter goal description"
            )

            LiquidGlassTextField(
                "Target Amount",
                text: .constant(""),
                placeholder: "0",
                keyboardType: .decimalPad
            )
        }
        .padding()
    }
}
