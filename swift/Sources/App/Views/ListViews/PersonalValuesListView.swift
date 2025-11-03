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
    @FetchAll(PersonalValue.all) private var values
    @State private var showingAddValue = false

    public init() {}

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
                    // NOTE: Performance - Filtering on Every Render
                    // CURRENT: Filters values array 4 times (once per ValueLevel) on every body evaluation
                    // IMPACT: O(n × 4) complexity, but fine for <500 values
                    // OPTIMIZE: If performance issues arise in Phase 6, use Dictionary(grouping:by:)
                    // ALTERNATIVE: @Query(PersonalValue.order(by: \.valueLevel)) for DB-level sorting
                    ForEach(ValueLevel.allCases, id: \.self) { level in
                        let levelValues = values.filter { $0.valueLevel == level }
                        if !levelValues.isEmpty {
                            Section(level.displayName) {
                                ForEach(levelValues) { value in
                                    // TODO: Phase 4 - Add Edit/Delete (like Terms)
                                    // PATTERN: .onTapGesture for edit, .swipeActions for delete
                                    // REQUIRES: Edit mode support in PersonalValuesFormView
                                    PersonalValuesRowView(value: value)
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
            }
        }
        .sheet(isPresented: $showingAddValue) {
            NavigationStack {
                PersonalValuesFormView()
            }
        }
    }
}
