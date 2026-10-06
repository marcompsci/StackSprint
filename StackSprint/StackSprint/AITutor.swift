import Foundation
import FoundationModels
import SwiftUI

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    var text: String
    enum Role { case user, assistant }
}

// MARK: - Tutor View Model

@Observable @MainActor final class TutorViewModel {
    var messages: [ChatMessage] = []
    var isGenerating = false
    var streamingText = ""
    var errorMessage: String?

    private var session: LanguageModelSession?

    func resetSession() {
        session = LanguageModelSession(instructions: """
            You are Bit, a friendly AI coding tutor inside StackSprint. \
            Help learners understand coding concepts concisely and encouragingly. \
            Keep answers under 120 words. Use simple language. \
            Show a short code snippet when helpful. \
            Never discuss topics outside software development and learning.
            """)
    }

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if session == nil { resetSession() }
        guard let session else { return }

        messages.append(ChatMessage(role: .user, text: trimmed))
        isGenerating = true
        streamingText = ""
        errorMessage = nil

        do {
            let stream = session.streamResponse(to: trimmed)
            for try await partial in stream {
                streamingText = partial.content
            }
            messages.append(ChatMessage(role: .assistant, text: streamingText))
            streamingText = ""
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            resetSession()
            errorMessage = "Conversation reset (context full). Please ask again."
        } catch {
            errorMessage = error.localizedDescription
        }
        isGenerating = false
    }
}

// MARK: - AI Tutor View

struct AITutorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = TutorViewModel()
    @State private var input = ""
    @FocusState private var inputFocused: Bool

    private let model = SystemLanguageModel.default

    var body: some View {
        NavigationStack {
            modelBody
                .navigationTitle("Bit AI Tutor")
                .navigationBarTitleDisplayMode(.inline)
                .modifier(SprintTheme())
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }

    @ViewBuilder
    private var modelBody: some View {
        switch model.availability {
        case .available:
            chatView
        case .unavailable(.appleIntelligenceNotEnabled):
            unavailableView("Apple Intelligence is off",
                detail: "Go to Settings \u{2192} Apple Intelligence & Siri and turn it on.",
                icon: "brain.head.profile")
        case .unavailable(.deviceNotEligible):
            unavailableView("Device not supported",
                detail: "Bit AI Tutor requires a device that supports Apple Intelligence.",
                icon: "iphone.slash")
        case .unavailable(.modelNotReady):
            unavailableView("Model downloading",
                detail: "The on-device model is downloading. Try again in a minute.",
                icon: "arrow.down.circle")
        case .unavailable:
            unavailableView("Not available",
                detail: "Bit AI Tutor is not available right now.",
                icon: "exclamationmark.triangle")
        }
    }

    private var chatView: some View {
        VStack(spacing: 0) {
            messageList
            Divider()
            inputBar
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if vm.messages.isEmpty { welcomeCard }
                    ForEach(vm.messages) { msg in
                        ChatBubble(message: msg).id(msg.id)
                    }
                    if vm.isGenerating && !vm.streamingText.isEmpty {
                        ChatBubble(message: ChatMessage(role: .assistant, text: vm.streamingText))
                            .id("streaming")
                    }
                    if vm.isGenerating && vm.streamingText.isEmpty {
                        ThinkingDots().id("thinking").padding(.leading, 8)
                    }
                    if let err = vm.errorMessage {
                        Text(err).font(.caption).foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(16)
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: vm.streamingText) { _, _ in
                withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
            }
            .onChange(of: vm.isGenerating) { _, generating in
                if generating { withAnimation { proxy.scrollTo("thinking", anchor: .bottom) } }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything about code\u{2026}", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 18))
            Button {
                let text = input
                input = ""
                Task { await vm.send(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(input.trimmingCharacters(in: .whitespaces).isEmpty ? Color.secondary : Color.mint)
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isGenerating)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var welcomeCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.mint.opacity(0.12)).frame(width: 80, height: 80)
                BiteAvatar().frame(width: 56, height: 80)
            }
            Text("Hi! I\u{2019}m Bit.").font(.system(.title2, design: .rounded, weight: .bold))
            Text("Ask me anything about code \u{2014} concepts, syntax, errors, or what to learn next.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .padding(.horizontal)
            VStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button(prompt) { Task { await vm.send(prompt) } }
                        .font(.subheadline)
                        .padding(.horizontal, 16).padding(.vertical, 9)
                        .background(SprintPalette.card, in: Capsule())
                        .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity).padding(.top, 28)
    }

    private func unavailableView(_ title: String, detail: String, icon: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 52)).foregroundStyle(.secondary)
            Text(title).font(.title2.bold())
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private let quickPrompts = [
        "What is a closure in Swift?",
        "Explain async/await simply",
        "What\u{2019}s the difference between a struct and a class?",
    ]
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                ZStack {
                    Circle().fill(Color.mint.opacity(0.12)).frame(width: 32, height: 32)
                    BiteAvatar().frame(width: 22, height: 32)
                }
            } else {
                Spacer(minLength: 60)
            }
            Text(message.text)
                .font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(message.role == .user ? Color.mint.opacity(0.18) : SprintPalette.card,
                            in: RoundedRectangle(cornerRadius: 18))
                .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
            if message.role == .user {
                Circle().fill(Color.mint.opacity(0.25)).frame(width: 32, height: 32)
                    .overlay(Image(systemName: "person.fill").font(.caption).foregroundStyle(.mint))
            } else {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Thinking Dots

private struct ThinkingDots: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(Color.mint).frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.2 : 0.8)
                    .opacity(phase == i ? 1.0 : 0.35)
                    .animation(.easeInOut(duration: 0.25), value: phase)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(350))
                phase = (phase + 1) % 3
            }
        }
    }
}
