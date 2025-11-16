//
// WorkoutDetailView.swift
// Written by Claude Code on 2025-11-05
//
// PURPOSE:
// Detailed view showing all data for a single workout from HealthKit
//

#if os(iOS)
import SwiftUI
import HealthKit
import Services  // HealthWorkout moved to Services/HealthKit/Models/

/// Detailed view of a single workout showing all available data
public struct WorkoutDetailView: View {
    let workout: HealthWorkout

    public init(workout: HealthWorkout) {
        self.workout = workout
    }

    public var body: some View {
        List {
            // Activity Section
            Section {
                HStack {
                    Image(systemName: workout.iconName)
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.activityName)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Time Section
            Section("Duration & Timing") {
                LabeledRow(label: "Duration", value: workout.formattedDuration)
                LabeledRow(label: "Start Time", value: formattedTime(workout.startDate))
                LabeledRow(label: "End Time", value: formattedTime(workout.endDate))
            }

            // Metrics Section
            if workout.totalDistance != nil || workout.totalEnergyBurned != nil {
                Section("Metrics") {
                    if let distance = workout.formattedDistance {
                        LabeledRow(label: "Distance", value: distance, icon: "figure.walk")
                    }

                    if let calories = workout.formattedCalories {
                        LabeledRow(label: "Energy Burned", value: calories, icon: "flame.fill")
                    }

                    if let pace = calculatePace() {
                        LabeledRow(label: "Average Pace", value: pace, icon: "speedometer")
                    }
                }
            }

            // Summary Section
            Section("Summary") {
                Text(workout.summaryLine)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            // Raw Data Section (for debugging/completeness)
            Section("Technical Details") {
                LabeledRow(label: "Activity Type", value: String(describing: workout.activityType))
                LabeledRow(label: "Workout ID", value: workout.id.uuidString)
            }
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        // FIX: Add bottom safe area inset for iOS 26 floating tab bar
        // The "Liquid Glass" tab bar floats above content, so we need to ensure
        // scrollable content doesn't get occluded by it
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: workout.startDate)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func calculatePace() -> String? {
        guard let distance = workout.totalDistance, distance > 0 else { return nil }

        let kilometers = distance / 1000.0
        let paceMinutesPerKm = workout.duration / 60.0 / kilometers

        let minutes = Int(paceMinutesPerKm)
        let seconds = Int((paceMinutesPerKm - Double(minutes)) * 60)

        return String(format: "%d:%02d /km", minutes, seconds)
    }
}

// MARK: - Supporting Views

private struct LabeledRow: View {
    let label: String
    let value: String
    var icon: String? = nil

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }

            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Running Workout") {
    NavigationStack {
        WorkoutDetailView(
            workout: HealthWorkout(
                startDate: Date().addingTimeInterval(-1800),
                endDate: Date(),
                activityType: .running,
                duration: 1800,
                totalDistance: 5200,
                totalEnergyBurned: 387
            )
        )
    }
}

#Preview("Yoga Workout") {
    NavigationStack {
        WorkoutDetailView(
            workout: HealthWorkout(
                startDate: Date().addingTimeInterval(-2400),
                endDate: Date(),
                activityType: .yoga,
                duration: 2400,
                totalDistance: nil,
                totalEnergyBurned: 150
            )
        )
    }
}

#else
// MARK: - macOS Stub

import SwiftUI
import Services  // HealthWorkout moved to Services/HealthKit/Models/

public struct WorkoutDetailView: View {
    let workout: HealthWorkout

    public init(workout: HealthWorkout) {
        self.workout = workout
    }

    public var body: some View {
        Text("HealthKit not available on macOS")
            .navigationTitle("Workout Details")
    }
}
#endif
