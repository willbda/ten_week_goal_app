//
// ImportWizardState.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Main state manager for import wizard with JSON persistence and auto-save.
// Handles loading/saving active imports, drafts, and crash recovery.
//
// ARCHITECTURE:
// - @Observable for SwiftUI reactivity
// - FileManager for JSON persistence
// - Timer for auto-save every 30 seconds
// - Three file locations: active_import.json, drafts/, completed/
//
// USAGE:
// ```swift
// @State var wizardState = ImportWizardState()
//
// // State automatically loads from active_import.json if exists
// // Auto-saves every 30s or when markDirty() called
//
// wizardState.stagedData.values.append(newValue)
// wizardState.markDirty()  // Triggers save
// ```
//

import Foundation
import Observation

@Observable
public class ImportWizardState {
    // MARK: - File Management

    private let fileManager = FileManager.default
    private let importDirectory: URL
    private let activeImportURL: URL

    // MARK: - Current State

    public var currentStep: WizardStep = .values
    public var stagedData: StagedData
    public var validation: ValidationState

    // MARK: - Auto-Save

    private var lastSaved: Date = Date()
    private var isDirty: Bool = false
    private var autoSaveTimer: Timer?

    // MARK: - Initialization

    public init() {
        // Setup directories
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.importDirectory = appSupport.appendingPathComponent("GoalTracker/imports")
        self.activeImportURL = importDirectory.appendingPathComponent("active_import.json")

        // Create directories
        try? fileManager.createDirectory(at: importDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(
            at: importDirectory.appendingPathComponent("drafts"),
            withIntermediateDirectories: true
        )
        try? fileManager.createDirectory(
            at: importDirectory.appendingPathComponent("completed"),
            withIntermediateDirectories: true
        )

        // Initialize with empty state first
        self.stagedData = StagedData()
        self.validation = ValidationState()

        // Then try to resume from existing file
        if let resumed = try? resumeActiveImport() {
            self.stagedData = resumed.stagedData
            self.currentStep = resumed.currentStep
            self.validation = resumed.validation
        }

        // Start auto-save
        startAutoSave()
    }

    deinit {
        autoSaveTimer?.invalidate()
    }

    // MARK: - Persistence

    /// Save current state to active_import.json
    public func save() throws {
        let state = ImportState(
            version: "1.0",
            created: stagedData.created,
            lastModified: Date(),
            currentStep: currentStep.rawValue,
            status: .inProgress,
            staged: stagedData,
            validation: validation
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(state)
        try data.write(to: activeImportURL)

        isDirty = false
        lastSaved = Date()
    }

    /// Resume from active import file
    private func resumeActiveImport() throws -> (
        stagedData: StagedData,
        currentStep: WizardStep,
        validation: ValidationState
    ) {
        guard fileManager.fileExists(atPath: activeImportURL.path) else {
            throw ImportError.noActiveImport
        }

        let data = try Data(contentsOf: activeImportURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let state = try decoder.decode(ImportState.self, from: data)

        guard state.version == "1.0" else {
            throw ImportError.unsupportedVersion(state.version)
        }

        return (
            stagedData: state.staged,
            currentStep: WizardStep(rawValue: state.currentStep) ?? .values,
            validation: state.validation
        )
    }

    /// Mark state as dirty (needs save)
    public func markDirty() {
        isDirty = true
    }

    // MARK: - Draft Management

    /// Save as named draft
    public func saveAsDraft(name: String) throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "\(timestamp)_\(name).json"
        let draftURL = importDirectory.appendingPathComponent("drafts").appendingPathComponent(filename)

        let state = ImportState(
            version: "1.0",
            created: stagedData.created,
            lastModified: Date(),
            currentStep: currentStep.rawValue,
            status: .draft,
            staged: stagedData,
            validation: validation
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(state)
        try data.write(to: draftURL)
    }

    // MARK: - Auto-Save

    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isDirty else { return }

            Task { @MainActor in
                do {
                    try self.save()
                    print("✓ Auto-saved import state")
                } catch {
                    print("⚠️ Auto-save failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Wizard Steps

public enum WizardStep: Int, CaseIterable {
    case values = 1
    case measures = 2
    case goals = 3
    case actions = 4
    case review = 5
    case commit = 6

    public func next() -> WizardStep {
        WizardStep(rawValue: self.rawValue + 1) ?? self
    }

    public func previous() -> WizardStep {
        WizardStep(rawValue: self.rawValue - 1) ?? self
    }
}

// MARK: - Errors

public enum ImportError: Error {
    case noActiveImport
    case unsupportedVersion(String)
}

// TODO: Implement draft loading
// TODO: Implement archive completed imports
// TODO: Add method to list all drafts
