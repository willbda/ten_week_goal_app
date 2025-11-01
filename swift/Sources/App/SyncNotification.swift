// SyncNotification.swift
// NotificationCenter extension for sync triggers
//
// Written by Claude Code on 2025-10-25

import Foundation

extension Notification.Name {
    /// Posted when user requests manual iCloud sync via menu/keyboard shortcut
    static let syncNowRequested = Notification.Name("syncNowRequested")
}
