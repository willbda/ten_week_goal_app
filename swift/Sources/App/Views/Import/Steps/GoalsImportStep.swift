//
// GoalsImportStep.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Goals import wizard step
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

public struct GoalsImportStep: View {
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
            if state.stagedData.goals.isEmpty {
                inputSection
                    .padding()
            } else {
                resultsSection
            }

            Spacer()
        }
        .navigationTitle("Import Goals")
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step 3: Import Goals", systemImage: "target")
                .font(.headline)

            Text("Paste your goals using pipe-separated format:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Format: Title | Target | Unit | Values")
                Text("• Example: Run 120km | 120 | km | Health, Movement")
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
                Button("Parse Goals") {
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
                Text("\(state.stagedData.goals.count) goals parsed")
                    .font(.headline)

                Spacer()

                Button("Start Over") {
                    state.stagedData.goals.removeAll()
                    inputText = ""
                    parseError = nil
                    state.markDirty()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Goals table
            List {
                ForEach(state.stagedData.goals) { goal in
                    GoalRow(goal: goal, onDelete: {
                        deleteGoal(goal)
                    })
                }
            }
        }
    }

    // MARK: - Actions

    private func parseInput() {
        parseError = nil

        do {
            let parsed = try ImportParser.parseGoals(
                inputText,
                stagedMeasures: state.stagedData.measures,
                stagedValues: state.stagedData.values
            )

            guard !parsed.isEmpty else {
                parseError = "No goals found in input"
                return
            }

            state.stagedData.goals = parsed
            state.markDirty()

        } catch {
            parseError = "Parse error: \(error.localizedDescription)"
        }
    }

    private func deleteGoal(_ goal: StagedGoal) {
        state.stagedData.goals.removeAll { $0.id == goal.id }
        state.markDirty()
    }
}

// MARK: - Goal Row

private struct GoalRow: View {
    let goal: StagedGoal
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.body)

                HStack(spacing: 8) {
                    // Target
                    Text("\(Int(goal.targetValue)) \(measureDisplayName)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)

                    // Status badge
                    StatusBadge(status: goal.status)
                }

                // Value references
                if !goal.valueRefs.isEmpty {
                    HStack(spacing: 4) {
                        Text("Values:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ForEach(goal.valueRefs, id: \.input) { ref in
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

    private var measureDisplayName: String {
        switch goal.measureRef {
        case .existing, .staged:
            return "unit"
        case .unresolved(let unit):
            return unit
        }
    }
}

#Preview {
    NavigationStack {
        GoalsImportStep(state: ImportWizardState())
    }
}
