//
// GoalProgressDashboardViewTEMP.swift
// Written by Claude Code on 2025-11-10
//
// PURPOSE:
// Dashboard view for goal progress tracking - vertical slice demonstration.
// Shows the complete data flow from repository → service → viewmodel → view.
//
// NOTE: "TEMP" suffix indicates this is an MVP implementation.
// Production version will have enhanced visualizations and animations.
//
// ARCHITECTURE:
// **PERMANENT PATTERNS**:
// - @State with @Observable ViewModel
// - .task for async data loading
// - Composition of smaller view components
//
// **TEMPORARY ELEMENTS**:
// - Basic progress rings (will add animations)
// - Simple list layout (will add grid options)
// - Basic colors (will integrate Liquid Glass design system)
//

import SwiftUI
import Models
import Services  // For GoalProgress, DashboardStats, ProgressStatus types

/// Main dashboard view for goal progress
///
/// **PERMANENT PATTERN**: View structure and data flow
/// **TEMPORARY**: Basic UI components (marked for enhancement)
public struct GoalProgressDashboardViewTEMP: View {

    // MARK: - State

    /// ViewModel manages all dashboard state
    /// **PERMANENT PATTERN**: @State with @Observable (not @StateObject)
    @State var viewModel = GoalProgressViewModel()

    // MARK: - Initialization

    /// Default initializer creates its own viewModel
    public init() {}

    /// Preview initializer accepts custom viewModel
    /// Used by SwiftUI previews to inject mock data
    init(viewModel: GoalProgressViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            if viewModel.isLoading && viewModel.goalProgress.isEmpty {
                // Loading state
                loadingView
            } else if viewModel.goalProgress.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Content
                dashboardContent
            }
        }
        .navigationTitle("Goal Progress")
        .task {
            // **PERMANENT PATTERN**: Load data on appear
            await viewModel.loadGoalProgress()
        }
        .refreshable {
            // **PERMANENT PATTERN**: Pull-to-refresh
            await viewModel.refresh()
        }
    }

    // MARK: - Content Views

    /// Main dashboard content
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary section
                if let stats = viewModel.dashboardStats {
                    DashboardSummaryCardTEMP(stats: stats)
                        .padding(.horizontal)
                }

                // Filter bar
                filterBar
                    .padding(.horizontal)

                // Goals list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.goalProgress) { goal in
                        GoalProgressCardTEMP(goal: goal)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    /// Filter and sort controls
    ///
    /// **TEMPORARY**: Basic filters
    /// **FUTURE**: Advanced filtering by term, value, date range
    private var filterBar: some View {
        HStack {
            // Filter toggle
            Toggle("Behind Only", isOn: Binding(
                get: { viewModel.showOnlyBehind },
                set: { _ in viewModel.toggleBehindFilter() }
            ))
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .tint(viewModel.showOnlyBehind ? .orange : .gray)

            Spacer()

            // Sort picker
            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        viewModel.updateSort(option)
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.sortBy == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
    }

    /// Loading state view
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading goals...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Goals Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first goal to start tracking progress")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // TODO: Add "Create Goal" button when form is ready
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Component Views

/// Dashboard summary card
///
/// **TEMPORARY**: Basic stats display
/// **FUTURE**: Add charts and trends
struct DashboardSummaryCardTEMP: View {
    let stats: DashboardStats

    var body: some View {
        VStack(spacing: 16) {
            // Overall progress
            HStack {
                Text("Overall Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(stats.overallCompletionPercent))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                        .frame(
                            width: geometry.size.width * (stats.overallCompletionPercent / 100),
                            height: 8
                        )
                }
            }
            .frame(height: 8)

            // Stats grid
            HStack(spacing: 20) {
                StatItemTEMP(
                    label: "Total",
                    value: "\(stats.totalGoals)",
                    color: .primary
                )

                StatItemTEMP(
                    label: "Complete",
                    value: "\(stats.completedGoals)",
                    color: .green
                )

                StatItemTEMP(
                    label: "On Track",
                    value: "\(stats.onTrackGoals)",
                    color: .blue
                )

                StatItemTEMP(
                    label: "Behind",
                    value: "\(stats.behindGoals)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(red: 0.95, green: 0.95, blue: 0.97))  // systemGray6 equivalent
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Individual stat item
struct StatItemTEMP: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Individual goal progress card
///
/// **TEMPORARY**: Basic card with progress ring
/// **FUTURE**: Add sparkline charts, velocity indicators
struct GoalProgressCardTEMP: View {
    let goal: GoalProgress

    var body: some View {
        HStack(spacing: 16) {
            // Progress ring
            ProgressRingViewTEMP(
                progress: goal.percentComplete / 100,
                color: Color(goal.statusColor)
            )
            .frame(width: 60, height: 60)

            // Goal details
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Label("\(Int(goal.currentProgress)) / \(Int(goal.targetValue)) \(goal.measureUnit)",
                          systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let days = goal.daysRemaining {
                        if days >= 0 {
                            Label("\(days) days left", systemImage: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("\(abs(days)) days overdue", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }

                // Status badge
                HStack {
                    StatusBadgeTEMP(status: goal.status)

                    if goal.isUrgent {
                        Label("Urgent", systemImage: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Chevron for detail (future)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .imageScale(.small)
        }
        .padding()
        .background(Color.white)  // systemBackground equivalent for light mode
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

/// Status badge component
struct StatusBadgeTEMP: View {
    let status: ProgressStatus

    var statusColor: Color {
        switch status {
        case .complete: return .green
        case .onTrack: return .blue
        case .behind: return .orange
        case .overdue: return .red
        case .notStarted: return .gray
        }
    }

    var statusIcon: String {
        switch status {
        case .complete: return "checkmark.circle.fill"
        case .onTrack: return "arrow.forward.circle"
        case .behind: return "exclamationmark.circle"
        case .overdue: return "xmark.circle"
        case .notStarted: return "circle"
        }
    }

    var body: some View {
        Label(status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
              systemImage: statusIcon)
            .font(.caption2)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.1))
            .clipShape(Capsule())
    }
}

/// Simple progress ring view
///
/// **TEMPORARY**: Basic ring without animation
/// **FUTURE**: Add smooth animations, gradient fills
struct ProgressRingViewTEMP: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                ))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.3), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Previews

#Preview("Dashboard with Data") {
    GoalProgressDashboardViewTEMP(viewModel: .preview)
        .environment(\.locale, .init(identifier: "en_US"))
}

#Preview("Dashboard Empty") {
    GoalProgressDashboardViewTEMP(viewModel: .previewEmpty)
}

#Preview("Dashboard Loading") {
    GoalProgressDashboardViewTEMP(viewModel: .previewLoading)
}

// MARK: - Implementation Notes

// VIEW ARCHITECTURE (PERMANENT PATTERNS)
//
// This demonstrates the production view patterns:
// 1. @State with @Observable ViewModel (not @StateObject)
// 2. .task for async data loading
// 3. Composition of smaller view components
// 4. Conditional rendering based on state
// 5. Pull-to-refresh with .refreshable
//
// DATA FLOW:
// 1. View appears → .task calls viewModel.loadGoalProgress()
// 2. ViewModel coordinates repository + service
// 3. @Observable properties update
// 4. SwiftUI automatically re-renders
//
// TEMPORARY ELEMENTS (marked with TEMP suffix):
// - Basic progress rings (will add animations)
// - Simple cards (will add charts)
// - Basic colors (will use Liquid Glass design system)
// - Static layout (will add grid/list toggle)
//
// PERMANENT PATTERNS:
// - View/ViewModel separation
// - Component composition
// - State-driven UI
// - Async data loading pattern