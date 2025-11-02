//
// DateGrouping.swift
// Utilities for grouping items by date categories
//
// Written by Claude Code on 2025-11-01
//
// PURPOSE:
// Provides date-based grouping for entity lists (Today, Yesterday, This Week, etc.)
// Generic implementation works with any item that has a Date property.
//
// DESIGN:
// - Groups: Today, Yesterday, This Week, Last Week, Earlier
// - Uses Calendar for proper date calculations (respects DST, time zones)
// - Generic over any item type via KeyPath
// - Returns array of DateGroup sections for List display
//
// TODO: @Agent1 - DateGroup struct may move to ComponentContracts.swift when created

import Foundation
import SwiftUI

// MARK: - DateGroup Model

/// A group of items sharing a date category
///
/// Used to organize entity lists by temporal proximity (Today, Yesterday, etc.)
///
/// **Usage**:
/// ```swift
/// let groups = DateGrouping.groupByDate(actions, dateKeyPath: \.logTime)
/// ForEach(groups) { group in
///     Section(group.title) {
///         ForEach(group.items) { item in
///             // Row view
///         }
///     }
/// }
/// ```
public struct DateGroup<Item>: Identifiable {
    public let id = UUID()
    public let title: String
    public let items: [Item]

    public init(title: String, items: [Item]) {
        self.title = title
        self.items = items
    }
}

// MARK: - DateGrouping Utility

/// Utilities for date-based grouping
public enum DateGrouping {

    // MARK: - Public API

    /// Groups items by date proximity
    ///
    /// Categories:
    /// - **Today**: Same calendar day as now
    /// - **Yesterday**: Previous calendar day
    /// - **This Week**: Same week as now (excluding Today/Yesterday)
    /// - **Last Week**: Previous week
    /// - **Earlier**: Before last week
    ///
    /// - Parameters:
    ///   - items: Array of items to group
    ///   - dateKeyPath: KeyPath to the Date property on each item
    /// - Returns: Array of DateGroup sections, ordered chronologically (newest first)
    ///
    /// **Example**:
    /// ```swift
    /// struct Action { let id: UUID; let logTime: Date }
    /// let actions: [Action] = [...]
    /// let groups = DateGrouping.groupByDate(actions, dateKeyPath: \.logTime)
    /// ```
    public static func groupByDate<T>(
        _ items: [T],
        dateKeyPath: KeyPath<T, Date>
    ) -> [DateGroup<T>] {
        let calendar = Calendar.current
        let now = Date()

        // Define date boundaries
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!

        // Categorize items
        var today: [T] = []
        var yesterday: [T] = []
        var thisWeek: [T] = []
        var lastWeek: [T] = []
        var earlier: [T] = []

        for item in items {
            let itemDate = item[keyPath: dateKeyPath]

            if itemDate >= todayStart {
                today.append(item)
            } else if itemDate >= yesterdayStart {
                yesterday.append(item)
            } else if itemDate >= thisWeekStart {
                thisWeek.append(item)
            } else if itemDate >= lastWeekStart {
                lastWeek.append(item)
            } else {
                earlier.append(item)
            }
        }

        // Build groups (only include non-empty)
        var groups: [DateGroup<T>] = []

        if !today.isEmpty {
            groups.append(DateGroup(title: "Today", items: today))
        }
        if !yesterday.isEmpty {
            groups.append(DateGroup(title: "Yesterday", items: yesterday))
        }
        if !thisWeek.isEmpty {
            groups.append(DateGroup(title: "This Week", items: thisWeek))
        }
        if !lastWeek.isEmpty {
            groups.append(DateGroup(title: "Last Week", items: lastWeek))
        }
        if !earlier.isEmpty {
            groups.append(DateGroup(title: "Earlier", items: earlier))
        }

        return groups
    }

    // MARK: - Helper Functions

    /// Formats a date as a human-readable relative string
    ///
    /// - Parameter date: The date to format
    /// - Returns: String like "Today at 2:30 PM", "Yesterday at 9:00 AM", "Mar 15 at 3:45 PM"
    ///
    /// **Example**:
    /// ```swift
    /// DateGrouping.formatRelativeDate(Date()) // "Today at 2:30 PM"
    /// ```
    public static func formatRelativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        if date >= todayStart {
            return "Today at \(timeFormatter.string(from: date))"
        } else if date >= yesterdayStart {
            return "Yesterday at \(timeFormatter.string(from: date))"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d 'at' h:mm a"
            return dateFormatter.string(from: date)
        }
    }

    /// Calculates the days between two dates
    ///
    /// - Parameters:
    ///   - from: Start date
    ///   - to: End date
    /// - Returns: Number of days (positive if `to` is after `from`)
    ///
    /// **Example**:
    /// ```swift
    /// let start = Date()
    /// let end = Date.daysFromNow(7)
    /// DateGrouping.daysBetween(from: start, to: end) // 7
    /// ```
    public static func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
}

// MARK: - Previews

// Preview Helper: Test Item Model
private struct DateGroupingTestItem: Identifiable {
    let id = UUID()
    let date: Date
    let title: String
}

#Preview("Empty Array") {
    let items: [DateGroupingTestItem] = []
    let groups = DateGrouping.groupByDate(items, dateKeyPath: \.date)

    List {
        if groups.isEmpty {
            Text("No items")
                .foregroundStyle(.secondary)
        } else {
            ForEach(groups) { group in
                Section(group.title) {
                    ForEach(group.items) { item in
                        Text("Item")
                    }
                }
            }
        }
    }
}

#Preview("All Groups Present") {
    let calendar = Calendar.current
    let items: [DateGroupingTestItem] = [
        // Today
        DateGroupingTestItem(date: Date(), title: "Today Item 1"),
        DateGroupingTestItem(date: calendar.date(byAdding: .hour, value: -6, to: Date())!, title: "Today Item 2"),

        // Yesterday
        DateGroupingTestItem(date: Date.daysFromNow(-1), title: "Yesterday Item 1"),
        DateGroupingTestItem(date: calendar.date(byAdding: .hour, value: -30, to: Date())!, title: "Yesterday Item 2"),

        // This Week
        DateGroupingTestItem(date: Date.daysFromNow(-3), title: "This Week Item 1"),
        DateGroupingTestItem(date: Date.daysFromNow(-5), title: "This Week Item 2"),

        // Last Week
        DateGroupingTestItem(date: Date.daysFromNow(-8), title: "Last Week Item 1"),
        DateGroupingTestItem(date: Date.daysFromNow(-12), title: "Last Week Item 2"),

        // Earlier
        DateGroupingTestItem(date: Date.daysFromNow(-20), title: "Earlier Item 1"),
        DateGroupingTestItem(date: Date.daysFromNow(-45), title: "Earlier Item 2")
    ]

    let groups = DateGrouping.groupByDate(items, dateKeyPath: \.date)

    List {
        ForEach(groups) { group in
            Section(group.title) {
                ForEach(group.items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(DateGrouping.formatRelativeDate(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("Only Today") {
    let calendar = Calendar.current
    let items: [DateGroupingTestItem] = [
        DateGroupingTestItem(date: Date(), title: "Morning"),
        DateGroupingTestItem(date: calendar.date(byAdding: .hour, value: -6, to: Date())!, title: "Afternoon"),
        DateGroupingTestItem(date: calendar.date(byAdding: .hour, value: -12, to: Date())!, title: "Evening")
    ]

    let groups = DateGrouping.groupByDate(items, dateKeyPath: \.date)

    List {
        ForEach(groups) { group in
            Section(group.title) {
                ForEach(group.items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(DateGrouping.formatRelativeDate(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("Midnight Boundary Edge Cases") {
    let calendar = Calendar.current
    let todayStart = calendar.startOfDay(for: Date())
    let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!

    let items: [DateGroupingTestItem] = [
        // Just after midnight today
        DateGroupingTestItem(date: calendar.date(byAdding: .minute, value: 1, to: todayStart)!, title: "12:01 AM Today"),

        // Just before midnight today
        DateGroupingTestItem(date: calendar.date(byAdding: .minute, value: -1, to: todayStart)!, title: "11:59 PM Yesterday"),

        // Exactly midnight yesterday
        DateGroupingTestItem(date: yesterdayStart, title: "12:00 AM Yesterday")
    ]

    let groups = DateGrouping.groupByDate(items, dateKeyPath: \.date)

    List {
        ForEach(groups) { group in
            Section(group.title) {
                ForEach(group.items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(DateGrouping.formatRelativeDate(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("Week Boundary Edge Cases") {
    let calendar = Calendar.current
    let now = Date()
    let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
    let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart)!

    let items: [DateGroupingTestItem] = [
        // Start of this week
        DateGroupingTestItem(date: thisWeekStart, title: "This Week Start"),

        // Just before this week (end of last week)
        DateGroupingTestItem(date: calendar.date(byAdding: .minute, value: -1, to: thisWeekStart)!, title: "Last Week End"),

        // Start of last week
        DateGroupingTestItem(date: lastWeekStart, title: "Last Week Start"),

        // Just before last week (earlier)
        DateGroupingTestItem(date: calendar.date(byAdding: .minute, value: -1, to: lastWeekStart)!, title: "Earlier")
    ]

    let groups = DateGrouping.groupByDate(items, dateKeyPath: \.date)

    List {
        ForEach(groups) { group in
            Section(group.title) {
                ForEach(group.items) { item in
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(DateGrouping.formatRelativeDate(item.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview("Realistic Data - Actions") {
    let calendar = Calendar.current
    let actions: [DateGroupingTestItem] = [
        DateGroupingTestItem(date: Date(), title: "Morning Run"),
        DateGroupingTestItem(date: calendar.date(byAdding: .hour, value: -12, to: Date())!, title: "Write Documentation"),
        DateGroupingTestItem(date: Date.daysFromNow(-1), title: "Team Meeting"),
        DateGroupingTestItem(date: calendar.date(byAdding: .hour, value: -30, to: Date())!, title: "Code Review"),
        DateGroupingTestItem(date: Date.daysFromNow(-4), title: "Project Planning"),
        DateGroupingTestItem(date: Date.daysFromNow(-6), title: "Client Call"),
        DateGroupingTestItem(date: Date.daysFromNow(-9), title: "Sprint Retrospective"),
        DateGroupingTestItem(date: Date.daysFromNow(-11), title: "Quarterly Review"),
        DateGroupingTestItem(date: Date.daysFromNow(-25), title: "Conference Attendance"),
        DateGroupingTestItem(date: Date.daysFromNow(-40), title: "Workshop Facilitation")
    ]

    let groups = DateGrouping.groupByDate(actions, dateKeyPath: \.date)

    List {
        ForEach(groups) { group in
            Section(group.title) {
                ForEach(group.items) { action in
                    VStack(alignment: .leading) {
                        Text(action.title)
                            .font(.headline)
                        Text(DateGrouping.formatRelativeDate(action.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

#Preview("Helper Functions") {
    VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
            Text("formatRelativeDate Examples")
                .font(.headline)

            Text(DateGrouping.formatRelativeDate(Date()))
            Text(DateGrouping.formatRelativeDate(Date.daysFromNow(-1)))
            Text(DateGrouping.formatRelativeDate(Date.daysFromNow(-5)))
            Text(DateGrouping.formatRelativeDate(Date.daysFromNow(-30)))
        }

        Divider()

        VStack(alignment: .leading, spacing: 8) {
            Text("daysBetween Examples")
                .font(.headline)

            Text("Today to +7 days: \(DateGrouping.daysBetween(from: Date(), to: Date.daysFromNow(7))) days")
            Text("Today to -7 days: \(DateGrouping.daysBetween(from: Date(), to: Date.daysFromNow(-7))) days")
            Text("Today to today: \(DateGrouping.daysBetween(from: Date(), to: Date())) days")
        }
    }
    .padding()
}
