//
// CommitStep.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Wizard step UI for importing data
// UI: Input area, parse button, preview table, validation display
//

import SwiftUI
import Services

public struct CommitStep: View {
    @Bindable var state: ImportWizardState

    public var body: some View {
        ContentUnavailableView {
            Label("Step 6: Commit", systemImage: "square.and.arrow.down")
        } description: {
            Text("Save imported data to database")
        } actions: {
            Text("Coming soon...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Commit Import")
    }
}
