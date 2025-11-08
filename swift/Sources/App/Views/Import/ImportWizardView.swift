//
// ImportWizardView.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Main wizard container with step navigation
// UI: Current step view, progress indicator, navigation
//

import SwiftUI
import Services

public struct ImportWizardView: View {
    @State private var wizardState = ImportWizardState()

    public var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressBar(currentStep: wizardState.currentStep)
                .padding()

            Divider()

            // Current step view
            currentStepView

            Divider()

            // Navigation buttons
            navigationButtons
                .padding()
        }
        .navigationTitle("Import Wizard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save Draft") {
                    saveDraft()
                }
            }
        }
    }

    // MARK: - Step Views

    @ViewBuilder
    private var currentStepView: some View {
        switch wizardState.currentStep {
        case .values:
            ValuesImportStep(state: wizardState)
        case .measures:
            MeasuresImportStep(state: wizardState)
        case .goals:
            GoalsImportStep(state: wizardState)
        case .actions:
            ActionsImportStep(state: wizardState)
        case .review:
            ReviewStep(state: wizardState)
        case .commit:
            CommitStep(state: wizardState)
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            // Back button
            if wizardState.currentStep != .values {
                Button("Back") {
                    goBack()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            // Next/Finish button
            Button(nextButtonLabel) {
                goNext()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed)
        }
    }

    private var nextButtonLabel: String {
        switch wizardState.currentStep {
        case .commit:
            return "Finish"
        case .review:
            return "Commit"
        default:
            return "Next"
        }
    }

    private var canProceed: Bool {
        switch wizardState.currentStep {
        case .values:
            return !wizardState.stagedData.values.isEmpty
        case .measures:
            return !wizardState.stagedData.measures.isEmpty
        case .goals:
            return !wizardState.stagedData.goals.isEmpty
        case .actions:
            return !wizardState.stagedData.actions.isEmpty
        case .review:
            return wizardState.validation.canCommit
        case .commit:
            return false  // Can't proceed past commit
        }
    }

    // MARK: - Actions

    private func goBack() {
        let steps: [WizardStep] = [.values, .measures, .goals, .actions, .review, .commit]
        guard let currentIndex = steps.firstIndex(of: wizardState.currentStep),
              currentIndex > 0 else { return }

        wizardState.currentStep = steps[currentIndex - 1]
        wizardState.markDirty()
    }

    private func goNext() {
        let steps: [WizardStep] = [.values, .measures, .goals, .actions, .review, .commit]
        guard let currentIndex = steps.firstIndex(of: wizardState.currentStep),
              currentIndex < steps.count - 1 else { return }

        wizardState.currentStep = steps[currentIndex + 1]
        wizardState.markDirty()
    }

    private func saveDraft() {
        // TODO: Implement draft saving
        print("Saving draft...")
    }
}

// MARK: - Progress Bar

private struct ProgressBar: View {
    let currentStep: WizardStep

    private let steps: [WizardStep] = [.values, .measures, .goals, .actions, .review, .commit]

    private var currentIndex: Int {
        steps.firstIndex(of: currentStep) ?? 0
    }

    private var progress: Double {
        Double(currentIndex) / Double(steps.count - 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)

            // Step labels
            HStack {
                ForEach(steps, id: \.self) { step in
                    Text(stepLabel(step))
                        .font(.caption)
                        .foregroundStyle(step == currentStep ? .primary : .secondary)

                    if step != steps.last {
                        Spacer()
                    }
                }
            }
        }
    }

    private func stepLabel(_ step: WizardStep) -> String {
        switch step {
        case .values: return "Values"
        case .measures: return "Measures"
        case .goals: return "Goals"
        case .actions: return "Actions"
        case .review: return "Review"
        case .commit: return "Commit"
        }
    }
}

#Preview {
    NavigationStack {
        ImportWizardView()
    }
}
