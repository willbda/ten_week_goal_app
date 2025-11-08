//
// CSVExportImportView.swift
// Written by Claude Code on 2025-11-06
// Updated by Claude Code on 2025-11-07 - Added entity type picker for Actions/Goals
//
// PURPOSE:
// Unified UI for CSV export/import operations.
// Supports Actions and Goals via entity type picker.
//

import SwiftUI
import SQLiteData
import Dependencies
import Services

struct CSVExportImportView: View {
    @Dependency(\.defaultDatabase) private var database

    // MARK: - Entity Type Selection

    @State private var selectedEntityType: EntityType = .actions

    enum EntityType: String, CaseIterable, Identifiable {
        case actions = "Actions"
        case goals = "Goals"
        case values = "Values"

        var id: String { rawValue }
    }

    // MARK: - State

    @State private var exportResult: String = ""
    @State private var importResult: String = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showFilePicker = false
    @State private var actionParseResult: CSVParseResult<ActionPreview>?
    @State private var goalParseResult: CSVParseResult<GoalPreview>?
    @State private var valueParseResult: CSVParseResult<ValuePreview>?
    @State private var showPreview = false

    var body: some View {
        // DESIGN: NavigationStack provides proper hierarchy with Liquid Glass navigation bar
        NavigationStack {
            // DESIGN: Form with .grouped style for iOS 18+ section styling and spacing
            Form {
                // DESIGN: Entity type picker section
                Section {
                    Picker("Entity Type", selection: $selectedEntityType) {
                        ForEach(EntityType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Select entity type to import or export")
                } header: {
                    Text("Import/Export Type")
                } footer: {
                    Text(footerText)
                        .font(.caption)
                }

                // DESIGN: Title-case section headers (not ALL CAPS) per iOS 18 guidelines
                Section("Export Options") {
                    // DESIGN: Using VStack in Form sections for proper layout
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export blank template with reference sheets")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // DESIGN: Standard bordered button
                        Button(action: exportTemplate) {
                            if isExporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Export Template", systemImage: "square.and.arrow.down")
                            }
                        }
                        .buttonStyle(.bordered) // DESIGN: Standard button style
                        .disabled(isExporting)
                        .accessibilityLabel("Export blank CSV template") // ACCESSIBILITY: VoiceOver support

                        Button(action: exportAll) {
                            if isExporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Export All \(selectedEntityType.rawValue)", systemImage: "square.and.arrow.down.fill")
                            }
                        }
                        .buttonStyle(.borderedProminent) // DESIGN: Prominent button for primary action
                        .disabled(isExporting)
                        .accessibilityLabel("Export all \(selectedEntityType.rawValue.lowercased()) to CSV") // ACCESSIBILITY: VoiceOver support

                        if !exportResult.isEmpty {
                            Text(exportResult)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }

                // DESIGN: Title-case section header
                Section("Import Options") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Import \(selectedEntityType.rawValue.lowercased()) from CSV file")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button(action: { showFilePicker = true }) {
                            if isImporting {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Choose CSV File", systemImage: "doc.badge.arrow.up")
                            }
                        }
                        .buttonStyle(.bordered) // DESIGN: Standard button style
                        .disabled(isImporting)
                        .accessibilityLabel("Choose CSV file to import") // ACCESSIBILITY: VoiceOver support
                        .fileImporter(
                            isPresented: $showFilePicker,
                            allowedContentTypes: [.commaSeparatedText],
                            onCompletion: handleFileSelection
                        )

                        if !importResult.isEmpty {
                            // DESIGN: Semantic colors with proper styling
                            Label {
                                Text(importResult)
                                    .font(.caption)
                            } icon: {
                                Image(systemName: importResult.contains("✓") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(importResult.contains("✓") ? .green : .orange)
                            }
                            .labelStyle(.titleAndIcon)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .formStyle(.grouped) // DESIGN: Grouped form style with proper spacing
            .navigationTitle("CSV Import & Export") // DESIGN: Clear navigation hierarchy
        }
        .sheet(isPresented: $showPreview) {
            Group {
                switch selectedEntityType {
                case .actions:
                    if let result = actionParseResult {
                        ImportPreviewView(
                            parseResult: result,
                            onConfirm: confirmActionImport,
                            onCancel: cancelImport,
                            entityName: "Action"
                        )
                    }
                case .goals:
                    if let result = goalParseResult {
                        ImportPreviewView(
                            parseResult: result,
                            onConfirm: confirmGoalImport,
                            onCancel: cancelImport,
                            entityName: "Goal"
                        )
                    }
                case .values:
                    if let result = valueParseResult {
                        ImportPreviewView(
                            parseResult: result,
                            onConfirm: confirmValueImport,
                            onCancel: cancelImport,
                            entityName: "Value"
                        )
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var footerText: String {
        switch selectedEntityType {
        case .actions:
            return "Import or export actions with measurements and goal contributions"
        case .goals:
            return "Import or export goals with metric targets and value alignments"
        case .values:
            return "Import or export personal values with levels and alignment guidance"
        }
    }

    // MARK: - Export Operations

    private func exportTemplate() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                let path: URL
                switch selectedEntityType {
                case .actions:
                    let coordinator = ActionCoordinator(database: database)
                    let service = ActionCSVService(database: database, coordinator: coordinator)
                    path = try await service.exportTemplate(to: downloadsDir)

                case .goals:
                    let coordinator = GoalCoordinator(database: database)
                    let service = GoalCSVService(database: database, coordinator: coordinator)
                    path = try await service.exportTemplate(to: downloadsDir)

                case .values:
                    let coordinator = PersonalValueCoordinator(database: database)
                    let service = ValueCSVService(database: database, coordinator: coordinator)
                    path = try await service.exportTemplate(to: downloadsDir)
                }

                exportResult = """
                ✓ Exported template to Downloads:
                - \(path.lastPathComponent)
                """
            } catch {
                exportResult = "⚠️ Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func exportAll() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                let path: URL
                switch selectedEntityType {
                case .actions:
                    let coordinator = ActionCoordinator(database: database)
                    let service = ActionCSVService(database: database, coordinator: coordinator)
                    path = try await service.exportActions(to: downloadsDir)

                case .goals:
                    let coordinator = GoalCoordinator(database: database)
                    let service = GoalCSVService(database: database, coordinator: coordinator)
                    path = try await service.exportGoals(to: downloadsDir)

                case .values:
                    let coordinator = PersonalValueCoordinator(database: database)
                    let service = ValueCSVService(database: database, coordinator: coordinator)
                    path = try await service.exportValues(to: downloadsDir)
                }

                exportResult = """
                ✓ Exported all \(selectedEntityType.rawValue.lowercased()) to Downloads:
                - \(path.lastPathComponent)
                """
            } catch {
                exportResult = "⚠️ Export failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Import Operations

    private func handleFileSelection(_ result: Result<URL, Error>) {
        Task {
            isImporting = true
            defer { isImporting = false }

            do {
                let fileURL = try result.get()

                // Grant access to security-scoped resource
                guard fileURL.startAccessingSecurityScopedResource() else {
                    importResult = "⚠️ Could not access file"
                    return
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }

                // Parse and show preview based on selected entity type
                switch selectedEntityType {
                case .actions:
                    let coordinator = ActionCoordinator(database: database)
                    let service = ActionCSVService(database: database, coordinator: coordinator)
                    let result = try await service.previewImport(from: fileURL)
                    actionParseResult = result

                case .goals:
                    let coordinator = GoalCoordinator(database: database)
                    let service = GoalCSVService(database: database, coordinator: coordinator)
                    let result = try await service.previewImport(from: fileURL)
                    goalParseResult = result

                case .values:
                    let coordinator = PersonalValueCoordinator(database: database)
                    let service = ValueCSVService(database: database, coordinator: coordinator)
                    let result = try await service.previewImport(from: fileURL)
                    valueParseResult = result
                }

                showPreview = true

            } catch {
                self.importResult = "⚠️ Parse failed: \(error.localizedDescription)"
            }
        }
    }

    private func confirmActionImport(_ selectedPreviews: [ActionPreview]) {
        Task {
            isImporting = true
            defer { isImporting = false }

            do {
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                let importResult = try await service.importSelected(selectedPreviews)
                displayImportResult(importResult)

                // Close preview
                showPreview = false
                actionParseResult = nil

            } catch {
                self.importResult = "⚠️ Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func confirmGoalImport(_ selectedPreviews: [GoalPreview]) {
        Task {
            isImporting = true
            defer { isImporting = false }

            do {
                let coordinator = GoalCoordinator(database: database)
                let service = GoalCSVService(database: database, coordinator: coordinator)

                let importResult = try await service.importSelected(selectedPreviews)
                displayImportResult(importResult)

                // Close preview
                showPreview = false
                goalParseResult = nil

            } catch {
                self.importResult = "⚠️ Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func confirmValueImport(_ selectedPreviews: [ValuePreview]) {
        Task {
            isImporting = true
            defer { isImporting = false }

            do {
                let coordinator = PersonalValueCoordinator(database: database)
                let service = ValueCSVService(database: database, coordinator: coordinator)

                let importResult = try await service.importSelected(selectedPreviews)
                displayImportResult(importResult)

                // Close preview
                showPreview = false
                valueParseResult = nil

            } catch {
                self.importResult = "⚠️ Import failed: \(error.localizedDescription)"
            }
        }
    }

    private func cancelImport() {
        showPreview = false
        actionParseResult = nil
        goalParseResult = nil
        valueParseResult = nil
    }

    private func displayImportResult(_ result: CSVImportResult) {
        self.importResult = result.summary

        if result.hasFailures {
            self.importResult += "\n\nErrors:\n"
            for (row, error) in result.failures.prefix(5) {
                self.importResult += "Row \(row): \(error)\n"
            }
            if result.failures.count > 5 {
                self.importResult += "... and \(result.failures.count - 5) more"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CSVExportImportView()
        .frame(width: 600, height: 500)
}
