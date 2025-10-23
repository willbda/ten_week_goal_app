// GoalDocument.swift
// Document-based file format for individual goals
//
// Written by Claude Code on 2025-10-23

import SwiftUI
import UniformTypeIdentifiers
import Models

// MARK: - Document Type

extension UTType {
    /// Custom document type for goal files (.tenweekgoal)
    static var tenWeekGoal: UTType {
        UTType(exportedAs: "com.tenweekgoal.goal")
    }
}

// MARK: - Goal Document

/// Document wrapper for individual goal files
///
/// Enables save/open of individual goals as standalone files.
/// Can be used alongside the database-based approach for:
/// - Sharing goals between users
/// - Version control (git-friendly)
/// - Backup/restore individual goals
struct GoalDocument: FileDocument {

    // MARK: - Properties

    var goal: Goal

    // MARK: - FileDocument Conformance

    static var readableContentTypes: [UTType] { [.tenWeekGoal, .json] }
    static var writableContentTypes: [UTType] { [.tenWeekGoal] }

    // MARK: - Initialization

    init(goal: Goal = Goal(title: "New Goal")) {
        self.goal = goal
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.goal = try decoder.decode(Goal.self, from: data)
    }

    // MARK: - Writing

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(goal)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Document-Based App Scene

/// Alternative app structure using DocumentGroup
///
/// To enable document-based mode:
/// 1. Replace WindowGroup in TenWeekGoalApp.swift with this DocumentGroup
/// 2. Add Info.plist entries for the custom document type
/// 3. Users can then create/open individual .tenweekgoal files
struct GoalDocumentApp: Scene {
    var body: some Scene {
        DocumentGroup(newDocument: GoalDocument()) { file in
            GoalDocumentEditor(document: file.$document)
        }
        .commands {
            // Add custom menu commands for document operations
            CommandGroup(after: .newItem) {
                Button("New Goal from Template...") {
                    // TODO: Show template picker
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Document Editor

/// Editor view for a single goal document
struct GoalDocumentEditor: View {
    @Binding var document: GoalDocument

    @State private var title: String
    @State private var detailedDescription: String
    @State private var measurementTarget: String
    @State private var measurementUnit: String

    init(document: Binding<GoalDocument>) {
        self._document = document

        // Initialize state from document
        let goal = document.wrappedValue.goal
        _title = State(initialValue: goal.title ?? "")
        _detailedDescription = State(initialValue: goal.detailedDescription ?? "")
        _measurementTarget = State(initialValue: goal.measurementTarget.map { String($0) } ?? "")
        _measurementUnit = State(initialValue: goal.measurementUnit ?? "")
    }

    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Goal Name", text: $title)
                    .font(.title2)

                TextField("Description", text: $detailedDescription, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("Target") {
                HStack {
                    TextField("Amount", text: $measurementTarget)
                        .frame(maxWidth: 100)

                    TextField("Unit", text: $measurementUnit)
                }
            }
        }
        .formStyle(.grouped)
        .padding(DesignSystem.Spacing.formPadding)
        .onChange(of: title) { _, newValue in
            updateDocument()
        }
        .onChange(of: detailedDescription) { _, newValue in
            updateDocument()
        }
        .onChange(of: measurementTarget) { _, newValue in
            updateDocument()
        }
        .onChange(of: measurementUnit) { _, newValue in
            updateDocument()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Export to database
                } label: {
                    Label("Add to Database", systemImage: "arrow.down.doc")
                }
            }
        }
    }

    private func updateDocument() {
        document.goal = Goal(
            title: title.isEmpty ? nil : title,
            detailedDescription: detailedDescription.isEmpty ? nil : detailedDescription,
            measurementUnit: measurementUnit.isEmpty ? nil : measurementUnit,
            measurementTarget: Double(measurementTarget),
            startDate: document.goal.startDate,
            targetDate: document.goal.targetDate,
            logTime: document.goal.logTime,
            id: document.goal.id
        )
    }
}

// MARK: - Hybrid Approach

/// Combined app supporting both database and document-based workflows
///
/// This is the recommended approach:
/// - Primary workflow: Database-based (WindowGroup)
/// - Secondary workflow: File-based for sharing/backup (DocumentGroup)
struct HybridApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        // Primary: Database-based window
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .task {
                    await appViewModel.initialize()
                }
                .frame(minWidth: 800, minHeight: 600)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Import Goal File...") {
                    // TODO: Show file picker
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Button("Export Goal as File...") {
                    // TODO: Show goal picker + save panel
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }

        // Secondary: Document-based for individual files
        DocumentGroup(newDocument: GoalDocument()) { file in
            GoalDocumentEditor(document: file.$document)
        }
    }
}
