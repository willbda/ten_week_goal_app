//
// MeasuresImportStep.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Measures import wizard step
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

public struct MeasuresImportStep: View {
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
            if state.stagedData.measures.isEmpty {
                inputSection
                    .padding()
            } else {
                resultsSection
            }

            Spacer()
        }
        .navigationTitle("Import Measures")
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Step 2: Import Measures", systemImage: "ruler.fill")
                .font(.headline)

            Text("Paste your measures as a simple list or CSV. Examples:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("• Simple: km")
                Text("• CSV: km, distance, Distance in kilometers")
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
                Button("Parse Measures") {
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
                Text("\(state.stagedData.measures.count) measures parsed")
                    .font(.headline)

                Spacer()

                Button("Start Over") {
                    state.stagedData.measures.removeAll()
                    inputText = ""
                    parseError = nil
                    state.markDirty()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Measures table
            List {
                ForEach(state.stagedData.measures) { measure in
                    MeasureRow(measure: measure, onDelete: {
                        deleteMeasure(measure)
                    })
                }
            }
        }
    }

    // MARK: - Actions

    private func parseInput() {
        parseError = nil

        do {
            let parsed = try ImportParser.parseMeasures(inputText)

            guard !parsed.isEmpty else {
                parseError = "No measures found in input"
                return
            }

            state.stagedData.measures = parsed
            state.markDirty()

        } catch {
            parseError = "Parse error: \(error.localizedDescription)"
        }
    }

    private func deleteMeasure(_ measure: StagedMeasure) {
        state.stagedData.measures.removeAll { $0.id == measure.id }
        state.markDirty()
    }
}

// MARK: - Measure Row

private struct MeasureRow: View {
    let measure: StagedMeasure
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(measure.unit)
                    .font(.body)

                HStack(spacing: 8) {
                    // Type badge
                    Text(measure.measureType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.2))
                        .foregroundStyle(typeColor)
                        .cornerRadius(4)

                    // Status badge
                    StatusBadge(status: measure.status)
                }

                if let description = measure.detailedDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private var typeColor: Color {
        switch measure.measureType.lowercased() {
        case "distance": return .blue
        case "time", "duration": return .green
        case "mass": return .purple
        case "count": return .orange
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        MeasuresImportStep(state: ImportWizardState())
    }
}
