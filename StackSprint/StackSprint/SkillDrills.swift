import SwiftUI

// MARK: - Skill drills for the paid tracks
//
// Reading about a skill isn't the same as practising it. These drills ask the learner
// to make the judgment themselves, with feedback straight away.
// • AI Skills: build a prompt from parts (with a privacy check), and decide what to do
//   with AI answers that might be wrong.
// • Professional Practice: find the bug in a short snippet, the way a reviewer would.
// All content is original.

struct ClaimCheck: Identifiable {
    let id: String
    let question: String
    let aiAnswer: String
    let options: [String]
    let best: Int
    let why: String
}

enum ClaimChecks {
    static let all: [ClaimCheck] = [
        ClaimCheck(id: "cc-1", question: "You asked an AI for a source on how much sleep teenagers need.",
                   aiAnswer: "According to \"Sleep and the Teenage Brain\" (Harlow, 2019, Journal of Youth Health, p. 214), teens need 9–10 hours.",
                   options: ["Use it: the citation is very specific", "Search for the article yourself before citing it", "Ask the AI if it's sure"],
                   best: 1, why: "AI tools can invent sources that look real, down to page numbers. A specific citation isn't proof. Find the article yourself; asking the AI again isn't a check."),
        ClaimCheck(id: "cc-2", question: "You asked for the dose of a medicine for your child.",
                   aiAnswer: "Give 10 ml every 4 hours.",
                   options: ["Follow it", "Check the product label or ask a pharmacist or doctor", "Halve it to be safe"],
                   best: 1, why: "For health, money and legal decisions, AI is a starting point at most. The label, a pharmacist or a doctor is the reliable source."),
        ClaimCheck(id: "cc-3", question: "You asked an AI to sum a list of 40 expenses.",
                   aiAnswer: "The total is $3,482.17.",
                   options: ["Trust it: computers are good at maths", "Check it with a calculator or spreadsheet", "Ask for the total again"],
                   best: 1, why: "Chat models predict text; they can slip on long arithmetic. Use a tool that actually calculates, or ask the AI to show its steps and check them."),
        ClaimCheck(id: "cc-4", question: "You asked who won a game last night.",
                   aiAnswer: "The home team won 3–1.",
                   options: ["Believe it", "Check a news or sports site", "It must be right if it sounds confident"],
                   best: 1, why: "A model may not know recent events, and it can sound confident either way. For anything recent, check a current source."),
        ClaimCheck(id: "cc-5", question: "You asked an AI to explain what a for loop does, and its answer matches your lesson.",
                   aiAnswer: "A for loop repeats code once for each item in a collection.",
                   options: ["Reasonable to use: it's a well-known basic fact you can check", "Never use AI for anything", "Report it as a hallucination"],
                   best: 0, why: "AI is often right on common, well-documented basics, and this matches what you learned. Checking is about effort that fits the stakes."),
        ClaimCheck(id: "cc-6", question: "An AI wrote a function for your app and says it's \"fully tested\".",
                   aiAnswer: "Here's the function. It's fully tested and handles every edge case.",
                   options: ["Ship it", "Run it and write your own tests, including edge cases", "Ask it to promise again"],
                   best: 1, why: "The AI hasn't run anything on your machine. Code from AI is a draft: you run it, test it and own it."),
        ClaimCheck(id: "cc-7", question: "You asked for a quote from a famous scientist for a school poster.",
                   aiAnswer: "\"Curiosity is the engine of every discovery.\" — a famous physicist",
                   options: ["Print it with the name", "Find the quote in a trusted collection or original source first", "Change one word so it's yours"],
                   best: 1, why: "Made-up quotes are common. If you can't find it in a reliable source, don't attribute it to a real person."),
        ClaimCheck(id: "cc-8", question: "An AI gives you a link to the official docs for a library.",
                   aiAnswer: "See the docs at the official site: docs.example-library.dev/v4/setup",
                   options: ["Open the library's homepage and navigate to the docs yourself", "Click it: it says official", "Paste your password there to log in"],
                   best: 0, why: "Links from AI can be wrong or point somewhere unexpected. Get to official pages from the project's real homepage, and never type passwords into a page you reached from an unverified link."),
        ClaimCheck(id: "cc-9", question: "You get a voice message that sounds exactly like your cousin, asking you to send money urgently.",
                   aiAnswer: "(A cloned voice) \"It's me, I'm stuck, please send $400 right now and don't tell anyone.\"",
                   options: ["Send it quickly", "Call your cousin back on the number you already have", "Reply asking for a selfie"],
                   best: 1, why: "Voices can be cloned from a few seconds of audio. Urgency and secrecy are warning signs. Verify through a channel you already trust."),
        ClaimCheck(id: "cc-10", question: "An AI summarised a 20-page contract for you.",
                   aiAnswer: "In short: you can cancel any time with no fee.",
                   options: ["Sign based on the summary", "Find the cancellation section in the contract and read it yourself", "Ask the AI to summarise it again"],
                   best: 1, why: "Summaries can drop conditions like notice periods or fees. For anything you sign, read the parts that matter in the original."),
        ClaimCheck(id: "cc-11", question: "An AI agent you set up to compare flights says it found a great deal and asks for your card details to book it.",
                   aiAnswer: "Found a $120 flight! Please type your card number so I can complete the booking.",
                   options: ["Type your card number", "Stop and book it yourself on the airline's own site", "Give it just the last 4 digits"],
                   best: 1, why: "Keep payments and account access in your own hands. Check the deal yourself on the official site before paying."),
        ClaimCheck(id: "cc-12", question: "You asked an AI to explain a homework concept and it gives a clear step-by-step explanation.",
                   aiAnswer: "Here's how photosynthesis works, step by step… (matches your textbook)",
                   options: ["Copy it as your homework answer", "Use it to understand, then write your answer in your own words", "Ignore it"],
                   best: 1, why: "Using AI to understand is fine; handing in its words as your own usually isn't. Check your school's rules and say when you used AI help."),
    ]
}

struct BugHunt: Identifiable {
    let id: String
    let title: String
    let lines: [String]
    let buggyLine: Int
    let why: String
    let fix: String
}

enum BugHunts {
    static let all: [BugHunt] = [
        BugHunt(id: "bh-1", title: "Average of a list",
                lines: ["func average(_ values: [Double]) -> Double {", "    let total = values.reduce(0, +)", "    return total / Double(values.count)", "}"],
                buggyLine: 2, why: "An empty list divides by zero and returns NaN.",
                fix: "guard !values.isEmpty else { return 0 }"),
        BugHunt(id: "bh-2", title: "Last item",
                lines: ["let names = [\"Ana\", \"Ben\", \"Cy\"]", "let last = names[names.count]", "print(last)"],
                buggyLine: 1, why: "Indexes start at 0, so the last index is count - 1. This crashes.",
                fix: "let last = names.last"),
        BugHunt(id: "bh-3", title: "Committing a key",
                lines: ["struct Config {", "    static let apiKey = \"sk_live_8f2a…\"", "    static let timeout = 30.0", "}"],
                buggyLine: 1, why: "A real secret is in the source code. Anyone with the repository can read it.",
                fix: "Load the key from the environment or a secrets manager, and replace the leaked one."),
        BugHunt(id: "bh-4", title: "Counting down",
                lines: ["var count = 3", "while count > 0 {", "    print(count)", "}"],
                buggyLine: 3, why: "count never changes, so the loop runs forever.",
                fix: "Add count -= 1 inside the loop."),
        BugHunt(id: "bh-5", title: "Checking a password length",
                lines: ["def is_long_enough(password):", "    if len(password) > 8:", "        return True", "    return False"],
                buggyLine: 1, why: "\"At least 8 characters\" needs >=. Exactly 8 characters is wrongly rejected.",
                fix: "if len(password) >= 8:"),
        BugHunt(id: "bh-6", title: "Comparing text",
                lines: ["let answer = readLine() ?? \"\"", "if answer == \"Yes\" {", "    startGame()", "}"],
                buggyLine: 1, why: "\"yes\" or \" Yes \" won't match. User input needs trimming and case-insensitive comparison.",
                fix: "if answer.trimmingCharacters(in: .whitespaces).lowercased() == \"yes\""),
        BugHunt(id: "bh-7", title: "Logging a login",
                lines: ["func signIn(user: String, password: String) {", "    print(\"Signing in \\(user) with \\(password)\")", "    auth.signIn(user, password)", "}"],
                buggyLine: 1, why: "Logs can be read by others and kept for a long time. Never log passwords or tokens.",
                fix: "print(\"Signing in \\(user)\")"),
        BugHunt(id: "bh-8", title: "Sum of a range",
                lines: ["// Sum the numbers 1 through 10", "var sum = 0", "for n in 1..<10 { sum += n }", "print(sum)"],
                buggyLine: 2, why: "1..<10 stops at 9, so 10 is left out (sum is 45, not 55).",
                fix: "for n in 1...10 { sum += n }"),
        BugHunt(id: "bh-9", title: "Saving user input",
                lines: ["let name = request.query[\"name\"]", "let sql = \"SELECT * FROM users WHERE name = '\" + name + \"'\"", "db.run(sql)"],
                buggyLine: 1, why: "Joining user input into SQL allows SQL injection.",
                fix: "db.run(\"SELECT * FROM users WHERE name = ?\", [name])"),
        BugHunt(id: "bh-10", title: "Waiting for data",
                lines: ["func load() async {", "    let data = fetchProfile()", "    show(data)", "}"],
                buggyLine: 1, why: "fetchProfile is async, so it must be awaited; otherwise the code doesn't compile or uses data that isn't there yet.",
                fix: "let data = await fetchProfile()"),
        BugHunt(id: "bh-11", title: "Comparing prices",
                lines: ["let total = 0.1 + 0.2", "if total == 0.3 {", "    print(\"Exact\")", "}"],
                buggyLine: 1, why: "Floating-point numbers can't store 0.1 exactly, so 0.1 + 0.2 isn't exactly 0.3. Use a tolerance or whole cents for money.",
                fix: "if abs(total - 0.3) < 0.0001 { … }  // or store cents as Int"),
        BugHunt(id: "bh-12", title: "Retrying a request",
                lines: ["while !success {", "    success = try sendRequest()", "}"],
                buggyLine: 0, why: "If the server is down this retries forever, as fast as it can. Limit the attempts and wait longer between them.",
                fix: "for attempt in 1...3 { … sleep(attempt * 2) }"),
    ]
}

// MARK: - Practice lab (shown in the review hub)

/// Drills for the paid tracks. Owned tracks open the drill; others open the paywall.
struct PracticeLabSection: View {
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var showingPaywall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Practice lab").font(.title3.bold())
            drill("Prompt builder", "Build a clear prompt step by step, with a privacy check", "square.stack.3d.up.fill",
                  track: PaidContent.aiTrack) { PromptBuilderView() }
            drill("Prompt makeovers", "Pick the best rewrite of a weak prompt", "wand.and.stars",
                  track: PaidContent.aiTrack) { PromptMakeoverView() }
            drill("Check the AI", "Decide what to do with answers that might be wrong", "checkmark.shield.fill",
                  track: PaidContent.aiTrack) { ClaimCheckView() }
            drill("Bug hunt", "Find the bug in a short snippet, like a code reviewer", "ant.fill",
                  track: PaidContent.professionalTrack) { BugHuntView() }
        }
        .sheet(isPresented: $showingPaywall) { ProPaywallView() }
    }

    @ViewBuilder
    private func drill<Destination: View>(_ title: String, _ subtitle: String, _ icon: String, track: String,
                                          @ViewBuilder destination: @escaping () -> Destination) -> some View {
        let locked = premiumStore.isLocked(track)
        let row = HStack(spacing: 12) {
            Image(systemName: icon).font(.title3).foregroundStyle(locked ? Color.secondary : Color.mint).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if locked {
                Text(PremiumStore.offer(for: track).shortTitle).font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.15), in: Capsule())
                Image(systemName: "lock.fill").foregroundStyle(.secondary)
            } else {
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        if locked {
            Button {
                premiumStore.preparePaywall(for: track)
                showingPaywall = true
            } label: { row }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), requires \(PremiumStore.offer(for: track).title)")
        } else {
            NavigationLink(destination: destination) { row }.buttonStyle(.plain)
        }
    }
}

// MARK: - Prompt builder

struct PromptBuilderView: View {
    @EnvironmentObject var store: LearningStore
    @State private var draft = PromptDraft()
    @State private var copied = false

    var body: some View {
        Form {
            Section {
                TextField("A friendly science teacher", text: $draft.role)
            } header: { Text("Role (optional)") } footer: { Text("Who should the AI act as?") }
            Section {
                TextField("Explain how vaccines train the immune system", text: $draft.task, axis: .vertical)
            } header: { Text("Task") } footer: { Text("Say exactly what you want, in a full sentence.") }
            Section {
                TextField("For a 12-year-old who likes football", text: $draft.context, axis: .vertical)
            } header: { Text("Context") } footer: { Text("Who it's for, why you need it, what they already know.") }
            Section {
                TextField("Under 150 words, with one everyday comparison", text: $draft.format, axis: .vertical)
            } header: { Text("Format") }
            Section {
                TextField("Jargon, scary details", text: $draft.avoid, axis: .vertical)
            } header: { Text("Avoid (optional)") }

            Section("Checklist") {
                ForEach(PromptCheck.feedback(draft)) { item in
                    Label(item.text, systemImage: item.ok ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.ok ? Color.green : (item.id == "privacy" ? Color.red : Color.secondary))
                        .font(.subheadline)
                }
            }
            let prompt = PromptCheck.assemble(draft)
            if !prompt.isEmpty {
                Section {
                    Text(prompt).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                    Button(copied ? "Copied" : "Copy prompt", systemImage: copied ? "checkmark" : "doc.on.doc") {
                        UIPasteboard.general.string = prompt
                        copied = true
                        store.recordPractice()
                        HapticManager.shared.notification(.success)
                    }
                    .disabled(!PromptCheck.privacyWarnings(prompt).isEmpty)
                } header: {
                    Text("Your prompt")
                } footer: {
                    Text(PromptCheck.privacyWarnings(prompt).isEmpty
                         ? "Paste it into any AI tool. Then check what comes back: you're still the one responsible for it."
                         : "Take out the private details before copying.")
                }
            }
        }
        .navigationTitle("Prompt builder")
        .modifier(SprintTheme())
        .onChange(of: draft) { _, _ in copied = false }
    }
}

// MARK: - Check the AI

struct ClaimCheckView: View {
    @EnvironmentObject var store: LearningStore
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0
    private let items = ClaimChecks.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if items.indices.contains(index) {
                    let item = items[index]
                    Text("\(index + 1) of \(items.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
                    Text(item.question).font(.headline)
                    VStack(alignment: .leading, spacing: 4) {
                        Label("The AI said", systemImage: "sparkles").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(item.aiAnswer)
                    }
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("What's the best next step?").font(.title3.bold())
                    ChoiceList(options: item.options, best: item.best, picked: $picked) { choice in
                        if choice == item.best { score += 1 }
                        if index + 1 == items.count { store.recordPractice() }
                    }
                    if picked != nil {
                        Text(item.why).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        Button(index + 1 < items.count ? "Next" : "Finish") { picked = nil; index += 1 }
                            .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                } else {
                    Text("\(score) of \(items.count) best calls").font(.largeTitle.bold())
                    Text("Check harder when the stakes are higher: health, money, legal, safety, anything recent, and any source or quote you'll repeat.")
                        .foregroundStyle(.secondary)
                    Button("Practice again") { index = 0; score = 0; picked = nil }.buttonStyle(.borderedProminent)
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle("Check the AI")
        .modifier(SprintTheme())
    }
}

/// Multiple choice with right/wrong colouring, shared by the drills.
private struct ChoiceList: View {
    let options: [String]
    let best: Int
    @Binding var picked: Int?
    let onPick: (Int) -> Void

    var body: some View {
        ForEach(options.indices, id: \.self) { i in
            Button {
                picked = i
                onPick(i)
                HapticManager.shared.notification(i == best ? .success : .warning)
                AccessibilityNotification.Announcement(i == best ? "Best choice" : "Not the best choice").post()
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(options[i]).multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if picked != nil && i == best { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                    else if picked == i { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(background(i), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(picked != nil)
            .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
        }
    }

    private func background(_ i: Int) -> Color {
        guard let picked else { return SprintPalette.card }
        if i == best { return .green.opacity(0.15) }
        if i == picked { return .red.opacity(0.12) }
        return SprintPalette.card
    }
}

// MARK: - Bug hunt

struct BugHuntView: View {
    @EnvironmentObject var store: LearningStore
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0
    private let items = BugHunts.all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if items.indices.contains(index) {
                    let item = items[index]
                    Text("\(index + 1) of \(items.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
                    Text(item.title).font(.title3.bold())
                    Text("Tap the line with the bug.").font(.subheadline).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(item.lines.indices, id: \.self) { i in
                            Button { pick(i, item) } label: {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text("\(i + 1)").font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 18, alignment: .trailing)
                                    Text(item.lines[i]).font(.system(.callout, design: .monospaced)).multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 8).padding(.horizontal, 10)
                                .background(lineFill(i, item), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(picked != nil)
                            .accessibilityLabel("Line \(i + 1): \(item.lines[i])")
                        }
                    }
                    .padding(10)
                    .background(Color(red: 0.055, green: 0.09, blue: 0.15).opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    if let picked {
                        Text(picked == item.buggyLine ? "Found it." : "The bug is on line \(item.buggyLine + 1).").font(.headline)
                        Text(item.why).fixedSize(horizontal: false, vertical: true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fix").font(.caption.bold()).foregroundStyle(.secondary)
                            Text(item.fix).font(.system(.callout, design: .monospaced))
                        }
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Button(index + 1 < items.count ? "Next" : "Finish") { self.picked = nil; index += 1 }
                            .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                } else {
                    Text("\(score) of \(items.count) bugs found").font(.largeTitle.bold())
                    Text("Reviewers look for the same few things again and again: empty inputs, off-by-one ranges, loops that never end, leaked secrets and sensitive data in logs.")
                        .foregroundStyle(.secondary)
                    Button("Hunt again") { index = 0; score = 0; picked = nil }.buttonStyle(.borderedProminent)
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle("Bug hunt")
        .modifier(SprintTheme())
    }

    private func pick(_ line: Int, _ item: BugHunt) {
        picked = line
        if line == item.buggyLine { score += 1 }
        if index + 1 == items.count { store.recordPractice() }
        HapticManager.shared.notification(line == item.buggyLine ? .success : .warning)
        AccessibilityNotification.Announcement(line == item.buggyLine ? "Found the bug" : "The bug is on line \(item.buggyLine + 1)").post()
    }

    private func lineFill(_ i: Int, _ item: BugHunt) -> Color {
        guard let picked else { return .clear }
        if i == item.buggyLine { return .green.opacity(0.18) }
        if i == picked { return .red.opacity(0.14) }
        return .clear
    }
}
