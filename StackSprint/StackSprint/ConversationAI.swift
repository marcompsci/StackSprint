import Combine
import FoundationModels
import SwiftUI

// MARK: - Practice Mode

enum PracticeMode: String, CaseIterable, Identifiable {
    case general    = "general"
    case interview  = "interview"
    case codeReview = "codeReview"

    var id: String { rawValue }
    var label: String {
        switch self { case .general: return "General"; case .interview: return "Interview"; case .codeReview: return "Code Review" }
    }
    var icon: String {
        switch self { case .general: return "sparkles"; case .interview: return "person.text.rectangle"; case .codeReview: return "curlybraces.square" }
    }
    var systemPrompt: String {
        switch self {
        case .general:
            return """
                You are Bit, an expert coding tutor in StackSprint. \
                Answer questions clearly and concisely. Use code examples where helpful. \
                Format code blocks with triple backticks and the language name.
                """
        case .interview:
            return """
                You are Bit, acting as a technical interviewer in StackSprint. \
                Ask coding interview questions, evaluate answers, give constructive feedback. \
                Start with a medium-difficulty question about data structures or algorithms. \
                When the user answers, give detailed feedback and then ask a follow-up question.
                """
        case .codeReview:
            return """
                You are Bit, a senior code reviewer in StackSprint. \
                When given code, analyze it for bugs, performance, style, and best practices. \
                Be specific and constructive. Suggest improvements with corrected code snippets. \
                If no code is provided yet, ask the user to paste their code.
                """
        }
    }
    var firstMessage: String {
        switch self {
        case .general:    return "Hi! I'm Bit ✨ Ask me anything about code — concepts, syntax, debugging, best practices, or whatever you're stuck on."
        case .interview:  return "Welcome to Interview Practice! I'll act as your technical interviewer. Ready? Let's start with a classic: **What's the difference between a stack and a queue? When would you use each?**"
        case .codeReview: return "Hello! Paste your code and I'll review it for bugs, style, performance, and best practices. I'll also suggest improvements."
        }
    }
}

// MARK: - Chat Message

struct PracticeMessage: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant }
    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date
    let mode: String

    init(id: UUID = .init(), role: Role, content: String, mode: PracticeMode) {
        self.id = id; self.role = role; self.content = content
        self.timestamp = .now; self.mode = mode.rawValue
    }
}

// MARK: - Conversation Store

@MainActor final class BitConversationStore: ObservableObject {
    static let shared = BitConversationStore()

    @Published var messages: [PracticeMessage] = []
    @Published var streamingText = ""
    @Published var isStreaming = false
    @Published var error: String?
    @Published var mode: PracticeMode = .general {
        didSet { if oldValue != mode { resetSession() } }
    }

    private var session: LanguageModelSession?
    private static let historyKey = "ss.practiceChat"
    private static let maxStoredMessages = 50

    init() { loadHistory() }

    // MARK: Send message

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isStreaming else { return }
        guard case .available = SystemLanguageModel.default.availability else {
            error = "On-device AI is not available on this device."; return
        }

        if session == nil { buildSession() }

        let userMsg = PracticeMessage(role: .user, content: trimmed, mode: mode)
        messages.append(userMsg)
        streamingText = ""
        isStreaming = true
        error = nil

        do {
            let stream = session!.streamResponse(to: trimmed)
            for try await partial in stream {
                streamingText = partial.content
            }
            let assistantMsg = PracticeMessage(role: .assistant, content: streamingText, mode: mode)
            messages.append(assistantMsg)
            streamingText = ""
            saveHistory()
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            resetSession()
            error = "Conversation was too long — starting fresh."
        } catch {
            self.error = error.localizedDescription
        }
        isStreaming = false
    }

    func resetSession() {
        session = nil
        buildSession()
    }

    func clearHistory() {
        messages = []
        resetSession()
        UserDefaults.standard.removeObject(forKey: Self.historyKey)
    }

    private func buildSession() {
        session = LanguageModelSession(instructions: mode.systemPrompt)
        // Inject the first assistant message for context
        if messages.filter({ $0.mode == mode.rawValue }).isEmpty {
            messages.append(PracticeMessage(role: .assistant, content: mode.firstMessage, mode: mode))
        }
    }

    // MARK: Persistence

    private func saveHistory() {
        let recent = Array(messages.suffix(Self.maxStoredMessages))
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.historyKey),
              let saved = try? JSONDecoder().decode([PracticeMessage].self, from: data)
        else { return }
        messages = saved
    }
}

// MARK: - Bit Practice View

struct BitPracticeView: View {
    @StateObject private var conv = BitConversationStore.shared
    @State private var input = ""
    @FocusState private var focused: Bool

    private var displayedMessages: [PracticeMessage] {
        conv.messages.filter { $0.mode == conv.mode.rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                messageList
                if let err = conv.error {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal).padding(.top, 4)
                }
                quickActions
                inputBar
            }
            .navigationTitle("Practice with Bit")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        conv.clearHistory()
                        HapticManager.shared.impact()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Clear conversation")
                }
            }
        }
    }

    // MARK: Mode Picker

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PracticeMode.allCases) { m in
                    Button {
                        HapticManager.shared.selection()
                        withAnimation { conv.mode = m }
                    } label: {
                        Label(m.label, systemImage: m.icon)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(conv.mode == m ? Color.purple.opacity(0.2) : SprintPalette.card, in: Capsule())
                            .foregroundStyle(conv.mode == m ? .purple : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(SprintPalette.card)
    }

    // MARK: Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(displayedMessages) { msg in
                        PracticeBubble(message: msg)
                            .id(msg.id)
                    }
                    if conv.isStreaming && !conv.streamingText.isEmpty {
                        PracticeBubble(message: PracticeMessage(
                            role: .assistant, content: conv.streamingText, mode: conv.mode
                        ))
                        .id("streaming")
                    }
                    if conv.isStreaming && conv.streamingText.isEmpty {
                        BitThinkingDots().id("thinking")
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .onChange(of: displayedMessages.count) { _, _ in
                withAnimation { proxy.scrollTo("streaming", anchor: .bottom) }
            }
            .onChange(of: conv.streamingText) { _, _ in
                proxy.scrollTo("streaming", anchor: .bottom)
            }
        }
    }

    // MARK: Quick Actions

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button(prompt) {
                        input = prompt
                        Task { await conv.send(prompt); input = "" }
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.purple.opacity(0.10), in: Capsule())
                    .foregroundStyle(Color.purple)
                    .buttonStyle(.plain)
                    .disabled(conv.isStreaming)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
        }
    }

    private var quickPrompts: [String] {
        switch conv.mode {
        case .general:    return ["Explain async/await", "What is a closure?", "Stack vs heap?", "Explain Big O"]
        case .interview:  return ["Next question", "Give me a hint", "Explain the answer", "Harder question"]
        case .codeReview: return ["Review for bugs", "Optimize this", "Explain this code", "Add error handling"]
        }
    }

    // MARK: Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Bit anything…", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .focused($focused)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
                .disabled(conv.isStreaming)

            Button {
                let text = input
                input = ""
                Task { await conv.send(text) }
            } label: {
                Image(systemName: conv.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.purple)
                    .opacity(input.isEmpty && !conv.isStreaming ? 0.4 : 1)
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !conv.isStreaming)
            .buttonStyle(.plain)
            .accessibilityLabel(conv.isStreaming ? "Stop generating" : "Send message")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(SprintPalette.navy)
    }
}

// MARK: - Practice Bubble (with code block rendering)

struct PracticeBubble: View {
    let message: PracticeMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 50) }
            if !isUser {
                Text("🤖").font(.title3)
            }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                ForEach(parseSegments(message.content)) { segment in
                    if segment.isCode {
                        CodeSegmentView(code: segment.text, language: segment.language)
                    } else {
                        Text(segment.text)
                            .font(.body)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(isUser ? Color.purple.opacity(0.18) : SprintPalette.card,
                                        in: RoundedRectangle(cornerRadius: 16,
                                                             style: isUser ? .continuous : .continuous))
                    }
                }
            }
            if isUser {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title3).foregroundStyle(Color.purple)
            } else {
                Spacer(minLength: 50)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "Bit"): \(message.content)")
    }
}

// MARK: - Code Segment Rendering

private struct MessageSegment: Identifiable {
    let id = UUID()
    let text: String
    let isCode: Bool
    let language: String
}

private func parseSegments(_ content: String) -> [MessageSegment] {
    var segments: [MessageSegment] = []
    var remaining = content
    while !remaining.isEmpty {
        if let codeStart = remaining.range(of: "```") {
            let before = String(remaining[remaining.startIndex..<codeStart.lowerBound])
            if !before.isEmpty { segments.append(.init(text: before, isCode: false, language: "")) }
            remaining = String(remaining[codeStart.upperBound...])
            // Extract language hint
            let lang: String
            if let newline = remaining.firstIndex(of: "\n") {
                lang = String(remaining[remaining.startIndex..<newline]).trimmingCharacters(in: .whitespaces)
                remaining = String(remaining[remaining.index(after: newline)...])
            } else { lang = "" }
            if let codeEnd = remaining.range(of: "```") {
                let code = String(remaining[remaining.startIndex..<codeEnd.lowerBound])
                segments.append(.init(text: code, isCode: true, language: lang))
                remaining = String(remaining[codeEnd.upperBound...])
            } else {
                segments.append(.init(text: remaining, isCode: true, language: lang))
                remaining = ""
            }
        } else {
            segments.append(.init(text: remaining, isCode: false, language: ""))
            remaining = ""
        }
    }
    return segments.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

private struct CodeSegmentView: View {
    let code: String
    let language: String
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                HStack {
                    Text(language).font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(copied ? "Copied!" : "Copy") {
                        UIPasteboard.general.string = code
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    }
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(Color.purple)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.purple.opacity(0.12))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code.trimmingCharacters(in: .newlines))
                    .font(.system(.caption, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.purple.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Thinking Dots

private struct BitThinkingDots: View {
    @State private var phase = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            Text("🤖").font(.title3)
            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle().fill(Color.purple.opacity(phase == i ? 1 : 0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
    }
}
