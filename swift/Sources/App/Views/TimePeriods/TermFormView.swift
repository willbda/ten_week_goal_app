//
// TermFormView.swift
// Written by Claude Code on 2025-11-02
//
// PURPOSE: User-friendly form for creating Terms (wraps generic TimePeriodFormViewModel)
// ARCHITECTURE: Type-specific view using generic ViewModel with specialization = .term
//

import Models
import Services
import SwiftUI

/// Form for creating a new Term (10-week planning period).
///
/// ARCHITECTURE DECISION: Type-Specific View + Generic ViewModel
/// - View is user-friendly (says "Term", not "Time Period")
/// - Wraps TimePeriodFormViewModel with pre-configured specialization = .term(number)
/// - User never sees "Time Period" or "Specialization" in UI
///
/// PATTERN: Based on PersonalValuesFormView
/// - FormScaffold template
/// - @State for ViewModel (not @StateObject)
/// - Individual @State properties for form fields
/// - Async save in Task
public struct TermFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TimePeriodFormViewModel()

    // Term-specific fields
    @State private var termNumber: Int = 1
    @State private var startDate = Date()
    @State private var targetDate = Calendar.current.date(byAdding: .weekOfYear, value: 10, to: Date()) ?? Date()

    // Generic TimePeriod fields
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var notes: String = ""

    public var body: some View {
        FormScaffold(
            title: "New Term",
            canSubmit: !viewModel.isSaving,
            onSubmit: handleSubmit,
            onCancel: { dismiss() }
        ) {
            Section("Term Details") {
                Stepper("Term Number: \(termNumber)", value: $termNumber, in: 1...52)
                    .accessibilityLabel("Term number")

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)

                DatePicker("End Date", selection: $targetDate, displayedComponents: .date)
            }

            DocumentableFields(
                title: $title,
                detailedDescription: $description,
                freeformNotes: $notes
            )

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
    }

    private func handleSubmit() {
        Task {
            do {
                _ = try await viewModel.save(
                    startDate: startDate,
                    targetDate: targetDate,
                    specialization: .term(number: termNumber),  // Type-specific!
                    title: title.isEmpty ? nil : title,
                    description: description.isEmpty ? nil : description,
                    notes: notes.isEmpty ? nil : notes
                )
                dismiss()
            } catch {
                // Error already set in viewModel.errorMessage
            }
        }
    }
}
