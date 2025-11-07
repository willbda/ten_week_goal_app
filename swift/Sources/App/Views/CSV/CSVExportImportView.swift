//
// CSVExportImportView.swift
// Written by Claude Code on 2025-11-06
//
// PURPOSE:
// Simple UI for CSV export/import operations.
// Demonstrates ActionCSVService usage.
//

import SwiftUI
import SQLiteData
import Dependencies
import Services

struct CSVExportImportView: View {
    @Dependency(\.defaultDatabase) private var database
    @State private var exportResult: String = ""
    @State private var importResult: String = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 20) {
            Text("CSV Import/Export")
                .font(.largeTitle)
                .padding()

            // Export Section
            GroupBox("Export") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export blank template with reference sheets:")
                        .font(.caption)

                    Button(action: exportTemplate) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("Export Template", systemImage: "square.and.arrow.down")
                        }
                    }
                    .disabled(isExporting)

                    Button(action: exportActions) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Label("Export All Actions", systemImage: "square.and.arrow.down.fill")
                        }
                    }
                    .disabled(isExporting)

                    if !exportResult.isEmpty {
                        Text(exportResult)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }

            // Import Section
            GroupBox("Import") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Import actions from CSV file:")
                        .font(.caption)

                    Button(action: { showFilePicker = true }) {
                        if isImporting {
                            ProgressView()
                        } else {
                            Label("Import CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                    .disabled(isImporting)
                    .fileImporter(
                        isPresented: $showFilePicker,
                        allowedContentTypes: [.commaSeparatedText],
                        onCompletion: handleFileSelection
                    )

                    if !importResult.isEmpty {
                        Text(importResult)
                            .font(.caption)
                            .foregroundStyle(importResult.contains("✓") ? .green : .red)
                    }
                }
                .padding()
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Export Operations

    private func exportTemplate() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                // Get Downloads directory
                let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                let result = try await service.exportTemplate(to: downloadsDir)

                exportResult = """
                ✓ Exported 3 files to Downloads:
                - actions_template.csv
                - available_measures.csv
                - available_goals.csv
                """
            } catch {
                exportResult = "⚠️ Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func exportActions() {
        Task {
            isExporting = true
            defer { isExporting = false }

            do {
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                let downloadsDir = FileManager.default.urls(
                    for: .downloadsDirectory,
                    in: .userDomainMask
                )[0]

                let result = try await service.exportActions(to: downloadsDir)

                exportResult = """
                ✓ Exported all actions to Downloads:
                - actions_export.csv
                - available_measures.csv
                - available_goals.csv
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

                // Import
                let coordinator = ActionCoordinator(database: database)
                let service = ActionCSVService(database: database, coordinator: coordinator)

                let importResult = try await service.importActions(from: fileURL)

                self.importResult = importResult.summary

                if importResult.hasFailures {
                    self.importResult += "\n\nErrors:\n"
                    for (row, error) in importResult.failures.prefix(5) {
                        self.importResult += "Row \(row): \(error)\n"
                    }
                    if importResult.failures.count > 5 {
                        self.importResult += "... and \(importResult.failures.count - 5) more"
                    }
                }
            } catch {
                self.importResult = "⚠️ Import failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CSVExportImportView()
        .frame(width: 600, height: 500)
}
