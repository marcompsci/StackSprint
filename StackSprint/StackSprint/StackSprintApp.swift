import SwiftUI
import WebKit
import UniformTypeIdentifiers

@main struct StackSprintApp: App {
    @StateObject private var store = LearningStore()
    @StateObject private var backend = Backend()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(backend)
                .tint(.indigo)
                .onAppear { store.switchUser(backend.session?.user.id) }
                .onChange(of: backend.session?.user.id) { _, id in store.switchUser(id) }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { LearnView() }
                .tabItem { Label("Learn", systemImage: "sparkles") }
            NavigationStack { StudioView() }
                .tabItem { Label("Studio", systemImage: "curlybraces") }
            NavigationStack { TogetherView() }
                .tabItem { Label("Together", systemImage: "heart.fill") }
            NavigationStack { AccountView() }
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
    }
}

struct LearnView: View {
    @EnvironmentObject var store: LearningStore
    @State private var exporting = false
    @State private var exportError: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Little lessons.\nReal superpowers.").font(.largeTitle.bold())
                    Text("Learn a little. Build something yours.").foregroundStyle(.secondary)
                    ProgressView(value: Double(store.completed.count), total: Double(max(store.curriculum?.lessons.count ?? 1, 1)))
                    Text("\(store.completed.count) lessons practiced").font(.caption.bold())
                }.padding(.vertical)
            }
            if let error = store.error { Text(error).foregroundStyle(.red) }
            ForEach(["Web development", "Python", "Cybersecurity"], id: \.self) { category in
                Section(category) {
                    ForEach(store.curriculum?.lessons.filter { $0.category == category } ?? []) { lesson in
                        NavigationLink { LessonView(lesson: lesson) } label: {
                            HStack {
                                Image(systemName: store.completed.contains(lesson.id) ? "checkmark.seal.fill" : "bolt.circle.fill")
                                    .foregroundStyle(.indigo)
                                VStack(alignment: .leading) {
                                    Text(lesson.term).font(.headline)
                                    Text(lesson.clue).font(.caption).foregroundStyle(.secondary)
                                }
                            }.padding(.vertical, 6)
                        }
                    }
                }
            }
            Section("Recall arcade") {
                NavigationLink("Web quiz · 25 questions") {
                    QuizView(questions: store.curriculum?.questions.filter { $0.id.hasPrefix("web-") } ?? [])
                }
                NavigationLink("Cybersecurity quiz · 25 questions") {
                    QuizView(questions: store.curriculum?.questions.filter { $0.id.hasPrefix("cyber-") } ?? [])
                }
                Button("Export flashcards (CSV)", systemImage: "square.and.arrow.up") { exporting = true }
                if let exportError { Text(exportError).foregroundStyle(.red) }
            }
        }
        .navigationTitle("StackSprint")
        .fileExporter(
            isPresented: $exporting,
            document: FlashcardDocument(lessons: store.curriculum?.lessons ?? []),
            contentType: .commaSeparatedText,
            defaultFilename: "StackSprint-flashcards"
        ) { result in
            if case .failure(let error) = result { exportError = error.localizedDescription }
        }
    }
}

struct LessonView: View {
    let lesson: Lesson
    @EnvironmentObject var store: LearningStore
    @State private var revealed = false
    @State private var code = ""
    @State private var feedback = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(lesson.clue).font(.title2.bold())
                Button(revealed ? "Hide explanation" : "Reveal explanation", systemImage: "sparkles") {
                    revealed.toggle()
                }.buttonStyle(.borderedProminent)
                if revealed {
                    Text(lesson.definition).font(.title3)
                    if !lesson.code.isEmpty {
                        Text("Recreate this example").font(.headline)
                        Text(lesson.code)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        TextEditor(text: $code)
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .frame(minHeight: 170)
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.3)))
                            .accessibilityLabel("Type the lesson code")
                        Text("This native checkpoint checks transcription, not execution. Open Studio to run and remix code.")
                            .font(.caption).foregroundStyle(.secondary)
                        Button("Check my example") {
                            if code.trimmingCharacters(in: .whitespacesAndNewlines) == lesson.code {
                                store.complete(lesson.id)
                                feedback = "Nicely done! Make your own version in Studio next."
                            } else {
                                feedback = "Check spelling, quotes, spacing, and line breaks against the example."
                            }
                        }.buttonStyle(.borderedProminent)
                    } else {
                        Button("I reviewed this concept") {
                            store.complete(lesson.id)
                            feedback = "Reviewed! Test your recall in the course quiz."
                        }.buttonStyle(.borderedProminent)
                    }
                    Text(feedback).foregroundStyle(.indigo).accessibilityAddTraits(.updatesFrequently)
                    NavigationLink("Open hands-on studio →") { StudioView() }
                }
            }.padding(24).frame(maxWidth: 700)
        }
        .navigationTitle(lesson.term)
        .onAppear { code = UserDefaults.standard.string(forKey: "draft.\(lesson.id)") ?? "" }
        .onChange(of: code) { _, value in UserDefaults.standard.set(value, forKey: "draft.\(lesson.id)") }
    }
}

struct QuizView: View {
    let questions: [Question]
    @State private var index = 0
    @State private var selected: Int?
    @State private var score = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if questions.isEmpty {
                    ContentUnavailableView("No questions available", systemImage: "questionmark.circle")
                } else if index >= questions.count {
                    Text("Round complete! 🎉").font(.largeTitle.bold())
                    Text("\(score) / \(questions.count) correct. Every attempt is practice.")
                    Button("Play again") { index = 0; score = 0; selected = nil }.buttonStyle(.borderedProminent)
                } else {
                    let q = questions[index]
                    Text("Question \(index + 1) of \(questions.count)").font(.caption.bold())
                    ProgressView(value: Double(index), total: Double(questions.count))
                    Text(q.question).font(.title2.bold())
                    ForEach(q.choices.indices, id: \.self) { i in
                        Button {
                            selected = i
                            if i == q.answer { score += 1 }
                        } label: {
                            HStack {
                                Text(q.choices[i])
                                Spacer()
                                if selected != nil && i == q.answer {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                            }.padding().frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.bordered).disabled(selected != nil)
                    }
                    if let selected {
                        Text(selected == q.answer ? "You got it!" : "A useful mistake — here's why.").font(.headline)
                        Text(q.explanation)
                        Button("Continue") { index += 1; self.selected = nil }.buttonStyle(.borderedProminent)
                    }
                }
            }.padding(24).frame(maxWidth: 700)
        }.navigationTitle("Recall arcade")
    }
}

struct StudioView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Hands-on web workspace · saves locally. Python needs internet; account sync does not include studio saves.")
                .font(.caption).padding(10)
            StudioWebView()
        }
        .navigationTitle("Build & play")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct TogetherView: View {
    @EnvironmentObject var store: LearningStore
    var body: some View {
        List {
            Section {
                Text("Better with a buddy. 💜").font(.largeTitle.bold())
                Text("Build a little. Cheer a lot. Invite a friend through an app you already use.")
                ShareLink(item: "I've practiced \(store.completed.count) lessons in StackSprint! Want to learn a coding concept together today?") {
                    Label("Share my progress", systemImage: "square.and.arrow.up")
                }
            }
            Section("Co-op quests") {
                ShareLink("Practice Python together", item: "Coding buddy quest: practice Python for five minutes, then show each other something you made!")
                ShareLink("Send encouragement", item: "Small steps count. Proud of you for showing up to code today! 🌱")
            }
            Section("Private by default") {
                Text("We do not upload contacts. Choose the recipient in your device's share sheet. In-app chat, friend accounts, and leaderboards are not included in this release.")
            }
        }.navigationTitle("Together")
    }
}

struct AccountView: View {
    @EnvironmentObject var backend: Backend
    @EnvironmentObject var store: LearningStore
    @State private var email = ""
    @State private var password = ""
    @State private var confirmDelete = false

    var body: some View {
        Form {
            if backend.config == nil {
                Section("Guest mode") {
                    Text("Learning works without an account. To enable cloud sync, add your Supabase URL and publishable key to BackendConfig.json and run backend/schema.sql on your project.")
                }
            }
            if let session = backend.session {
                Section("Signed in") {
                    Text(session.user.email ?? "Your account")
                    Button("Sync lesson progress") { perform { try await backend.sync(store) } }
                    Button("Sign out") { perform { await backend.signOut() } }
                    Button("Delete account", role: .destructive) { confirmDelete = true }
                }
            } else {
                Section("Cloud account") {
                    TextField("Email", text: $email)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        #endif
                    SecureField("Password", text: $password)
                        #if os(iOS)
                        .textContentType(.password)
                        #endif
                    Button("Sign in") {
                        perform { try await backend.signIn(email: email, password: password); password = "" }
                    }
                    Button("Create account") {
                        perform { try await backend.signUp(email: email, password: password); password = "" }
                    }
                }.disabled(backend.config == nil)
            }
            if backend.busy { ProgressView("Working…") }
            if !backend.message.isEmpty { Text(backend.message) }
            Section("About your progress") {
                Text("Guest and account lesson progress are separate. Sync uploads completed native lessons and merges cloud completions. Drafts and the web studio remain local.")
            }
        }
        .disabled(backend.busy)
        .navigationTitle("Account")
        .confirmationDialog("Delete your account and all cloud progress? This cannot be undone.", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete permanently", role: .destructive) {
                perform {
                    let id = backend.session?.user.id
                    try await backend.deleteAccount()
                    if let id { UserDefaults.standard.removeObject(forKey: "native.completed.\(id)") }
                }
            }
        }
    }

    private func perform(_ work: @escaping @MainActor () async throws -> Void) {
        backend.busy = true; backend.message = ""
        Task { defer { backend.busy = false }; do { try await work() } catch { backend.message = error.localizedDescription } }
    }
}

#if canImport(UIKit)
struct StudioWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
#elseif canImport(AppKit)
struct StudioWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        let web = WKWebView()
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Web") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
#endif

struct FlashcardDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String

    init(lessons: [Lesson]) {
        func quote(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        text = "Term,Definition,Example\r\n" + lessons.map {
            [quote($0.term), quote($0.definition), quote($0.code)].joined(separator: ",")
        }.joined(separator: "\r\n")
    }

    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
