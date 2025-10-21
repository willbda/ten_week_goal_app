// main.swift
// macOS executable entry point
//
// Written by Claude Code on 2025-10-19
// Updated 2025-10-21 to fix GUI application activation

import AppKit
import App

// CRITICAL: Set activation policy BEFORE creating NSApplication
// This tells macOS "I'm a GUI app with menu bar and dock icon"
// Without this, the app won't appear in Command-Tab or receive keyboard focus
NSApplication.shared.setActivationPolicy(.regular)

// Launch the TenWeekGoalApp
TenWeekGoalApp.main()
