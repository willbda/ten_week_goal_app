// ValuesListView.swift
// Main list view for displaying all values
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// List view displaying all types of values
///
/// Shows values organized by type: Highest Order, Major, General, and Life Areas.
/// Each type is sorted by priority within its section.
public struct ValuesListView: View {

    // MARK: - Initialization

    public init() {}

    // MARK: - State

    /// View model for values management
    @State private var viewModel = ValuesViewModel()

    /// Sheet presentation for adding new value
    @State private var showingAddValue = false

    // MARK: - Body

    public var body: some View {
        contentView(viewModel: viewModel)
            .navigationTitle("Values")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddValue = true
                    } label: {
                        Label("Add Value", systemImage: "plus")
                    }
                }
            }
    }

    // MARK: - Content View

    @ViewBuilder
    private func contentView(viewModel: ValuesViewModel) -> some View {
        if let error = viewModel.error {
            ContentUnavailableView {
                Label("Error Loading Values", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            }
        } else if viewModel.allValuesForDisplay.isEmpty {
            ContentUnavailableView {
                Label("No Values Yet", systemImage: "heart")
            } description: {
                Text("Define what matters to you by adding your first value")
            } actions: {
                Button("Add Value") {
                    showingAddValue = true
                }
            }
        } else {
            List {
                ForEach(viewModel.allValuesForDisplay, id: \.0) { sectionTitle, valueDisplayable in
                    Section(sectionTitle) {
                        ForEach(valueDisplayable.displayItems) { item in
                            ValueRowView(item: item)
                        }
                    }
                }
                
                // Information section about value types
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Value Types")
                            .font(DesignSystem.Typography.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            valueTypeDescription("Highest Order:", "Abstract philosophical ideals")
                            valueTypeDescription("Major Values:", "Actionable values you should regularly see in your goals")
                            valueTypeDescription("General Values:", "Things you believe are worthwhile")
                            valueTypeDescription("Life Areas:", "Domains that structure your life")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func valueTypeDescription(_ title: String, _ description: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .fontWeight(.medium)
            Text(description)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ValuesListView()
    }
}