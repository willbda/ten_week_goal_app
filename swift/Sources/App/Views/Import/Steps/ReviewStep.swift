//
// ReviewStep.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Wizard step UI for importing data
// UI: Input area, parse button, preview table, validation display
//

import SwiftUI
import Services

public struct ReviewStep: View {
    @Bindable var state: ImportWizardState

    public var body: some View {
        ContentUnavailableView {
            Label("Step 5: Review", systemImage: "eye")
        } description: {
            Text("Review all imported data and resolve any conflicts")
        } actions: {
            VStack(spacing: 8) {
                Text("Summary:")
                    .font(.headline)

                Text("\(state.stagedData.values.count) values")
                Text("\(state.stagedData.measures.count) measures")
                Text("\(state.stagedData.goals.count) goals")
                Text("\(state.stagedData.actions.count) actions")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .navigationTitle("Review Import")
    }
}
