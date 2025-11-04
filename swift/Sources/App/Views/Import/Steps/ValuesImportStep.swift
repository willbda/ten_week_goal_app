//
// ValuesImportStep.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Values import wizard step
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

public struct ValuesImportStep: View {
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
            if state.stagedData.values.isEmpty {
                inputSection
                    .padding()
            } else {
                resultsSection
            }

            Spacer()
        }
        .navigationTitle("Import Values")
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step 1: Import Personal Values", systemImage: "heart.circle.fill")
                .font(.headline)

            Text("Paste your values as a simple list or CSV. Examples:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Simple: Health & Vitality")
                Text("• CSV: Health & Vitality, major, 90, Physical wellbeing")
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
                Button("Parse Values") {
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
                Text("\(state.stagedData.values.count) values parsed")
                    .font(.headline)

                Spacer()

                Button("Start Over") {
                    state.stagedData.values.removeAll()
                    inputText = ""
                    parseError = nil
                    state.markDirty()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Values table
            List {
                ForEach(state.stagedData.values) { value in
                    ValueRow(value: value, onDelete: {
                        deleteValue(value)
                    })
                }
            }
        }
    }

    // MARK: - Actions

    private func parseInput() {
        parseError = nil

        do {
            let parsed = try ImportParser.parseValues(inputText)

            guard !parsed.isEmpty else {
                parseError = "No values found in input"
                return
            }

            state.stagedData.values = parsed
            state.markDirty()

        } catch {
            parseError = "Parse error: \(error.localizedDescription)"
        }
    }

    private func deleteValue(_ value: StagedValue) {
        state.stagedData.values.removeAll { $0.id == value.id }
        state.markDirty()
    }
}

// MARK: - Value Row

private struct ValueRow: View {
    let value: StagedValue
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(value.title)
                    .font(.body)

                HStack(spacing: 8) {
                    // Level badge (abbreviated for space)
                    Text(levelAbbreviation(value.level))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(levelColor.opacity(0.2))
                        .foregroundStyle(levelColor)
                        .cornerRadius(4)

                    // Priority
                    Text("Priority: \(value.priority)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Status badge
                    StatusBadge(status: value.status)
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

    private var levelColor: Color {
        switch value.level {
        case .general: return .blue
        case .major: return .purple
        case .highestOrder: return .red
        case .lifeArea: return .green
        }
    }

    private func levelAbbreviation(_ level: ValueLevel) -> String {
        switch level {
        case .general: return "General"
        case .major: return "Major"
        case .highestOrder: return "Highest"
        case .lifeArea: return "Life Area"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ValuesImportStep(state: ImportWizardState())
    }
}
