// DemoApp.swift
// Simple SwiftUI demo to showcase the Ten Week Goal App's Action model
//
// This demonstrates the early progress of the Swift port, showing:
// - Action creation and validation
// - Clean domain model structure
// - Cross-platform compatibility

import SwiftUI
import Foundation

// MARK: - Domain Models (Included directly for demo purposes)

/// Base class for all entities with common identification fields
class IndependentEntity {
    var commonName: String
    var id: Int?
    var description: String?
    var notes: String?

    init(
        commonName: String,
        id: Int? = nil,
        description: String? = nil,
        notes: String? = nil
    ) {
        self.commonName = commonName
        self.id = id
        self.description = description
        self.notes = notes
    }
}

/// Base class for entities that can be stored in database
class PersistableEntity: IndependentEntity {
    var logTime: Date

    init(
        commonName: String,
        id: Int? = nil,
        description: String? = nil,
        notes: String? = nil,
        logTime: Date = Date()
    ) {
        self.logTime = logTime
        super.init(
            commonName: commonName,
            id: id,
            description: description,
            notes: notes
        )
    }
}

/// An action taken at a point in time, with optional measurements and timing
class Action: PersistableEntity {
    var measurementUnitsByAmount: [String: Double]?
    var durationMinutes: Double?
    var startTime: Date?

    init(
        commonName: String,
        id: Int? = nil,
        description: String? = nil,
        notes: String? = nil,
        logTime: Date = Date(),
        measurementUnitsByAmount: [String: Double]? = nil,
        durationMinutes: Double? = nil,
        startTime: Date? = nil
    ) {
        self.measurementUnitsByAmount = measurementUnitsByAmount
        self.durationMinutes = durationMinutes
        self.startTime = startTime

        super.init(
            commonName: commonName,
            id: id,
            description: description,
            notes: notes,
            logTime: logTime
        )
    }

    func isValid() -> Bool {
        if let measurements = measurementUnitsByAmount {
            for (_, value) in measurements {
                if value <= 0 {
                    return false
                }
            }
        }

        if startTime != nil && durationMinutes == nil {
            return false
        }

        return true
    }
}

extension Action: Equatable {
    static func == (lhs: Action, rhs: Action) -> Bool {
        lhs.id == rhs.id &&
        lhs.commonName == rhs.commonName &&
        lhs.description == rhs.description &&
        lhs.notes == rhs.notes &&
        lhs.logTime == rhs.logTime &&
        lhs.measurementUnitsByAmount == rhs.measurementUnitsByAmount &&
        lhs.durationMinutes == rhs.durationMinutes &&
        lhs.startTime == rhs.startTime
    }
}

@main
struct TenWeekGoalDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var actions: [Action] = []
    @State private var showingAddAction = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header with app status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ten Week Goal App")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Swift Implementation - Early Development")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("🚧 Demonstrating Action Model & Domain Architecture")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                #if os(iOS)
                    Color(UIColor.systemBackground)
                #else
                    Color(NSColor.controlBackgroundColor)
                #endif
                )
                
                Divider()
                
                // Actions list
                if actions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Actions Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Add your first action to see the domain model in action!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(actions.indices, id: \.self) { index in
                            ActionRow(action: actions[index])
                        }
                        .onDelete(perform: deleteActions)
                    }
                }
                
                // Add button
                Button(action: { showingAddAction = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Action")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddAction) {
            AddActionView { newAction in
                actions.append(newAction)
            }
        }
        .onAppear {
            loadSampleData()
        }
    }
    
    func deleteActions(at offsets: IndexSet) {
        actions.remove(atOffsets: offsets)
    }
    
    func loadSampleData() {
        // Add some sample actions to demonstrate the model
        let sampleActions = [
            Action(
                commonName: "Morning Run",
                description: "Regular morning cardio",
                measurementUnitsByAmount: ["distance_miles": 3.2, "pace_min_per_mile": 8.5],
                durationMinutes: 27.2
            ),
            Action(
                commonName: "Strength Training",
                description: "Upper body workout",
                notes: "Focused on compound movements",
                measurementUnitsByAmount: ["sets": 4.0, "reps_per_set": 8.0],
                durationMinutes: 45.0
            ),
            Action(
                commonName: "Read Philosophy",
                description: "Daily reading session",
                durationMinutes: 30.0
            )
        ]
        
        // Add IDs to simulate database entries
        for (index, action) in sampleActions.enumerated() {
            action.id = index + 1
        }
        
        actions = sampleActions
    }
}

struct ActionRow: View {
    let action: Action
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(action.commonName)
                    .font(.headline)
                
                Spacer()
                
                if let id = action.id {
                    Text("ID: \(id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let description = action.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let measurements = action.measurementUnitsByAmount, !measurements.isEmpty {
                HStack {
                    Image(systemName: "ruler")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(formatMeasurements(measurements))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("Logged: \(formatDate(action.logTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let duration = action.durationMinutes {
                    Spacer()
                    Text("\(Int(duration))min")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            // Show validation status
            HStack {
                Image(systemName: action.isValid() ? "checkmark.circle" : "xmark.circle")
                    .foregroundColor(action.isValid() ? .green : .red)
                Text(action.isValid() ? "Valid" : "Invalid")
                    .font(.caption)
                    .foregroundColor(action.isValid() ? .green : .red)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    func formatMeasurements(_ measurements: [String: Double]) -> String {
        return measurements.map { key, value in
            "\(key): \(String(format: "%.1f", value))"
        }.joined(separator: ", ")
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AddActionView: View {
    @State private var commonName = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var durationMinutes = ""
    @State private var measurements: [(String, String)] = [("", "")]
    
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Action) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Info") {
                    TextField("Action Name", text: $commonName)
                    TextField("Description (optional)", text: $description)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Timing") {
                    TextField("Duration (minutes)", text: $durationMinutes)
                #if os(iOS)
                        .keyboardType(.decimalPad)
                #endif
                }
                
                Section("Measurements") {
                    ForEach(measurements.indices, id: \.self) { index in
                        HStack {
                            TextField("Type (e.g., distance_miles)", text: $measurements[index].0)
                            TextField("Value", text: $measurements[index].1)
                        #if os(iOS)
                                .keyboardType(.decimalPad)
                        #endif
                        }
                    }
                    
                    Button("Add Measurement") {
                        measurements.append(("", ""))
                    }
                }
            }
            .navigationTitle("Add Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        createAction()
                    }
                    .disabled(commonName.isEmpty)
                }
            }
        }
    }
    
    func createAction() {
        // Parse measurements
        var measurementDict: [String: Double]? = nil
        let validMeasurements = measurements.compactMap { (key, value) -> (String, Double)? in
            guard !key.isEmpty, let doubleValue = Double(value), doubleValue > 0 else { return nil }
            return (key, doubleValue)
        }
        
        if !validMeasurements.isEmpty {
            measurementDict = Dictionary(uniqueKeysWithValues: validMeasurements)
        }
        
        // Parse duration
        let duration: Double? = {
            guard !durationMinutes.isEmpty else { return nil }
            return Double(durationMinutes)
        }()
        
        let action = Action(
            commonName: commonName,
            description: description.isEmpty ? nil : description,
            notes: notes.isEmpty ? nil : notes,
            measurementUnitsByAmount: measurementDict,
            durationMinutes: duration
        )
        
        onAdd(action)
        dismiss()
    }
}

#Preview {
    ContentView()
}