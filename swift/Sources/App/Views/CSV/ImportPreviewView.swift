//
// ImportPreviewView.swift
// Written by Claude Code on 2025-11-06
// Updated by Claude Code on 2025-11-07 - Made generic over CSVPreviewable
//
// PURPOSE:
// Preview and confirm CSV import before committing to database.
// Shows parsed items (Actions, Goals, etc.) with checkbox selection.
// Generic over any CSVPreviewable type.
//

import SwiftUI
import Services

struct ImportPreviewView<Preview: CSVPreviewable>: View {
    let parseResult: CSVParseResult<Preview>
    let onConfirm: ([Preview]) -> Void
    let onCancel: () -> Void
    let entityName: String  // "Action", "Goal", etc.

    @State private var selectedPreviews: Set<UUID> = []
    @State private var selectAll: Bool = true

    var body: some View {
        NavigationStack {
            previewList
                .navigationTitle("Review Import")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel, action: onCancel)
                            .accessibilityLabel("Cancel import")
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import \(selectedCount)") {
                            confirmImport()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedPreviews.isEmpty)
                        .accessibilityLabel("Import \(selectedCount) selected actions")
                    }
                }
                .safeAreaInset(edge: .top) {
                    summaryBar
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }
        }
        .frame(minWidth: 600, idealWidth: 700, minHeight: 400, idealHeight: 600)
        .onAppear {
            selectedPreviews = Set(parseResult.previews.filter { $0.isValid }.map { $0.id })
        }
    }

    // DESIGN: Extracted list view to reduce type-checking complexity
    private var previewList: some View {
        List {
            if !parseResult.errors.isEmpty {
                Section("Parse Errors") {
                    ForEach(parseResult.errors, id: \.self) { error in
                        Label {
                            Text(error)
                                .font(.caption)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Error: \(error)")
                    }
                }
            }

            Section {
                ForEach(parseResult.previews) { preview in
                    PreviewRow(preview: preview, isSelected: selectedPreviews.contains(preview.id))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(preview.id)
                        }
                        .accessibilityLabel("\(preview.title), \(preview.isValid ? "valid" : "has issues")")
                        .accessibilityHint("Tap to \(selectedPreviews.contains(preview.id) ? "deselect" : "select") for import")
                }
            } header: {
                sectionHeader
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // DESIGN: Extracted header to reduce complexity
    private var sectionHeader: some View {
        HStack {
            Text("\(entityName)s to Import")
                .font(.headline)
            Text("(\(selectedCount) of \(parseResult.previews.count) selected)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button(selectAll ? "Deselect All" : "Select All") {
                toggleSelectAll()
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .accessibilityLabel(selectAll ? "Deselect all actions" : "Select all valid actions")
        }
    }

    // MARK: - Components

    // DESIGN: Summary bar with glass effect for visual hierarchy
    private var summaryBar: some View {
        HStack(spacing: 20) {
            summaryItem(count: parseResult.validCount, label: "Valid", color: .green)
            if parseResult.warningCount > 0 {
                summaryItem(count: parseResult.warningCount, label: "Warnings", color: .orange)
            }
            if parseResult.errorCount > 0 {
                summaryItem(count: parseResult.errorCount, label: "Errors", color: .red)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial) // DESIGN: Thin material for subtle glass effect
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func summaryItem(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private var selectedCount: Int {
        selectedPreviews.count
    }

    private func toggleSelection(_ id: UUID) {
        if selectedPreviews.contains(id) {
            selectedPreviews.remove(id)
        } else {
            selectedPreviews.insert(id)
        }
    }

    private func toggleSelectAll() {
        if selectAll {
            // Deselect all
            selectedPreviews.removeAll()
        } else {
            // Select all valid
            selectedPreviews = Set(parseResult.previews.filter { $0.isValid }.map { $0.id })
        }
        selectAll.toggle()
    }

    private func confirmImport() {
        let selected = parseResult.previews.filter { selectedPreviews.contains($0.id) }
        onConfirm(selected)
    }
}

// MARK: - Preview Row

struct PreviewRow<Preview: CSVPreviewable>: View {
    let preview: Preview
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // DESIGN: Interactive checkbox with smooth animation
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .animation(.smooth(duration: 0.2), value: isSelected) // DESIGN: Smooth state transition
                .accessibilityHidden(true) // ACCESSIBILITY: Redundant with row label

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // DESIGN: Clear hierarchy with semantic fonts
                Text(preview.title)
                    .font(.headline)
                    .lineLimit(2)

                // DESIGN: Summary text (entity-specific details)
                Text(preview.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                // DESIGN: Validation status with appropriate semantic color
                if let message = preview.validationStatus.message {
                    Label {
                        Text(message)
                            .font(.caption)
                    } icon: {
                        Image(systemName: preview.validationStatus.icon)
                    }
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(statusColor)
                    .padding(.top, 2)
                }
            }

            Spacer()

            // DESIGN: Row number badge
            Text("#\(preview.rowNumber)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(nsColor: .systemGray).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 6) // DESIGN: More breathing room (iOS 18 spacing)
    }

    private var statusColor: Color {
        switch preview.validationStatus {
        case .valid: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Preview

#Preview("Actions") {
    ImportPreviewView(
        parseResult: CSVParseResult(previews: [
            ActionPreview(
                rowNumber: 1,
                title: "Morning run",
                description: "Beautiful weather",
                measurements: [("km", 5.2), ("minutes", 28)],
                goalTitles: ["Spring into Running"]
            )
        ]),
        onConfirm: { selected in
            print("Importing \(selected.count) actions")
        },
        onCancel: {
            print("Cancelled")
        },
        entityName: "Action"
    )
    .frame(width: 700, height: 600)
}

#Preview("Goals") {
    ImportPreviewView(
        parseResult: CSVParseResult(previews: [
            GoalPreview(
                rowNumber: 1,
                title: "Run 120km",
                description: "Spring training",
                targets: [("km", 120)],
                valueNames: ["Health", "Movement"]
            )
        ]),
        onConfirm: { selected in
            print("Importing \(selected.count) goals")
        },
        onCancel: {
            print("Cancelled")
        },
        entityName: "Goal"
    )
    .frame(width: 700, height: 600)
}


//#Preview {
//    ImportPreviewView(
//        parseResult: ParseResult(
//            previews: [
//                ActionPreview(
//                    rowNumber: 1,
//                    title: "Morning run",
//                    description: "Great weather",
//                    measurements: [("km", 5.2), ("minutes", 28)],
//                    goalTitles: ["Spring into Running"],
//                    validationStatus: .valid
//                ),
//                ActionPreview(
//                    rowNumber: 2,
//                    title: "Evening run",
//                    measurements: [("kilometers", 4.1)],
//                    validationStatus: .error("Measure 'kilometers' not found. Available: km, miles, m")
//                ),
//                ActionPreview(
//                    rowNumber: 3,
//                    title: "Guitar practice",
//                    measurements: [("minutes", 45)],
//                    goalTitles: ["Build Guitar Skills"],
//                    validationStatus: .valid
//                )
//            ],
//            errors: ["Row 10: Missing required field 'title'"]
//        ),
//        onConfirm: { selected in
//            print("Importing \(selected.count) actions")
//        },
//        onCancel: {
//            print("Cancelled")
//        }
//    )
//    .frame(width: 700, height: 600)
//}
