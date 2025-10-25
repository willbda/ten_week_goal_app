// GoalProgressActivity.swift
// Live Activities for goal progress tracking
//
// Written by Claude Code on 2025-10-24

#if os(iOS)
import SwiftUI
import ActivityKit

// MARK: - Activity Attributes

@available(iOS 16.1, *)
public struct GoalProgressAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentProgress: Double
        var targetAmount: Double
        var unit: String
        var lastUpdated: Date

        public var percentComplete: Double {
            guard targetAmount > 0 else { return 0 }
            return min(currentProgress / targetAmount * 100, 100)
        }

        public var remaining: Double {
            max(targetAmount - currentProgress, 0)
        }
    }

    // Static attributes that don't change
    public var goalTitle: String
    public var goalID: String
    public var goalIcon: String
    public var goalColor: String // Hex color for Dynamic Island
}

// MARK: - Live Activity Configuration

@available(iOS 16.1, *)
public struct GoalProgressLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoalProgressAttributes.self) { context in
            // Lock Screen view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island configurations
            DynamicIsland {
                // Expanded view
                expandedView(context: context)
            } compactLeading: {
                // Compact leading (left side when collapsed)
                compactLeadingView(context: context)
            } compactTrailing: {
                // Compact trailing (right side when collapsed)
                compactTrailingView(context: context)
            } minimal: {
                // Minimal view (when multiple activities)
                minimalView(context: context)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(
        context: ActivityViewContext<GoalProgressAttributes>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: context.attributes.goalIcon)
                    .foregroundStyle(colorFromHex(context.attributes.goalColor))

                Text(context.attributes.goalTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text("\(Int(context.state.percentComplete))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(.quaternary)

                    // Progress fill
                    Capsule()
                        .fill(
                            colorFromHex(context.attributes.goalColor).gradient
                        )
                        .frame(
                            width: geometry.size.width * (context.state.percentComplete / 100)
                        )
                }
            }
            .frame(height: 8)

            // Stats
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progress")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(formatNumber(context.state.currentProgress)) \(context.state.unit)")
                        .font(.caption.bold())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text("\(formatNumber(context.state.remaining)) \(context.state.unit)")
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Dynamic Island - Expanded View

    @ViewBuilder
    private func expandedView(
        context: ActivityViewContext<GoalProgressAttributes>
    ) -> some View {
        DynamicIslandExpandedRegion(.leading) {
            // Left side - Icon and title
            HStack(spacing: 8) {
                Image(systemName: context.attributes.goalIcon)
                    .font(.title2)
                    .foregroundStyle(colorFromHex(context.attributes.goalColor))

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.goalTitle)
                        .font(.headline)
                        .lineLimit(1)

                    Text("\(formatNumber(context.state.currentProgress)) / \(formatNumber(context.state.targetAmount)) \(context.state.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }

        DynamicIslandExpandedRegion(.trailing) {
            // Right side - Percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(context.state.percentComplete))%")
                    .font(.title2.bold())
                    .foregroundStyle(colorFromHex(context.attributes.goalColor))

                Text("complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }

        DynamicIslandExpandedRegion(.center) {
            // Center - Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.quaternary)

                        Capsule()
                            .fill(colorFromHex(context.attributes.goalColor).gradient)
                            .frame(
                                width: geometry.size.width * (context.state.percentComplete / 100)
                            )
                    }
                }
                .frame(height: 6)
                .padding(.horizontal)
            }
        }

        DynamicIslandExpandedRegion(.bottom) {
            // Bottom - Action buttons
            HStack(spacing: 12) {
                Button {
                    // TODO: Deep link to log progress
                } label: {
                    Label("Log Progress", systemImage: "plus.circle.fill")
                        .font(.caption.bold())
                }
                .tint(colorFromHex(context.attributes.goalColor))

                Button {
                    // TODO: Deep link to goal detail
                } label: {
                    Label("View Details", systemImage: "chart.bar.fill")
                        .font(.caption.bold())
                }
                .tint(.secondary)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Dynamic Island - Compact Leading

    @ViewBuilder
    private func compactLeadingView(
        context: ActivityViewContext<GoalProgressAttributes>
    ) -> some View {
        Image(systemName: context.attributes.goalIcon)
            .foregroundStyle(colorFromHex(context.attributes.goalColor))
    }

    // MARK: - Dynamic Island - Compact Trailing

    @ViewBuilder
    private func compactTrailingView(
        context: ActivityViewContext<GoalProgressAttributes>
    ) -> some View {
        Text("\(Int(context.state.percentComplete))%")
            .font(.caption.bold())
            .foregroundStyle(colorFromHex(context.attributes.goalColor))
    }

    // MARK: - Dynamic Island - Minimal

    @ViewBuilder
    private func minimalView(
        context: ActivityViewContext<GoalProgressAttributes>
    ) -> some View {
        Image(systemName: context.attributes.goalIcon)
            .foregroundStyle(colorFromHex(context.attributes.goalColor))
    }

    // MARK: - Helpers

    private func colorFromHex(_ hex: String) -> Color {
        var cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanedHex = cleanedHex.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        return Color(red: r, green: g, blue: b)
    }

    private func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Live Activity Manager

@available(iOS 16.1, *)
public class GoalProgressActivityManager {
    public static let shared = GoalProgressActivityManager()

    private init() {}

    /// Start live activity for a goal
    public func startActivity(
        goalID: String,
        title: String,
        icon: String = "target",
        color: String = "#FF9500", // Orange default
        currentProgress: Double,
        targetAmount: Double,
        unit: String
    ) async throws -> Activity<GoalProgressAttributes> {
        let attributes = GoalProgressAttributes(
            goalTitle: title,
            goalID: goalID,
            goalIcon: icon,
            goalColor: color
        )

        let initialState = GoalProgressAttributes.ContentState(
            currentProgress: currentProgress,
            targetAmount: targetAmount,
            unit: unit,
            lastUpdated: Date()
        )

        let activity = try Activity.request(
            attributes: attributes,
            content: .init(state: initialState, staleDate: nil),
            pushType: nil
        )

        return activity
    }

    /// Update existing live activity
    public func updateActivity(
        _ activity: Activity<GoalProgressAttributes>,
        currentProgress: Double
    ) async {
        let updatedState = GoalProgressAttributes.ContentState(
            currentProgress: currentProgress,
            targetAmount: activity.content.state.targetAmount,
            unit: activity.content.state.unit,
            lastUpdated: Date()
        )

        await activity.update(
            .init(state: updatedState, staleDate: nil)
        )
    }

    /// End live activity
    public func endActivity(
        _ activity: Activity<GoalProgressAttributes>,
        dismissPolicy: ActivityUIDismissalPolicy = .default
    ) async {
        await activity.end(
            .init(state: activity.content.state, staleDate: nil),
            dismissalPolicy: dismissPolicy
        )
    }

    /// Get all active goal progress activities
    public var activeActivities: [Activity<GoalProgressAttributes>] {
        Activity<GoalProgressAttributes>.activities
    }

    /// Find activity by goal ID
    public func findActivity(forGoalID goalID: String) -> Activity<GoalProgressAttributes>? {
        Activity<GoalProgressAttributes>.activities.first {
            $0.attributes.goalID == goalID
        }
    }
}

// MARK: - Usage Example

/*
 // Start a live activity for a goal
 Task {
     do {
         let activity = try await GoalProgressActivityManager.shared.startActivity(
             goalID: goal.id.uuidString,
             title: "Complete 50km running",
             icon: "figure.run",
             color: "#FF9500",
             currentProgress: 26.0,
             targetAmount: 50.0,
             unit: "km"
         )

         print("Live activity started: \(activity.id)")
     } catch {
         print("Failed to start live activity: \(error)")
     }
 }

 // Update progress
 Task {
     if let activity = GoalProgressActivityManager.shared.findActivity(forGoalID: goalID) {
         await GoalProgressActivityManager.shared.updateActivity(
             activity,
             currentProgress: 30.0
         )
     }
 }

 // End activity when goal is complete
 Task {
     if let activity = GoalProgressActivityManager.shared.findActivity(forGoalID: goalID) {
         await GoalProgressActivityManager.shared.endActivity(
             activity,
             dismissPolicy: .after(.seconds(5)) // Auto-dismiss after 5 seconds
         )
     }
 }
 */

#endif
