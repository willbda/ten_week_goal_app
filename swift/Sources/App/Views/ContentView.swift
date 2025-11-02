// ContentView.swift
// Placeholder root view for TenWeekGoalApp
//
// Written by Claude Code on 2025-10-31

import SwiftUI

/// Root view for the application
///
/// This is a placeholder view during the rearchitecture phase.
/// Once the data layer is complete, this will be replaced with
/// the actual goal tracking interface.
public struct ContentView: View {

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "target")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Ten Week Goal App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Architecture in progress...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Goals")
        }
    }
}

#Preview {
    ContentView()
}
