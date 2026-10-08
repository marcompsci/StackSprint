import Combine
import FoundationModels
import SwiftUI

// MARK: - Generable Lesson Struct

@Generable
struct GeneratedLesson {
    @Guide(description: "The programming concept, keyword, or function name — 2 to 5 words, title-case")
    var term: String

    @Guide(description: "A one-line prediction or hint for the learner, 8 to 15 words, no spoilers")
    var clue: String

    @Guide(description: "A clear, 2–3 sentence explanation of the concept")
    var definition: String

    @Guide(description: "A short, illustrative code example, 2–8 lines. Use empty string if no code fits.")
    var code: String
}

// MARK: - Custom Lessons Store

@MainActor final class CustomLessonsStore: ObservableObject {
    @Published private(set) var lessons: [Lesson] = []

    private static let key = "ss.customLessons"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([Lesson].self, from: data) {
            lessons = saved
        }
    }

    func add(_ lesson: Lesson) {
        guard !lessons.contains(where: { $0.id == lesson.id }) else { return }
        lessons.insert(lesson, at: 0)
        persist()
    }

    func remove(_ lesson: Lesson) {
        lessons.removeAll { $0.id == lesson.id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(lessons) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}

// MARK: - Lesson Generator ViewModel

@MainActor final class LessonGeneratorViewModel: ObservableObject {
    @Published var topic = ""
    @Published var category = "Swift"
    @Published var isGenerating = false
    @Published var preview: GeneratedLesson?
    @Published var savedLesson: Lesson?
    @Published var error: String?

    let categories = ["Swift", "Python", "TypeScript", "React", "Go", "Rust",
                      "Web development", "Cybersecurity", "Interview Prep", "Custom"]

    private var session: LanguageModelSession?

    func generate() async {
        guard !topic.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard case .available = SystemLanguageModel.default.availability else {
            error = "On-device AI is not available on this device."; return
        }
        isGenerating = true
        preview = nil
        error = nil
        savedLesson = nil

        if session == nil {
            session = LanguageModelSession(instructions: """
                You are Bit, a coding tutor assistant inside StackSprint. \
                Generate concise, beginner-friendly coding lessons. \
                Always use clear language and practical code examples. \
                Category context: \(category).
                """)
        }
        do {
            let prompt = """
                Create a StackSprint lesson card for the following topic in \(category): "\(topic)".
                The code example should be in \(codeLanguage) syntax.
                Keep everything concise and educational.
                """
            let response = try await session!.respond(to: prompt, generating: GeneratedLesson.self)
            preview = response.content
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            error = (try? await refusal.explanation.content) ?? "Bit couldn't generate a lesson for that topic."
        } catch {
            self.error = error.localizedDescription
        }
        isGenerating = false
    }

    func save(to store: CustomLessonsStore) {
        guard let gen = preview else { return }
        let lesson = Lesson(
            id: "custom-\(UUID().uuidString.prefix(8).lowercased())",
            term: gen.term,
            category: "My Lessons",
            clue: gen.clue,
            definition: gen.definition,
            code: gen.code,
            difficulty: nil
        )
        store.add(lesson)
        savedLesson = lesson
    }

    private var codeLanguage: String {
        switch category {
        case "Swift":        return "Swift"
        case "Python":       return "Python"
        case "TypeScript":   return "TypeScript"
        case "React":        return "JSX/TypeScript"
        case "Go":           return "Go"
        case "Rust":         return "Rust"
        default:             return "appropriate programming language"
        }
    }
}

// MARK: - Generate Lesson View

struct GenerateLessonView: View {
    @EnvironmentObject var customLessons: CustomLessonsStore
    @StateObject private var vm = LessonGeneratorViewModel()
    @Environment(\.dismiss) private var dismiss

    private var aiAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    private var unavailableBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("On-device AI unavailable").font(.subheadline.bold())
                Text("Requires iOS 26 on a device with Apple Intelligence.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    if !aiAvailable { unavailableBanner }
                    promptSection
                    if vm.isGenerating { generatingIndicator }
                    if let preview = vm.preview { previewSection(preview) }
                    if let saved = vm.savedLesson { savedConfirmation(saved) }
                    if let err = vm.error {
                        Text(err).font(.subheadline).foregroundStyle(.red)
                            .multilineTextAlignment(.center).padding(.horizontal)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Generate a Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(SprintTheme())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Ask Bit to teach you anything", systemImage: "sparkles")
                .font(.headline).foregroundStyle(.purple)

            TextField("e.g. async/await, closures, REST APIs…", text: $vm.topic)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .accessibilityLabel("Topic to generate a lesson about")

            Picker("Category", selection: $vm.category) {
                ForEach(vm.categories, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)

            Button {
                HapticManager.shared.impact()
                Task { await vm.generate() }
            } label: {
                Label("Generate with Bit ✦", systemImage: "sparkles")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.purple)
            .disabled(vm.topic.trimmingCharacters(in: .whitespaces).isEmpty || vm.isGenerating)
            .accessibilityIdentifier("generate-lesson-button")
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
    }

    private var generatingIndicator: some View {
        HStack(spacing: 12) {
            ProgressView().tint(.purple)
            Text("Bit is crafting your lesson…").font(.subheadline).foregroundStyle(.secondary)
        }
        .padding()
    }

    private func previewSection(_ gen: GeneratedLesson) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Preview", systemImage: "eye.fill").font(.headline)
            Text(gen.term).font(.title2.bold())
            Text(gen.clue).font(.subheadline).foregroundStyle(.secondary)
            Text(gen.definition).font(.body)
            if !gen.code.isEmpty {
                Text(gen.code)
                    .font(.system(.body, design: .monospaced))
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
            HStack(spacing: 12) {
                Button("Save to My Lessons") {
                    HapticManager.shared.notification(.success)
                    vm.save(to: customLessons)
                }
                .buttonStyle(.borderedProminent).tint(.purple)
                .disabled(vm.savedLesson != nil)

                Button("Try again") {
                    vm.preview = nil; vm.savedLesson = nil
                    Task { await vm.generate() }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 20))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func savedConfirmation(_ lesson: Lesson) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint)
            Text("\"\(lesson.term)\" saved to My Lessons!").font(.subheadline.bold())
        }
        .padding(14)
        .background(Color.mint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }
}
