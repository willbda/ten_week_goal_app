import Models
import SwiftUI

public struct PersonalValuesFormView: View {
    @StateObject private var viewModel = PersonalValueFormViewModel()
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title: String = ""
    @State private var selectedLevel: ValueLevel = .general
    @State private var priority: Int = 50
    @State private var description: String = ""
    @State private var notes: String = ""
    @State private var lifeDomain: String = ""
    @State private var alignmentGuidance: String = ""

    // TODO: Phase 4 - Add Edit Mode Support
    // PATTERN: enum Mode { case create; case edit(PersonalValue) }
    // WHEN: Before allowing users to edit existing values
    // IMPL: Add .onAppear { if case .edit(let value) = mode { loadExistingValue(value) } }
    public init() {}

    public var body: some View {
        FormScaffold(
            title: "New Value",
            canSubmit: !title.isEmpty && !viewModel.isSaving,
            onSubmit: handleSubmit,
            onCancel: { dismiss() }
        ) {
            DocumentableFields(
                title: $title,
                detailedDescription: $description,
                freeformNotes: $notes
            )

            Section("Value Properties") {
                Picker("Level", selection: $selectedLevel) {
                    ForEach(ValueLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }

                Stepper("Priority: \(priority)", value: $priority, in: 1...100)
            }

            Section("Context") {
                TextField("Life Domain", text: $lifeDomain)
                TextField("Alignment Guidance", text: $alignmentGuidance, axis: .vertical)
                    .lineLimit(3...6)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func handleSubmit() {
        Task {
            do {
                _ = try await viewModel.save(
                    title: title,
                    level: selectedLevel,
                    priority: priority,
                    description: description.isEmpty ? nil : description,
                    notes: notes.isEmpty ? nil : notes,
                    lifeDomain: lifeDomain.isEmpty ? nil : lifeDomain,
                    alignmentGuidance: alignmentGuidance.isEmpty ? nil : alignmentGuidance
                )

                // NOTE: Dismiss Timing Options
                // CURRENT: Immediate dismiss (no success feedback)
                // OPTION A: Add brief delay for success moment
                //   try? await Task.sleep(for: .milliseconds(300))
                // OPTION B: Show success message before dismiss (requires @Published successMessage)
                //   viewModel.successMessage = "Value saved!"
                //   try? await Task.sleep(for: .seconds(1))
                // WHEN: Phase 5 - if UX testing shows users want confirmation
                // TRADEOFF: Delay adds friction, but provides feedback
                dismiss()
            } catch {
                // Error already set in viewModel.errorMessage and displayed in form
            }
        }
    }

    // TODO: Phase 5 - Add Success Animation
    // PATTERN: .onChange(of: viewModel.successMessage) { _, newValue in
    //     if newValue != nil {
    //         withAnimation(.spring()) { /* show checkmark */ }
    //     }
    // }
    // WHEN: If user feedback indicates they want success confirmation
    // IMPL: Requires @Published var successMessage: String? in ViewModel
}

