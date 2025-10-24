// ContentView_iOS.swift
// iOS 26 implementation with Liquid Glass design
//
// Written by Claude Code on 2025-10-24

#if os(iOS)
import SwiftUI

/// Main content view for iOS with Liquid Glass design
@available(iOS 18.0, *)
public struct ContentView_iOS: View {

    // MARK: - Section Definition

    public enum Section: String, CaseIterable, Identifiable {
        case actions, goals, values, terms, assistant

        public var id: String { rawValue }

        var title: String {
            switch self {
            case .assistant: return "Assistant"
            default: return rawValue.capitalized
            }
        }

        var subtitle: String {
            switch self {
            case .actions: return "Log your progress"
            case .goals: return "Set objectives"
            case .values: return "Define principles"
            case .terms: return "Plan periods"
            case .assistant: return "AI guidance"
            }
        }

        var icon: String {
            switch self {
            case .actions: return "text.rectangle"
            case .goals: return "pencil.and.scribble"
            case .values: return "heart"
            case .terms: return "calendar"
            case .assistant: return "wand.and.stars"
            }
        }

        var sectionColor: LiquidGlass.SectionColor {
            switch self {
            case .actions: return .actions
            case .goals: return .goals
            case .values: return .values
            case .terms: return .terms
            case .assistant: return .assistant
            }
        }

        var color: Color {
            sectionColor.color
        }

        var tint: Color {
            sectionColor.tint
        }
    }

    // MARK: - State

    @State private var selectedSection: Section = .actions
    @State private var showQuickAdd = false
    @Namespace private var tabIndicator

    // MARK: - Environment

    @Environment(AppViewModel.self) private var appViewModel

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some View {
        ZStack {
            // Layer 0: Adaptive background
            AdaptiveGradientBackground()

            // Layer 1: Main content with tab navigation
            VStack(spacing: 0) {
                // Content area
                ZStack {
                    if appViewModel.isInitializing {
                        initializingView
                    } else if let error = appViewModel.initializationError {
                        errorView(error: error)
                    } else {
                        contentForSelectedSection
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }

                // Fluid tab bar
                fluidTabBar
                    .padding(.top, 8)
            }

            // Layer 2: Floating quick add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingQuickAddButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 100) // Above tab bar
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Content Views

    @ViewBuilder
    private var contentForSelectedSection: some View {
        Group {
            switch selectedSection {
            case .actions:
                ActionsListView()
            case .goals:
                GoalsListView()
            case .values:
                ValuesListView()
            case .terms:
                TermsListView()
            case .assistant:
                if #available(iOS 26.0, *) {
                    AssistantChatView()
                } else {
                    comingSoonView
                }
            }
        }
        .id(selectedSection) // Force view recreation on section change
    }

    // MARK: - Fluid Tab Bar

    private var fluidTabBar: some View {
        HStack(spacing: 0) {
            ForEach(Section.allCases) { section in
                Button {
                    // Haptic feedback
                    let haptic = UIImpactFeedbackGenerator(style: .soft)
                    haptic.impactOccurred()

                    withAnimation(LiquidGlass.AnimationCurve.fluid.animation) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(.title3)
                            .symbolVariant(selectedSection == section ? .fill : .none)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(
                                selectedSection == section ? section.color : .secondary
                            )

                        Text(section.title)
                            .font(.caption2)
                            .fontWeight(selectedSection == section ? .medium : .regular)
                            .foregroundStyle(
                                selectedSection == section ? section.color : .secondary
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 4)
                    .background {
                        if selectedSection == section {
                            Capsule()
                                .fill(.regularMaterial)
                                .overlay {
                                    Capsule()
                                        .fill(section.tint)
                                }
                                .shadow(
                                    color: section.color.opacity(0.2),
                                    radius: 8,
                                    y: 2
                                )
                                .matchedGeometryEffect(
                                    id: "TAB_INDICATOR",
                                    in: tabIndicator
                                )
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(
                cornerRadius: LiquidGlass.CornerRadius.large.value,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
            .shadow(
                color: .black.opacity(0.12),
                radius: 20,
                y: -5
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: LiquidGlass.CornerRadius.large.value,
                    style: .continuous
                )
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Floating Quick Add Button

    private var floatingQuickAddButton: some View {
        Button {
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()

            withAnimation(LiquidGlass.AnimationCurve.fluid.animation) {
                showQuickAdd.toggle()
            }
        } label: {
            Image(systemName: showQuickAdd ? "xmark" : "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background {
                    Circle()
                        .fill(selectedSection.color.gradient)
                        .shadow(
                            color: selectedSection.color.opacity(0.4),
                            radius: 12,
                            y: 4
                        )
                }
                .rotationEffect(.degrees(showQuickAdd ? 45 : 0))
        }
        .buttonStyle(PressableScaleButtonStyle())
    }

    // MARK: - Status Views

    private var initializingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(selectedSection.color)

            VStack(spacing: 8) {
                Text("Initializing")
                    .font(.title2.bold())

                Text("Setting up your goal tracker...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassCard(
            elevation: .raised,
            tintColor: selectedSection.tint
        )
        .padding()
    }

    private func errorView(error: Error) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.red)
                .symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: 12) {
                Text("Database Error")
                    .font(.title2.bold())

                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                LiquidGlassButton(
                    "Retry",
                    icon: "arrow.clockwise",
                    style: .primary
                ) {
                    Task {
                        await appViewModel.initialize()
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassCard(
            elevation: .raised,
            tintColor: .red.opacity(0.1)
        )
        .padding()
    }

    private var comingSoonView: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.indigo.gradient)
                .symbolEffect(.pulse, options: .repeating)

            VStack(spacing: 8) {
                Text("Coming Soon")
                    .font(.title2.bold())

                Text("AI Assistant requires iOS 26+")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Available features will appear here when you update.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassCard(
            elevation: .raised,
            tintColor: .indigo.opacity(0.1)
        )
        .padding()
    }
}

// MARK: - Pressable Scale Button Style

@available(iOS 18.0, *)
private struct PressableScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                LiquidGlass.AnimationCurve.snap.animation,
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview

@available(iOS 18.0, *)
#Preview("iOS Content View") {
    ContentView_iOS()
        .environment(AppViewModel())
}

#endif
