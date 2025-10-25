// ListViewBuilder.swift
// Reusable pattern for entity list views
//
// Written by Claude Code on 2025-10-24
//
// Extracts common patterns from ActionsListView, GoalsListView, TermsListView, ValuesListView
// Uses ViewBuilder to enable declarative, type-safe list view composition

import SwiftUI

// MARK: - ViewModel Protocol

/// Protocol for view models that manage a collection of items
///
/// All list view models (ActionsViewModel, GoalsViewModel, etc.) should conform to this
/// to enable generic list view handling.
///
/// TODO(human): Define the protocol requirements for a list view model.
/// Hint: What properties do ActionsViewModel, GoalsViewModel, TermsViewModel, ValuesViewModel all share?
/// - They all have `isLoading: Bool`
/// - They all have `error: Error?`
/// - They all have a collection of items (actions, goals, terms, values)
///
/// Consider: How do you make the item type generic? (Associated type)
/// Consider: Should there be a `loadItems()` method requirement?
protocol ListViewModel {
    // TODO(human): Add associated type for the item type
    // associatedtype Item: ???

    // TODO(human): Add property requirements
    // var isLoading: Bool { get }
    // var error: Error? { get }
    // var items: [???] { get }  // Use the associated type

    // TODO(human): Add method requirements
    // func loadItems() async
}

// MARK: - Generic List View

/// Generic wrapper for entity list views
///
/// Handles standard patterns:
/// - Loading state (ProgressView)
/// - Error state (ContentUnavailableView with retry)
/// - Empty state (ContentUnavailableView with add button)
/// - Populated state (List with ForEach)
/// - Toolbar with Add button
/// - Sheet presentation for forms
///
/// TODO(human): Implement the generic constraints and ViewBuilder patterns.
///
/// This view should:
/// 1. Be generic over ViewModel (conforming to ListViewModel)
/// 2. Be generic over RowView (some View that displays one item)
/// 3. Use @ViewBuilder for the row content
/// 4. Use @ViewBuilder for optional custom sections
///
/// Think about:
/// - How does ForEach constrain its Item type? (Identifiable)
/// - How do you pass a closure that builds a view from an item?
/// - How do you make sections optional while keeping syntax clean?
// TODO(human): Uncomment and complete generic constraints when implementing
/*
struct EntityListView<ViewModel, RowContent>: View where
    // TODO(human): Add generic constraints
    // ViewModel: ListViewModel,
    // RowContent: View,
    // ViewModel.Item: Identifiable  // So we can use ForEach
{

    // MARK: - Properties

    let viewModel: ViewModel
    let title: String
    let emptyIcon: String
    let emptyMessage: String
    let addButtonTitle: String

    // TODO(human): Add ViewBuilder closures
    // 1. A closure that takes an Item and returns RowContent (the row view)
    // 2. A closure for custom sections (optional, uses @ViewBuilder)
    // 3. A closure for the add button action

    // Hint for the row builder:
    // let rowBuilder: (ViewModel.Item) -> RowContent

    // Hint for custom sections:
    // @ViewBuilder let customSections: () -> CustomSections
    // (Make CustomSections another generic parameter)

    // MARK: - Initialization

    // TODO(human): Create an initializer that takes:
    // - viewModel
    // - title
    // - emptyIcon, emptyMessage, addButtonTitle
    // - @ViewBuilder rowBuilder closure
    // - Optional @ViewBuilder customSections closure
    // - onAdd action closure

    // MARK: - Body

    var body: some View {
        Group {
            // TODO(human): Implement the standard state handling
            // if viewModel.isLoading {
            //     ProgressView("Loading...")
            // } else if let error = viewModel.error {
            //     errorView(error)
            // } else if viewModel.items.isEmpty {
            //     emptyView
            // } else {
            //     contentView
            // }

            Text("TODO: Implement body")
        }
        .navigationTitle(title)
        .toolbar {
            // TODO(human): Add toolbar with Add button
            // ToolbarItem(placement: .primaryAction) {
            //     Button { onAdd() } label: {
            //         Label(addButtonTitle, systemImage: "plus")
            //     }
            // }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        // TODO(human): Implement error ContentUnavailableView with retry button
        // Hint: Look at GoalsListView line 169-180 for the pattern
        Text("TODO: Error view")
    }

    @ViewBuilder
    private var emptyView: some View {
        // TODO(human): Implement empty ContentUnavailableView with add button
        // Hint: Look at GoalsListView line 182-190 for the pattern
        Text("TODO: Empty view")
    }

    @ViewBuilder
    private var contentView: some View {
        // TODO(human): Implement List with ForEach
        // Should include:
        // 1. Custom sections (if provided)
        // 2. ForEach over viewModel.items using the rowBuilder
        // 3. .refreshable { await viewModel.loadItems() }

        // Hint: How do you conditionally include custom sections?
        // Can you call the customSections builder before the main ForEach?

        Text("TODO: Content view")
    }
}
*/

// MARK: - Usage Example (Commented Out)

/*
 How to use EntityListView to replace GoalsListView:

 struct GoalsListView: View {
     @Environment(AppViewModel.self) private var appViewModel
     @State private var viewModel: GoalsViewModel?
     @State private var showingAddGoal = false

     var body: some View {
         Group {
             if let viewModel = viewModel {
                 EntityListView(
                     viewModel: viewModel,
                     title: "Goals",
                     emptyIcon: "target",
                     emptyMessage: "Set your first goal to start tracking your objectives",
                     addButtonTitle: "Add Goal"
                 ) { goal in
                     // Row builder closure
                     GoalRowView(goal: goal)
                 } customSections: {
                     // Custom sections builder
                     if !currentGoals.isEmpty {
                         Section("Current Goals") {
                             ForEach(currentGoals) { goal in
                                 GoalRowView(goal: goal)
                             }
                         }
                     }
                     if !overdueGoals.isEmpty {
                         Section("Overdue Goals") {
                             ForEach(overdueGoals) { goal in
                                 GoalRowView(goal: goal)
                             }
                         }
                     }
                 } onAdd: {
                     showingAddGoal = true
                 }
             }
         }
         .sheet(isPresented: $showingAddGoal) {
             GoalFormView(...)
         }
         .task {
             if let database = appViewModel.databaseManager {
                 viewModel = GoalsViewModel(database: database)
                 await viewModel?.loadGoals()
             }
         }
     }
 }
 */

// MARK: - Design Notes

/*
 Key Decisions to Think About:

 1. **Generic Constraints**
    - ViewModel must conform to ListViewModel
    - ViewModel.Item must be Identifiable (for ForEach)
    - RowContent must be View
    - CustomSections must be View (optional)

 2. **ViewBuilder Closures**
    - Row builder: (Item) -> RowContent
    - Custom sections: @ViewBuilder () -> CustomSections
    - These enable declarative syntax at call site

 3. **Optional Sections**
    - How do you make customSections optional?
    - Option A: Default to EmptyView
    - Option B: Overload initializer (one with sections, one without)
    - Option C: Use Group { } wrapper that accepts optional content

 4. **State Handling**
    - Loading, error, empty, populated states are identical across all views
    - Only difference is the icon/message text

 5. **Actions**
    - Add button action: Simple closure
    - Swipe actions: Could be added as another ViewBuilder parameter
    - Context menus: Could be added as another ViewBuilder parameter

 Benefits of this abstraction:
 - Reduces 180-line views to ~60 lines
 - Enforces consistent UX patterns
 - Type-safe (compiler checks everything)
 - Still declarative (no loss of SwiftUI's readability)

 Tradeoffs:
 - More complex generics (harder to understand initially)
 - Less flexible (harder to customize one-off behaviors)
 - Debugging generics can be harder

 Apple's approach: They provide generic containers (List, ForEach, Group)
 but not higher-level abstractions like "entity list view". This is because
 every app has different patterns. Your app's pattern is very consistent,
 making abstraction worthwhile.
 */
