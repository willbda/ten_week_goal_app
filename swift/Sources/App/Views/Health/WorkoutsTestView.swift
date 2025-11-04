//
// WorkoutsTestView.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE:
// Simple test view to validate HealthKit data flow on iOS.
// Displays workouts for a selected date with authorization handling.
//
// USAGE:
// NavigationStack {
//     WorkoutsTestView()
// }

#if os(iOS)
import SwiftUI
import HealthKit
import Models
import Services

/// Test view for viewing Apple Health workouts
///
/// This is a minimal implementation to validate:
/// - HealthKit authorization flow
/// - Workout data fetching
/// - Data display in SwiftUI
///
/// Future: Expand to full-featured workout viewer with details, charts, etc.
public struct WorkoutsTestView: View {
    @State private var healthManager = HealthKitManager.shared
    @State private var selectedDate: Date = Date()
    @State private var workouts: [HealthWorkout] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    public init() {}

    public var body: some View {
        VStack{
            // Date Picker
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .padding()
            .background(Color(.systemGroupedBackground))
            .onChange(of: selectedDate) { _, newDate in
                Task {
                    await loadWorkouts(for: newDate)
                }
            }



            // Content
            contentView
        }
        .navigationTitle("Workouts")
        .task {
            // Check authorization on appear
            print("📱 WorkoutsTestView appeared - checking status...")
            print("📱 Current authorizationStatus: \(healthManager.authorizationStatus)")
            if healthManager.checkAuthorizationStatus() {
                print("📱 Already authorized, loading workouts...")
                await loadWorkouts(for: selectedDate)
            } else {
                print("📱 Not authorized, status: \(healthManager.authorizationStatus)")
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch healthManager.authorizationStatus {
        case .notDetermined:
            authorizationNeededView
        case .denied:
            deniedView
        case .unavailable:
            unavailableView
        case .authorized:
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if workouts.isEmpty {
                emptyView
            } else {
                workoutsList
            }
        }
    }

    // MARK: - Authorization States

    private var authorizationNeededView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("HealthKit Authorization Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Grant access to view your workout history")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                print("🔘 Grant Access button tapped")
                Task {
                    print("📱 Starting authorization task...")
                    do {
                        print("📱 Calling requestAuthorization...")
                        try await healthManager.requestAuthorization()
                        print("📱 Authorization request completed")
                        // If successful, load workouts
                        if healthManager.authorizationStatus == .authorized {
                            await loadWorkouts(for: selectedDate)
                        }
                    } catch {
                        print("❌ Authorization failed: \(error)")
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Label("Grant Access", systemImage: "lock.open")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var deniedView: some View {
        VStack(spacing: 20) {

            Text("Access Denied")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable HealthKit access in Settings to view workouts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                // Open Settings
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gearshape")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    private var unavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("HealthKit Unavailable")
                .font(.title2)
                .fontWeight(.semibold)

            Text("HealthKit is not available on this device")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Content States

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading workouts...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Error Loading Workouts")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await loadWorkouts(for: selectedDate)
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("No Workouts")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No workouts found for \(formattedDate)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Try selecting a different date or add workouts in the Health app")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    private var workoutsList: some View {
        List {
            Section {
                ForEach(workouts) { workout in
                    WorkoutRowView(workout: workout)
                }
            } header: {
                Text("\(workouts.count) workout\(workouts.count == 1 ? "" : "s") on \(formattedDate)")
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: selectedDate)
    }

    private func loadWorkouts(for date: Date) async {
        guard healthManager.authorizationStatus == HealthKitManager.AuthorizationStatus.authorized else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let hkWorkouts = try await healthManager.fetchWorkouts(for: date)
            workouts = hkWorkouts.map { HealthWorkout(from: $0) }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Workout Row

/// Row view for displaying a single workout
private struct WorkoutRowView: View {
    let workout: HealthWorkout

    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            Image(systemName: workout.iconName)
                .font(.title2)
                .foregroundStyle(.red)
                .frame(width: 40, height: 40)
                .background(Color.red.opacity(0.1))
                .clipShape(Circle())

            // Workout Info
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.activityName)
                    .font(.headline)

                Text(workout.summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: workout.startDate)
        let end = formatter.string(from: workout.endDate)
        return "\(start) - \(end)"
    }
}

// MARK: - Preview

#Preview("With Workouts") {
    NavigationStack {
        WorkoutsTestView()
    }
}

#Preview("Empty State") {
    NavigationStack {
        WorkoutsTestView()
    }
}

#else
// MARK: - macOS Stub

import SwiftUI

public struct WorkoutsTestView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("HealthKit Not Available")
                .font(.title)
                .fontWeight(.bold)

            Text("HealthKit is only available on iOS")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Workouts")
    }
}

#Preview {
    NavigationStack {
        WorkoutsTestView()
    }
}

#endif
