//
// HealthDashboardTestView.swift
// Written by Claude Code on 2025-11-08
//
// PURPOSE:
// Simple test view to verify HealthKit live tracking integration.
// Displays real-time step count, distance, and active energy with minimal UI.
//
// USAGE:
// Add to your app's navigation or ContentView:
// ```swift
// NavigationLink("Health Dashboard") {
//     HealthDashboardTestView()
// }
// ```
//
// TODO: Replace with full Liquid Glass UI in Phase 7 (Views)
//

import SwiftUI
import Services

/// Minimal test view for HealthKit live tracking
///
/// **Purpose**: Verify that HealthKitLiveTrackingService + HealthDashboardViewModel
/// work correctly before building full Liquid Glass UI.
///
/// **What this tests**:
/// - HealthKit authorization flow
/// - Real-time step count updates
/// - Real-time distance updates
/// - Real-time active energy updates
/// - Query lifecycle (start/stop on appear/disappear)
///
/// **How to test on iOS Simulator**:
/// 1. Open Health app on simulator
/// 2. Tap "Browse" → "Activity" → "Steps"
/// 3. Tap "Add Data" → enter step count → "Add"
/// 4. This view should update automatically (within 2-3 seconds)
public struct HealthDashboardTestView: View {
    @State private var viewModel = HealthDashboardViewModel()

    public var body: some View {
        List {
            // Authorization section
            Section {
                authorizationStatus
            } header: {
                Text("HealthKit Status")
            }

            // Metrics section
            if viewModel.authorizationStatus == .authorized {
                Section {
                    metricRow(
                        icon: "figure.walk",
                        label: "Steps",
                        value: viewModel.formattedDailySteps,
                        detail: "Goal: \(viewModel.formattedStepGoal)"
                    )

                    metricRow(
                        icon: "map",
                        label: "Distance",
                        value: viewModel.formattedDistance,
                        detail: nil
                    )

                    metricRow(
                        icon: "flame.fill",
                        label: "Active Energy",
                        value: viewModel.formattedActiveEnergy,
                        detail: nil
                    )
                } header: {
                    HStack {
                        Text("Today's Metrics")
                        Spacer()
                        if viewModel.isTracking {
                            LiveIndicator()
                        }
                    }
                } footer: {
                    Text("Last updated: \(viewModel.formattedLastUpdated)")
                        .font(.caption)
                }

                // Progress section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Step Progress")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(viewModel.stepProgressPercentage * 100))%")
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }

                        ProgressView(value: viewModel.stepProgressPercentage)
                            .tint(.blue)

                        if viewModel.hasReachedStepGoal {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("Goal reached!")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Error section
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            // Debug section
            Section {
                debugInfo
            } header: {
                Text("Debug Info")
            }
        }
        .navigationTitle("Health Tracking Test")
        .task {
            // Request authorization and start tracking when view appears
            await viewModel.requestAuthorizationAndStart()
        }
        .onDisappear {
            // Stop tracking when view disappears (battery conservation)
            viewModel.stopLiveTracking()
        }
    }

    // MARK: - Subviews

    private var authorizationStatus: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            VStack(alignment: .leading) {
                Text("Authorization Status")
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.authorizationStatus == .notDetermined {
                Button("Enable") {
                    Task {
                        await viewModel.requestAuthorizationAndStart()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func metricRow(icon: String, label: String, value: String, detail: String?) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue.gradient)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(label)
                    .font(.headline)
                if let detail = detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
        }
    }

    private var debugInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            debugRow(label: "Is Tracking", value: "\(viewModel.isTracking)")
            debugRow(label: "Steps (raw)", value: "\(viewModel.dailySteps)")
            debugRow(label: "Distance (raw)", value: String(format: "%.3f km", viewModel.dailyDistance))
            debugRow(label: "Energy (raw)", value: String(format: "%.1f kcal", viewModel.activeEnergy))
            debugRow(label: "Last Updated", value: viewModel.lastUpdated.formatted(date: .omitted, time: .standard))
        }
        .font(.caption)
        .monospaced()
    }

    private func debugRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    // MARK: - Computed Properties

    private var statusIcon: String {
        switch viewModel.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .unavailable:
            return .gray
        }
    }

    private var statusText: String {
        switch viewModel.authorizationStatus {
        case .authorized:
            return "Authorized - live tracking active"
        case .denied:
            return "Denied - enable in Settings → Health → Data Access"
        case .notDetermined:
            return "Not determined - tap Enable to authorize"
        case .unavailable:
            return "HealthKit not available on this device"
        }
    }
}

// MARK: - Live Indicator Component

struct LiveIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
                .opacity(isAnimating ? 1.0 : 0.3)

            Text("LIVE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Authorized") {
    NavigationStack {
        HealthDashboardTestView()
    }
}

#Preview("Not Determined") {
    NavigationStack {
        HealthDashboardTestView()
    }
}
