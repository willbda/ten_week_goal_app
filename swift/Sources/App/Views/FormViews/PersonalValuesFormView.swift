// //  2. ValueFormView ❌ MISSING (High Priority)

// //   Why needed: UI for creating PersonalValues

// //   What it would do:
// //   public struct ValueFormView: View {
// //       @StateObject private var viewModel: ValueFormViewModel

// //       @State private var title: String = ""
// //       @State private var selectedLevel: ValueLevel = .general
// //       @State private var priority: Int = 50
// //       @State private var description: String = ""
// //       @State private var notes: String = ""
// //       @State private var lifeDomain: String = ""
// //       @State private var alignmentGuidance: String = ""

// //       @Environment(\.dismiss) private var dismiss

// //       var body: some View {
// //           Form {
// //               Section("Basic Information") {
// //                   TextField("Title", text: $title)

// //                   Picker("Level", selection: $selectedLevel) {
// //                       ForEach(ValueLevel.allCases, id: \.self) { level in
// //                           Text(level.rawValue.capitalized).tag(level)
// //                       }
// //                   }

// //                   Stepper("Priority: \(priority)", value: $priority, in: 1...100)
// //               }

// //               Section("Details") {
// //                   TextField("Description", text: $description, axis: .vertical)
// //                   TextField("Life Domain", text: $lifeDomain)
// //                   TextField("Alignment Guidance", text: $alignmentGuidance, axis: .vertical)
// //               }

// //               Section("Notes") {
// //                   TextField("Freeform Notes", text: $notes, axis: .vertical)
// //               }
// //           }
// //           .navigationTitle("New Value")
// //           .toolbar {
// //               ToolbarItem(placement: .confirmationAction) {
// //                   Button("Save") {
// //                       Task {
// //                           do {
// //                               _ = try await viewModel.save(
// //                                   title: title,
// //                                   level: selectedLevel,
// //                                   priority: priority,
// //                                   description: description.isEmpty ? nil : description,
// //                                   notes: notes.isEmpty ? nil : notes,
// //                                   lifeDomain: lifeDomain.isEmpty ? nil : lifeDomain,
// //                                   alignmentGuidance: alignmentGuidance.isEmpty ? nil : alignmentGuidance
// //                               )
// //                               dismiss()
// //                           } catch {
// //                               // Error already set in viewModel
// //                           }
// //                       }
// //                   }
// //                   .disabled(title.isEmpty || viewModel.isSaving)
// //               }

// //               ToolbarItem(placement: .cancellationAction) {
// //                   Button("Cancel") {
// //                       dismiss()
// //                   }
// //               }
// //           }
// //           .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
// //               Button("OK") {
// //                   viewModel.errorMessage = nil
// //               }
// //           } message: {
// //               if let error = viewModel.errorMessage {
// //                   Text(error)
// //               }
// //           }
// //       }
// //   }

//  Step 1: PersonalValueFormViewModel (~30 min)

//   Pattern: Use SQLiteData's dependency injection

//   import Foundation
//   import SwiftUI
//   import SQLiteData
//   import Models

//   ---
//   Step 2: PersonalValuesFormView (~45 min)

//   Pattern: Use FormScaffold template like ActionFormView

//   import SwiftUI
//   import Models

//   public struct PersonalValuesFormView: View {
//       @StateObject private var viewModel = PersonalValueFormViewModel()
//       @Environment(\.dismiss) private var dismiss

//       // Form state
//       @State private var title: String = ""
//       @State private var selectedLevel: ValueLevel = .general
//       @State private var priority: Int = 50
//       @State private var description: String = ""
//       @State private var notes: String = ""
//       @State private var lifeDomain: String = ""
//       @State private var alignmentGuidance: String = ""

//       public init() {}

//       public var body: some View {
//           FormScaffold(
//               title: "New Value",
//               canSubmit: !title.isEmpty && !viewModel.isSaving,
//               onSubmit: handleSubmit,
//               onCancel: { dismiss() }
//           ) {
//               DocumentableFields(
//                   title: $title,
//                   detailedDescription: $description,
//                   freeformNotes: $notes
//               )

//               Section("Value Properties") {
//                   Picker("Level", selection: $selectedLevel) {
//                       ForEach(ValueLevel.allCases, id: \.self) { level in
//                           Text(level.displayName).tag(level)
//                       }
//                   }

//                   Stepper("Priority: \(priority)", value: $priority, in: 1...100)
//               }

//               Section("Context") {
//                   TextField("Life Domain", text: $lifeDomain)
//                   TextField("Alignment Guidance", text: $alignmentGuidance, axis: .vertical)
//                       .lineLimit(3...6)
//               }

//               if let error = viewModel.errorMessage {
//                   Section {
//                       Text(error)
//                           .foregroundStyle(.red)
//                   }
//               }
//           }
//       }

//       private func handleSubmit() {
//           Task {
//               do {
//                   _ = try await viewModel.save(
//                       title: title,
//                       level: selectedLevel,
//                       priority: priority,
//                       description: description.isEmpty ? nil : description,
//                       notes: notes.isEmpty ? nil : notes,
//                       lifeDomain: lifeDomain.isEmpty ? nil : lifeDomain,
//                       alignmentGuidance: alignmentGuidance.isEmpty ? nil : alignmentGuidance
//                   )
//                   dismiss()
//               } catch {
//                   // Error already set in viewModel
//               }
//           }
//       }
//   }

//   ---
