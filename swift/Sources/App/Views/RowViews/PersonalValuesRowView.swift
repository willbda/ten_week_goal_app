// //  4. ValueRowView ❌ MISSING (Low Priority)

// //   Why needed: Display a single PersonalValue in list

// //   What it would do:
// //   public struct ValueRowView: View {
// //       let value: PersonalValue

// //       var body: some View {
// //           VStack(alignment: .leading, spacing: 4) {
// //               HStack {
// //                   Text(value.title ?? "Untitled")
// //                       .font(.headline)

// //                   Spacer()

// //                   if let priority = value.priority {
// //                       Text("\(priority)")
// //                           .font(.caption)
// //                           .foregroundStyle(.secondary)
// //                   }
// //               }

// //               if let description = value.detailedDescription {
// //                   Text(description)
// //                       .font(.caption)
// //                       .foregroundStyle(.secondary)
// //                       .lineLimit(2)
// //               }

// //               if let domain = value.lifeDomain {
// //                   Text(domain)
// //                       .font(.caption2)
// //                       .foregroundStyle(.tertiary)
// //               }
// //           }
// //       }
// //   }

// Step 4: ValueRowView (~15 min)

//   Simple display component:

//   import SwiftUI
//   import Models

//   public struct ValueRowView: View {
//       let value: PersonalValue

//       public init(value: PersonalValue) {
//           self.value = value
//       }

//       public var body: some View {
//           VStack(alignment: .leading, spacing: 4) {
//               HStack {
//                   Text(value.title ?? "Untitled")
//                       .font(.headline)

//                   Spacer()

//                   if let priority = value.priority {
//                       Text("\(priority)")
//                           .font(.caption)
//                           .foregroundStyle(.secondary)
//                           .padding(.horizontal, 8)
//                           .padding(.vertical, 2)
//                           .background(.secondary.opacity(0.15))
//                           .clipShape(Capsule())
//                   }
//               }

//               if let description = value.detailedDescription {
//                   Text(description)
//                       .font(.caption)
//                       .foregroundStyle(.secondary)
//                       .lineLimit(2)
//               }

//               if let domain = value.lifeDomain {
//                   Text(domain)
//                       .font(.caption2)
//                       .foregroundStyle(.tertiary)
//                       .padding(.top, 2)
//               }
//           }
//           .padding(.vertical, 4)
//       }
//   }

//   ---
