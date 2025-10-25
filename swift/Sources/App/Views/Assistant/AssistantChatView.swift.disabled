// AssistantChatView.swift
// Main AI assistant chat interface
//
// Written by Claude Code on 2025-10-23
//
// This view provides the conversation interface for the on-device AI assistant,
// displaying messages, handling user input, and managing the chat session.

import SwiftUI

/// Main chat interface for the AI assistant
///
/// Displays the conversation history, provides text input, and manages
/// the overall chat experience with typing indicators and error states.
///
/// The view automatically initializes the conversation service when it appears
/// and provides controls for clearing the conversation.
public struct AssistantChatView: View {

    // MARK: - State

    @State private var viewModel = ConversationViewModel()
    @FocusState private var isInputFocused: Bool
    @State private var scrollToBottom = false
    @Namespace private var bottomAnchor

    // MARK: - Initialization

    public init() {}

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            // Message list
            messageList

            // Divider
            Divider()

            // Input area
            inputArea
        }
        .navigationTitle("AI Assistant")
        .toolbar {
            toolbarContent
        }
        .task {
            await viewModel.initialize()
            // Focus input after initialization
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            scrollToBottom = true
        }
        .animation(.smooth, value: viewModel.messages.count)
    }

    // MARK: - Message List

    @ViewBuilder
    private var messageList: some View {
        if viewModel.isInitialized {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageRow(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        // Invisible anchor for scrolling to bottom
                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchor)
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                .scrollContentBackground(.hidden)
                .background(ContentMaterials.listRow)
                .onChange(of: scrollToBottom) { _, shouldScroll in
                    if shouldScroll {
                        withAnimation(.smooth) {
                            proxy.scrollTo(bottomAnchor, anchor: .bottom)
                        }
                        scrollToBottom = false
                    }
                }
            }
        } else {
            // Loading or error state
            VStack(spacing: DesignSystem.Spacing.lg) {
                if viewModel.errorMessage != nil {
                    errorView
                } else {
                    loadingView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ContentMaterials.listRow)
        }
    }

    // MARK: - Input Area

    @ViewBuilder
    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: DesignSystem.Spacing.sm) {
            // Text field
            TextField("Ask about your goals and progress...", text: $viewModel.currentPrompt, axis: .vertical)
                .textFieldStyle(.plain)
                .font(DesignSystem.Typography.body)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
                .disabled(!viewModel.isInitialized || viewModel.isLoading)

            // Send button
            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: viewModel.isLoading ? "ellipsis.circle" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(viewModel.canSendMessage ? .indigo : Color.secondary.opacity(0.5))
                    .symbolEffect(.pulse, isActive: viewModel.isLoading)
                    .animation(.smooth, value: viewModel.isLoading)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSendMessage)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(DesignSystem.Spacing.md)
        .background(ContentMaterials.form)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            // Status indicator
            if !viewModel.availabilityStatus.isEmpty && viewModel.availabilityStatus != "Ready" {
                Text(viewModel.availabilityStatus)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            // Clear conversation
            Button {
                Task {
                    await viewModel.clearConversation()
                }
            } label: {
                Label("Clear Conversation", systemImage: "trash")
            }
            .disabled(!viewModel.isInitialized || viewModel.messages.isEmpty)
        }
    }

    // MARK: - Status Views

    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .indigo))

            Text("Initializing AI Assistant...")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.secondary)

            Text(viewModel.availabilityStatus)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var errorView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Error icon
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.error.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(DesignSystem.Colors.error)
            }

            // Error message
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("Unable to Initialize")
                    .font(DesignSystem.Typography.headline)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                }
            }

            // Retry button
            Button("Try Again") {
                Task {
                    await viewModel.initialize()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }
}

// MARK: - Preview

#Preview {
    AssistantChatView()
        .frame(width: 800, height: 600)
}