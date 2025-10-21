// ValueRowView.swift
// Individual row component for displaying a value
//
// Written by Claude Code on 2025-10-20

import SwiftUI
import Models

/// Row view for displaying a single value
///
/// Displays value details including name, description, priority, and domain.
/// Works with any value type through the ValueDisplayItem protocol.
struct ValueRowView: View {

    // MARK: - Properties

    let item: ValueDisplayItem

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Value name with priority indicator
                HStack {
                    Text(item.friendlyName ?? "Untitled Value")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Priority indicator
                    priorityBadge
                }
                
                // Detailed description
                if let description = item.detailedDescription {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Additional info (like alignment guidance for Major Values)
                if let additionalInfo = item.additionalInfo {
                    Text(additionalInfo)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .italic()
                        .lineLimit(2)
                }
                
                // Life domain tag
                if let domain = item.lifeDomain {
                    HStack {
                        Spacer()
                        Text(domain)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Priority Badge
    
    @ViewBuilder
    private var priorityBadge: some View {
        if item.priority <= 5 {
            Text("★★★")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.yellow)
        } else if item.priority <= 10 {
            Text("★★")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
        } else if item.priority <= 25 {
            Text("★")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        Section("Highest Order Values") {
            ValueRowView(item: ValueDisplayItem(
                id: UUID(),
                friendlyName: "Eudaimonia",
                detailedDescription: "Living a flourishing, meaningful life",
                priority: 1,
                lifeDomain: "Philosophy",
                additionalInfo: nil
            ))
        }
        
        Section("Major Values") {
            ValueRowView(item: ValueDisplayItem(
                id: UUID(),
                friendlyName: "Physical Health",
                detailedDescription: "Maintaining strength, endurance, and vitality",
                priority: 8,
                lifeDomain: "Health",
                additionalInfo: "Exercising regularly, eating well, getting adequate sleep"
            ))
        }
        
        Section("General Values") {
            ValueRowView(item: ValueDisplayItem(
                id: UUID(),
                friendlyName: "Creativity",
                detailedDescription: "Expressing original ideas and making new things",
                priority: 15,
                lifeDomain: "Personal Growth",
                additionalInfo: nil
            ))
            
            ValueRowView(item: ValueDisplayItem(
                id: UUID(),
                friendlyName: "Integrity",
                detailedDescription: "Acting in alignment with principles",
                priority: 12,
                lifeDomain: nil,
                additionalInfo: nil
            ))
        }
        
        Section("Life Areas") {
            ValueRowView(item: ValueDisplayItem(
                id: UUID(),
                friendlyName: "Career",
                detailedDescription: "Professional development and work life",
                priority: 20,
                lifeDomain: nil,
                additionalInfo: nil
            ))
        }
    }
}