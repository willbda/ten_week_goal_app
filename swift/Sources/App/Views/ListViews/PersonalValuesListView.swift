// 3. ValuesListView ❌ MISSING (Medium Priority)

//   Why needed: Display list of PersonalValues, entry point for creating new ones

//   What it would do:
//   public struct ValuesListView: View {
//       @Query private var values: [PersonalValue]
//       @State private var showingAddValue = false

//       var body: some View {
//           List {
//               ForEach(ValueLevel.allCases, id: \.self) { level in
//                   Section(level.rawValue.capitalized) {
//                       ForEach(values.filter { $0.valueLevel == level }) { value in
//                           ValueRowView(value: value)
//                       }
//                   }
//               }
//           }
//           .navigationTitle("Values")
//           .toolbar {
//               Button {
//                   showingAddValue = true
//               } label: {
//                   Label("Add Value", systemImage: "plus")
//               }
//           }
//           .sheet(isPresented: $showingAddValue) {
//               NavigationStack {
//                   ValueFormView(
//                       viewModel: ValueFormViewModel(
//                           coordinator: PersonalValueCoordinator(database: /* ... */)
//                       )
//                   )
//               }
//           }
//       }
//   }

//   Step 3: PersonalValuesListView (~30 min)

//   Pattern: Use SQLiteData @Query macro

//   import SwiftUI
//   import SQLiteData
//   import Models

//   public struct PersonalValuesListView: View {
//       @Query private var values: [PersonalValue]
//       @State private var showingAddValue = false

//       public init() {}

//       public var body: some View {
//           List {
//               ForEach(ValueLevel.allCases, id: \.self) { level in
//                   let levelValues = values.filter { $0.valueLevel == level }
//                   if !levelValues.isEmpty {
//                       Section(level.displayName) {
//                           ForEach(levelValues) { value in
//                               ValueRowView(value: value)
//                           }
//                       }
//                   }
//               }
//           }
//           .navigationTitle("Values")
//           .toolbar {
//               ToolbarItem(placement: .primaryAction) {
//                   Button {
//                       showingAddValue = true
//                   } label: {
//                       Label("Add Value", systemImage: "plus")
//                   }
//               }
//           }
//           .sheet(isPresented: $showingAddValue) {
//               NavigationStack {
//                   PersonalValuesFormView()
//               }
//           }
//       }
//   }

//   ---
