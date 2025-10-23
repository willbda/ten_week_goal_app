//  ModelAvailability.swift
//  Checks and monitors Foundation Models availability
//
//  Written by Claude Code on 2025-10-23
//
//  This @MainActor @Observable class monitors whether the on-device LLM
//  is available for use. It provides graceful degradation - when the model
//  is unavailable, the AI chat feature simply doesn't appear in the UI.

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Monitors the availability of the on-device language model
///
/// This class checks whether Apple's Foundation Models framework is available
/// and whether Apple Intelligence is enabled. The UI can observe this state
/// to conditionally show/hide AI-powered features.
///
/// Example:
/// ```swift
/// @State private var modelChecker = ModelAvailability.shared
///
/// var body: some View {
///     if modelChecker.isAvailable {
///         // Show AI chat icon
///     }
/// }
/// ```
@available(macOS 26.0, *)
@MainActor
@Observable
public final class ModelAvailability {

    // MARK: - Shared Instance

    /// Singleton instance for app-wide model availability checking
    public static let shared = ModelAvailability()

    // MARK: - Properties

    /// Whether the model is currently available for use
    public private(set) var isAvailable: Bool = false

    /// Human-readable reason if model is unavailable
    public private(set) var unavailableReason: String?

    /// Detailed availability status from the framework
    public private(set) var availabilityStatus: String = "Checking..."

    // MARK: - Private Properties

    #if canImport(FoundationModels)
    /// Reference to the system language model
    private var model: SystemLanguageModel?
    #endif

    /// Timer for periodic availability checks
    private var checkTimer: Timer?

    // MARK: - Initialization

    private init() {
        // Initial check
        checkAvailability()

        // Set up periodic checks (every 30 seconds)
        // This handles cases where user enables Apple Intelligence while app is running
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                self.checkAvailability()
            }
        }
    }

    deinit {
        MainActor.assumeIsolated {
            checkTimer?.invalidate()
        }
    }

    // MARK: - Public Methods

    /// Manually trigger an availability check
    public func refresh() {
        checkAvailability()
    }

    // MARK: - Private Methods

    /// Check if the Foundation Models framework is available
    private func checkAvailability() {
        #if canImport(FoundationModels)
        // Get reference to the system model
        if model == nil {
            model = SystemLanguageModel.default
        }

        guard let model = model else {
            isAvailable = false
            unavailableReason = "Model not initialized"
            availabilityStatus = "Not initialized"
            return
        }

        // Check availability status
        switch model.availability {
        case .available:
            isAvailable = true
            unavailableReason = nil
            availabilityStatus = "Available"

        case .unavailable(.deviceNotEligible):
            isAvailable = false
            unavailableReason = "Device not eligible (requires M1+ Mac)"
            availabilityStatus = "Device not eligible"

        case .unavailable(.appleIntelligenceNotEnabled):
            isAvailable = false
            unavailableReason = "Apple Intelligence not enabled in System Settings"
            availabilityStatus = "Apple Intelligence disabled"

        case .unavailable(.modelNotReady):
            isAvailable = false
            unavailableReason = "Model downloading or preparing..."
            availabilityStatus = "Model not ready"

        case .unavailable(let other):
            isAvailable = false
            unavailableReason = "Unavailable: \(other)"
            availabilityStatus = "Unavailable"

        @unknown default:
            isAvailable = false
            unavailableReason = "Unknown availability status"
            availabilityStatus = "Unknown"
        }
        #else
        // Foundation Models not available (pre-macOS 26.0)
        isAvailable = false
        unavailableReason = "Requires macOS 26.0 or later"
        availabilityStatus = "OS version too old"
        #endif
    }
}

/// Convenience wrapper for pre-macOS 15.1 compatibility
///
/// This allows the rest of the app to compile on macOS 15.0
/// while still checking for AI availability at runtime.
@MainActor
@Observable
public final class AIAssistantAvailability {

    public static let shared = AIAssistantAvailability()

    public var isAvailable: Bool {
        if #available(macOS 26.0, *) {
            return ModelAvailability.shared.isAvailable
        } else {
            return false
        }
    }

    public var statusMessage: String {
        if #available(macOS 26.0, *) {
            return ModelAvailability.shared.availabilityStatus
        } else {
            return "Requires macOS 26.0+"
        }
    }

    private init() {}
}