import Models
import SQLiteData
import SwiftUI

// ARCHITECTURE DECISION: Why @FetchAll instead of ViewModel?
// CONTEXT: Evaluated different patterns for fetching data in list views
// OPTIONS CONSIDERED:
//   A. ViewModel with @Published values array (Repository pattern)
//   B. @FetchAll directly in View (SwiftUI + SQLiteData pattern)
//   C. @Query from SwiftData (if we were using SwiftData instead of SQLiteData)
// WHY @FetchAll:
//   - Reactive updates: Values automatically refresh when database changes
//   - Minimal boilerplate: No ViewModel needed for simple lists
//   - Type-safe: Query defined at compile-time (PersonalValue.all)
//   - Memory efficient: SQLiteData handles pagination under the hood
// WHEN TO USE VIEWMODEL INSTEAD:
//   - Complex filtering/sorting logic
//   - Multi-source data aggregation
//   - Business logic coordination
// SEE: ActionListView for example of list WITH ViewModel (complex filtering)

public struct PersonalValuesListView: View {
    // Fetching all PersonalValues from the database
    @FetchAll(wrappedValue: [], PersonalValue.all)
    private var values

    @State private var showingAddValue = false
    @State private var valueToEdit: PersonalValue?
    @State private var valueToDelete: PersonalValue?
    @State private var selectedValue: PersonalValue?  // For keyboard navigation

    public init() {}

    // Computed property to avoid layout recursion
    private var groupedValues: [ValueLevel: [PersonalValue]] {
        Dictionary(grouping: values, by: \PersonalValue.valueLevel)
    }

    public var body: some View {
        Group {
            if values.isEmpty {
                // Empty state
                ContentUnavailableView {
                    Label("No Values Yet", systemImage: "heart")
                } description: {
                    Text("Define what matters to you by adding your first personal value")
                } actions: {
                    Button("Add Value") {
                        showingAddValue = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    // PERFORMANCE FIX (2025-11-03):
                    // Previous: Filtered values 4 times on EVERY render (O(n × 4))
                    // Current: Dictionary grouping once, lookup per level (O(n) + O(1) lookups)
                    // Database: Already sorted by valueLevel + priority via ORDER BY
                    ForEach(ValueLevel.allCases, id: \.self) { level in
                        if let levelValues = groupedValues[level], !levelValues.isEmpty {
                            Section(level.displayName) {
                                ForEach(levelValues) { value in
                                    PersonalValuesRowView(value: value)
                                        .onTapGesture {
                                            edit(value)
                                        }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                valueToDelete = value
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                edit(value)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                        // Context menu for mouse/trackpad users
                                        .contextMenu {
                                            Button {
                                                edit(value)
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }

                                            Divider()

                                            Button(role: .destructive) {
                                                valueToDelete = value
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Values")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddValue = true
                } label: {
                    Label("Add Value", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingAddValue) {
            NavigationStack {
                PersonalValuesFormView()
            }
        }
        .sheet(item: $valueToEdit) { value in
            NavigationStack {
                PersonalValuesFormView(valueToEdit: value)
            }
        }
        .alert(
            "Delete Value",
            isPresented: .constant(valueToDelete != nil),
            presenting: valueToDelete
        ) { value in
            Button("Cancel", role: .cancel) {
                valueToDelete = nil
            }
            Button("Delete", role: .destructive) {
                delete(value)
            }
        } message: { value in
            Text("Are you sure you want to delete '\(value.title ?? "this value")'?")
        }
    }

    // MARK: - Actions

    private func edit(_ value: PersonalValue) {
        valueToEdit = value
    }

    private func delete(_ value: PersonalValue) {
        Task {
            // Create temporary ViewModel for delete operation
            let viewModel = PersonalValuesFormViewModel()
            do {
                try await viewModel.delete(value: value)
                valueToDelete = nil
            } catch {
                // Error handled by ViewModel.errorMessage
                // Could show alert here if needed
                print("Delete error: \(error)")
                valueToDelete = nil
            }
        }
    }
}
