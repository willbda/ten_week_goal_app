//
// ActionsImportStep.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Actions import wizard step
// UI: Paste area → Parse → Review table → Next
//
// FUTURE ENHANCEMENT (Option 3 - Hybrid Paste + Edit):
// After parsing, show editable rows with TextFields instead of read-only table.
// This allows users to paste bulk data, then fix errors without re-pasting.
// See discussion 2025-11-03 about SwiftUI Table limitations and import UX.
//

import SwiftUI
import Services
import Models

public struct ActionsImportStep: View {
    @Bindable var state: ImportWizardState
    @State private var inputText: String = ""
    @State private var parseError: String?

    public var body: some View {
        VStack(spacing: 0) {
            // Instructions
            instructionsSection
                .padding()

            Divider()

            // Input area or results table
            if state.stagedData.actions.isEmpty {
                inputSection
                    .padding()
            } else {
                resultsSection
            }

            Spacer()
        }
        .navigationTitle("Import Actions")
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step 4: Import Actions", systemImage: "checkmark.circle.fill")
                .font(.headline)

            Text("Paste your actions using pipe-separated format:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Format: Title | Date | Measurements | Goals")
                Text("• Example: Morning run | 2025-11-03 | km:5.2 | Run 120km")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Input Section

    private var inputSection: some View {
        VStack(spacing: 16) {
            TextEditor(text: $inputText)
                .font(.body)
                .frame(minHeight: 200)
                .padding(8)
                #if os(macOS)
                .background(Color(nsColor: .textBackgroundColor))
                #else
                .background(Color(uiColor: .systemBackground))
                #endif
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            if let error = parseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Parse Actions") {
                    parseInput()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !inputText.isEmpty {
                    Button("Clear") {
                        inputText = ""
                        parseError = nil
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(spacing: 0) {
            // Summary header
            HStack {
                Text("\(state.stagedData.actions.count) actions parsed")
                    .font(.headline)

                Spacer()

                Button("Start Over") {
                    state.stagedData.actions.removeAll()
                    inputText = ""
                    parseError = nil
                    state.markDirty()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Actions table
            List {
                ForEach(state.stagedData.actions) { action in
                    ActionRow(action: action, onDelete: {
                        deleteAction(action)
                    })
                }
            }
        }
    }

    // MARK: - Actions

    private func parseInput() {
        parseError = nil

        do {
            let parsed = try ImportParser.parseActions(
                inputText,
                stagedMeasures: state.stagedData.measures,
                stagedGoals: state.stagedData.goals
            )

            guard !parsed.isEmpty else {
                parseError = "No actions found in input"
                return
            }

            state.stagedData.actions = parsed
            state.markDirty()

        } catch {
            parseError = "Parse error: \(error.localizedDescription)"
        }
    }

    private func deleteAction(_ action: StagedAction) {
        state.stagedData.actions.removeAll { $0.id == action.id }
        state.markDirty()
    }
}

// MARK: - Action Row

private struct ActionRow: View {
    let action: StagedAction
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.body)

                HStack(spacing: 8) {
                    // Date
                    Text(action.date, style: .date)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .cornerRadius(4)

                    // Status badge
                    StatusBadge(status: action.status)
                }

                // Measurements
                if !action.measurements.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(action.measurements.indices, id: \.self) { index in
                            let measurement = action.measurements[index]
                            Text("\(measurementUnit(measurement)): \(measurement.value, specifier: "%.1f")")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(3)
                        }
                    }
                }

                // Goal references
                if !action.goalRefs.isEmpty {
                    HStack(spacing: 4) {
                        Text("Goals:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(action.goalRefs, id: \.input) { ref in
                            Text(ref.input)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(3)
                        }
                    }
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func measurementUnit(_ measurement: StagedMeasurement) -> String {
        switch measurement.measureRef {
        case .existing, .staged:
            return "unit"
        case .unresolved(let unit):
            return unit
        }
    }
}

#Preview {
    NavigationStack {
        ActionsImportStep(state: ImportWizardState())
    }
}
