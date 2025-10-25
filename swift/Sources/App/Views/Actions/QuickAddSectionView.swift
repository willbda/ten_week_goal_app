// QuickAddSectionView.swift
// Quick access component for creating actions from recent history or active goals
//
// Written by Claude Code on 2025-10-22

import SwiftUI
import Models

/// Quick add section showing recent actions and active goals
///
/// Displays a collapsible section with:
/// - Recent actions (with duplicate buttons)
/// - Active goals (with log action buttons)
struct QuickAddSectionView: View {

    // MARK: - Properties

    /// Recent actions to show
    let recentActions: [Action]

    /// Active goals to show
    let activeGoals: [Goal]

    /// Callback when duplicate action is requested
    let onDuplicateAction: (Action) -> Void

    /// Callback when log action for goal is requested
    let onLogActionForGoal: (Goal) -> Void

    // MARK: - State

    /// Whether the section is expanded
    @AppStorage("quickAddSectionExpanded") private var isExpanded = true

    // MARK: - Body

    var body: some View {
        Section {
            if isExpanded {
                // Recent Actions subsection
                if !recentActions.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Recent Actions")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, DesignSystem.Spacing.sm)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(recentActions.prefix(5)) { action in
                                    QuickActionCard(
                                        title: action.title ?? action.detailedDescription ?? "Untitled",
                                        subtitle: formatActionDetails(action),
                                        icon: "doc.text",
                                        iconColor: .blue,
                                        actionIcon: "plus.square.on.square"
                                    ) {
                                        onDuplicateAction(action)
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }

                // Active Goals subsection
                if !activeGoals.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Active Goals")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.horizontal, DesignSystem.Spacing.sm)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(activeGoals.prefix(5)) { goal in
                                    QuickActionCard(
                                        title: goal.title ?? goal.detailedDescription ?? "Untitled",
                                        subtitle: formatGoalDetails(goal),
                                        icon: "target",
                                        iconColor: .orange,
                                        actionIcon: "plus.circle"
                                    ) {
                                        onLogActionForGoal(goal)
                                    }
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }

                if recentActions.isEmpty && activeGoals.isEmpty {
                    Text("No recent actions or active goals")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
        } header: {
            Button {
                withAnimation(.smooth) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)

                    Text("Quick Add")
                        .font(DesignSystem.Typography.headline)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Formatters

    /// Format action details for display
    private func formatActionDetails(_ action: Action) -> String {
        var details: [String] = []

        // Add measurements
        if !action.measuresByUnit.isEmpty {
            let formatted = action.measuresByUnit.map { String(format: "%.1f %@", $0.value, $0.key) }
            details.append(formatted.joined(separator: ", "))
        }

        // Add duration
        if let duration = action.durationMinutes {
            details.append(String(format: "%.0f min", duration))
        }

        return details.isEmpty ? "No details" : details.joined(separator: " • ")
    }

    /// Format goal details for display
    private func formatGoalDetails(_ goal: Goal) -> String {
        var details: [String] = []

        // Add target
        if let target = goal.measurementTarget, let unit = goal.measurementUnit {
            details.append(String(format: "Target: %.1f %@", target, unit))
        }

        // Add target date
        if let targetDate = goal.targetDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            details.append("Due: \(formatter.string(from: targetDate))")
        }

        return details.isEmpty ? "No target set" : details.joined(separator: " • ")
    }
}

// MARK: - Quick Action Card Component

/// Compact card for horizontal scrolling
private struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let actionIcon: String
    let onTap: () -> Void

    var body: some View {
        let zoom = ZoomManager.shared.zoomLevel

        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack {
                    Image(systemName: icon)
                        .font(DesignSystem.Typography.title3)
                        .foregroundStyle(iconColor)

                    Spacer()

                    Image(systemName: actionIcon)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.white)
                        .frame(width: 22 * zoom, height: 22 * zoom)
                        .background(iconColor)
                        .clipShape(Circle())
                }

                Text(title)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(DesignSystem.Spacing.sm)
            .frame(width: 160 * zoom, height: 100 * zoom, alignment: .topLeading)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("With Content") {
    List {
        QuickAddSectionView(
            recentActions: [
                Action(
                    title: "Morning run",
                    measuresByUnit: ["km": 5.0, "minutes": 30],
                    durationMinutes: 30,
                    logTime: Date()
                ),
                Action(
                    title: "Meditation",
                    durationMinutes: 15,
                    logTime: Date().addingTimeInterval(-3600)
                ),
                Action(
                    title: "Read book",
                    measuresByUnit: ["pages": 25],
                    logTime: Date().addingTimeInterval(-7200)
                )
            ],
            activeGoals: [
                Goal(
                    title: "Run 50km this week",
                    measurementUnit: "km",
                    measurementTarget: 50.0,
                    targetDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())
                ),
                Goal(
                    title: "Meditate daily",
                    measurementUnit: "sessions",
                    measurementTarget: 30,
                    targetDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())
                )
            ],
            onDuplicateAction: { action in
                print("Duplicate: \(action.title ?? "")")
            },
            onLogActionForGoal: { goal in
                print("Log action for: \(goal.title ?? "")")
            }
        )
    }
}

#Preview("Empty") {
    List {
        QuickAddSectionView(
            recentActions: [],
            activeGoals: [],
            onDuplicateAction: { _ in },
            onLogActionForGoal: { _ in }
        )
    }
}
