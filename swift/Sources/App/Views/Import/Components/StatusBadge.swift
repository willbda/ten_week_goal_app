//
// StatusBadge.swift
// Written by Claude Code on 2025-11-03
//
// PURPOSE: Status indicator for staged data (valid/duplicate/unresolved)
//

import SwiftUI
import Services

public struct StatusBadge: View {
    let status: ResolutionStatus

    public init(status: ResolutionStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)

            Text(displayText)
                .font(.caption)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor.opacity(0.2))
        .foregroundStyle(foregroundColor)
        .cornerRadius(4)
    }

    private var iconName: String {
        switch status {
        case .resolved:
            return "checkmark.circle.fill"
        case .needsResolution:
            return "questionmark.circle.fill"
        case .userChoice:
            return "exclamationmark.triangle.fill"
        }
    }

    private var displayText: String {
        switch status {
        case .resolved:
            return "Resolved"
        case .needsResolution:
            return "Needs Resolution"
        case .userChoice:
            return "Choose Option"
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .resolved:
            return .green
        case .needsResolution:
            return .gray
        case .userChoice:
            return .orange
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .resolved:
            return .green
        case .needsResolution:
            return .gray
        case .userChoice:
            return .orange
        }
    }
}
