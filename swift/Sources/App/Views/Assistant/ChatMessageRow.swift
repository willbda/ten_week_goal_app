// ChatMessageRow.swift
// Individual message bubble component for chat interface
//
// Written by Claude Code on 2025-10-23
//
// This view displays a single message in the chat interface with appropriate
// styling for user vs AI messages, typing indicators, and timestamps.

import SwiftUI

/// Displays a single message in the chat interface
///
/// Renders messages with different styling based on whether they're from
/// the user or AI, includes typing indicators for loading states, and
/// shows timestamps on hover.
public struct ChatMessageRow: View {

    // MARK: - Properties

    let message: ChatMessage

    // MARK: - State

    @State private var showTimestamp = false
    @State private var isHovering = false
    @State private var typingDots = 0

    // MARK: - Body

    public var body: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.sm) {
            if message.isUser {
                Spacer(minLength: 60)
                userMessage
            } else {
                aiMessage
                Spacer(minLength: 60)
            }
        }
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - User Message

    @ViewBuilder
    private var userMessage: some View {
        VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxs) {
            // Timestamp (when hovering)
            if isHovering {
                Text(message.shortTime)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.tertiary)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Message bubble
            HStack {
                Text(message.text)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.indigo)
                    )
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - AI Message

    @ViewBuilder
    private var aiMessage: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(.indigo.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                    .foregroundStyle(.indigo)
            }

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                // Timestamp (when hovering)
                if isHovering {
                    Text(message.shortTime)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                // Message bubble or typing indicator
                if message.isLoading {
                    typingIndicator
                } else {
                    messageBubble
                }
            }
        }
    }

    @ViewBuilder
    private var messageBubble: some View {
        Text(message.text)
            .font(DesignSystem.Typography.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ContentMaterials.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                    )
            )
            .textSelection(.enabled)
    }

    // MARK: - Typing Indicator

    @ViewBuilder
    private var typingIndicator: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(.indigo.opacity(typingDots == index ? 1.0 : 0.3))
                    .frame(width: 8, height: 8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: typingDots
                    )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ContentMaterials.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation {
                typingDots = 2
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func messageContextMenu(for text: String) -> some View {
        Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        }

        Divider()

        Button("Copy with Timestamp") {
            let timestampedText = "[\(message.formattedTime)] \(text)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(timestampedText, forType: .string)
        }
    }
}

// MARK: - Preview

#Preview("User Message") {
    ChatMessageRow(
        message: ChatMessage(
            text: "What made July so meaningful for me?",
            isUser: true
        )
    )
    .padding()
    .frame(width: 600)
}

#Preview("AI Message") {
    ChatMessageRow(
        message: ChatMessage(
            text: "Looking at your July activities, I can see you completed several important goals. Your 'Daily 5k Run' goal shows consistent progress with 18 logged runs, and you also started working on your 'Learn Swift' milestone. This combination of physical activity and learning seems to align well with your values of health and personal growth.",
            isUser: false
        )
    )
    .padding()
    .frame(width: 600)
}

#Preview("Loading Message") {
    ChatMessageRow(
        message: ChatMessage(
            text: "",
            isUser: false,
            isLoading: true
        )
    )
    .padding()
    .frame(width: 600)
}