import Models
import SQLiteData
import SwiftUI

public struct PersonalValuesListView: View {
    @Query private var values: [PersonalValue]
    @State private var showingAddValue = false

    public init() {}

    public var body: some View {
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
                            // TODO: Phase 4 - Add Edit Navigation
                            // PATTERN: NavigationLink { PersonalValuesFormView(mode: .edit(value)) }
                            // REQUIRES: Edit mode support in FormView
                            ValueRowView(value: value)
                        }
                        // TODO: Phase 4 - Add Delete Functionality
                        // .onDelete { indexSet in
                        //     Task { for index in indexSet { try? await viewModel.delete(levelValues[index]) } }
                        // }
                        // REQUIRES: delete() method in ViewModel + Coordinator
                    }
                }
            }
        }
        // TODO: Phase 5 - Add Empty State
        // .overlay {
        //     if values.isEmpty {
        //         ContentUnavailableView("No Values Yet", systemImage: "heart.circle",
        //                               description: Text("Tap + to add your first value"))
        //     }
        // }
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
