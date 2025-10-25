// LiquidGlassFormView.swift
// Form components with Liquid Glass styling
//
// Written by Claude Code on 2025-10-24

#if os(iOS)
import SwiftUI

// MARK: - Action Form with Liquid Glass

/// Action creation/edit form with Liquid Glass design
@available(iOS 18.0, *)
public struct LiquidActionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppViewModel.self) private var appViewModel

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var measurements: String = ""
    @State private var duration: String = ""
    @State private var showValidationError = false
    @State private var isSaving = false

    let existingAction: Action?

    public init(action: Action? = nil) {
        self.existingAction = action
        if let action {
            _title = State(initialValue: action.title ?? "")
            _description = State(initialValue: action.detailedDescription ?? "")
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveGradientBackground()

                ScrollView {
                    VStack(spacing: LiquidGlass.Spacing.lg.value) {
                        // Header card
                        headerCard

                        // Main form
                        formContent

                        // Actions
                        actionButtons
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(existingAction == nil ? "New Action" : "Edit Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        LiquidGlassCard(
            elevation: .raised,
            tintColor: LiquidGlass.SectionColor.actions.tint
        ) {
            HStack(spacing: 16) {
                Image(systemName: "text.rectangle.page")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LiquidGlass.SectionColor.actions.color.gradient
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Log Your Progress")
                        .font(.headline)

                    Text("Record what you accomplished today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        LiquidGlassCard(elevation: .raised) {
            VStack(spacing: LiquidGlass.Spacing.md.value) {
                // Title field
                LiquidGlassTextField(
                    "Action Title",
                    text: $title,
                    placeholder: "E.g., Ran 5 kilometers"
                )

                Divider()
                    .background(.white.opacity(0.1))

                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                        .padding(LiquidGlass.Spacing.xs.value)
                        .background {
                            RoundedRectangle(
                                cornerRadius: LiquidGlass.CornerRadius.small.value,
                                style: .continuous
                            )
                            .fill(.thinMaterial)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: LiquidGlass.CornerRadius.small.value,
                                    style: .continuous
                                )
                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                            }
                        }
                }

                Divider()
                    .background(.white.opacity(0.1))

                // Measurements field
                LiquidGlassTextField(
                    "Measurements (Optional)",
                    text: $measurements,
                    placeholder: "E.g., {\"distance_km\": 5.0}",
                    keyboardType: .numbersAndPunctuation
                )

                Divider()
                    .background(.white.opacity(0.1))

                // Duration field
                LiquidGlassTextField(
                    "Duration (Optional)",
                    text: $duration,
                    placeholder: "Minutes",
                    keyboardType: .decimalPad
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: LiquidGlass.Spacing.md.value) {
            if isSaving {
                ProgressView()
                    .tint(LiquidGlass.SectionColor.actions.color)
            } else {
                LiquidGlassButton(
                    existingAction == nil ? "Create Action" : "Save Changes",
                    icon: "checkmark.circle.fill",
                    style: .primary
                ) {
                    saveAction()
                }

                if existingAction != nil {
                    LiquidGlassButton(
                        "Delete Action",
                        icon: "trash",
                        style: .destructive
                    ) {
                        deleteAction()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveAction() {
        guard !title.isEmpty else {
            showValidationError = true
            let haptic = UINotificationFeedbackGenerator()
            haptic.notificationOccurred(.error)
            return
        }

        isSaving = true

        Task {
            // TODO: Implement save logic via AppViewModel
            // For now, simulate save delay
            try? await Task.sleep(for: .seconds(0.5))

            await MainActor.run {
                let haptic = UINotificationFeedbackGenerator()
                haptic.notificationOccurred(.success)
                dismiss()
            }
        }
    }

    private func deleteAction() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        // TODO: Implement delete logic
        dismiss()
    }
}

// MARK: - Goal Form with Liquid Glass

/// Goal creation/edit form with Liquid Glass design
@available(iOS 18.0, *)
public struct LiquidGoalFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var targetAmount: String = ""
    @State private var unit: String = ""
    @State private var startDate = Date()
    @State private var targetDate = Date().addingTimeInterval(60 * 60 * 24 * 70) // 10 weeks
    @State private var goalType: GoalType = .goal

    enum GoalType: String, CaseIterable {
        case goal = "Goal"
        case milestone = "Milestone"
        case smart = "SMART Goal"

        var icon: String {
            switch self {
            case .goal: return "target"
            case .milestone: return "flag.checkered"
            case .smart: return "star.circle"
            }
        }

        var color: Color {
            switch self {
            case .goal: return .orange
            case .milestone: return .yellow
            case .smart: return .green
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                AdaptiveGradientBackground()

                ScrollView {
                    VStack(spacing: LiquidGlass.Spacing.lg.value) {
                        // Goal type selector
                        goalTypeSelector

                        // Form content
                        formContent

                        // Action buttons
                        actionButtons
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Goal Type Selector

    private var goalTypeSelector: some View {
        LiquidGlassCard(
            elevation: .raised,
            tintColor: goalType.color.opacity(0.1)
        ) {
            VStack(spacing: 12) {
                Text("Goal Type")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(GoalType.allCases, id: \.self) { type in
                        Button {
                            let haptic = UIImpactFeedbackGenerator(style: .soft)
                            haptic.impactOccurred()

                            withAnimation(LiquidGlass.AnimationCurve.snap.animation) {
                                goalType = type
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.title3)
                                    .symbolVariant(goalType == type ? .fill : .none)

                                Text(type.rawValue)
                                    .font(.caption2)
                            }
                            .foregroundStyle(goalType == type ? type.color : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                if goalType == type {
                                    RoundedRectangle(
                                        cornerRadius: LiquidGlass.CornerRadius.small.value,
                                        style: .continuous
                                    )
                                    .fill(.regularMaterial)
                                    .overlay {
                                        RoundedRectangle(
                                            cornerRadius: LiquidGlass.CornerRadius.small.value,
                                            style: .continuous
                                        )
                                        .fill(type.color.opacity(0.15))
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        LiquidGlassCard(elevation: .raised) {
            VStack(spacing: LiquidGlass.Spacing.md.value) {
                LiquidGlassTextField(
                    "Goal Title",
                    text: $title,
                    placeholder: "E.g., Complete 50km running"
                )

                Divider().background(.white.opacity(0.1))

                LiquidGlassTextField(
                    "Target Amount",
                    text: $targetAmount,
                    placeholder: "50",
                    keyboardType: .decimalPad
                )

                Divider().background(.white.opacity(0.1))

                LiquidGlassTextField(
                    "Unit",
                    text: $unit,
                    placeholder: "km"
                )

                Divider().background(.white.opacity(0.1))

                // Date pickers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timeline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Start")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $startDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }

                    HStack {
                        Text("Target")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $targetDate,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        LiquidGlassButton(
            "Create Goal",
            icon: "checkmark.circle.fill",
            style: .primary
        ) {
            saveGoal()
        }
    }

    // MARK: - Actions

    private func saveGoal() {
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)

        // TODO: Implement save logic
        dismiss()
    }
}

// MARK: - Previews

@available(iOS 18.0, *)
#Preview("Action Form") {
    LiquidActionFormView()
        .environment(AppViewModel())
}

@available(iOS 18.0, *)
#Preview("Goal Form") {
    LiquidGoalFormView()
}

#endif
