import SwiftUI
import StoreKit

enum ArcadeKeys {
    static let predictBest = "arcade.predict.best"
    static let errorsBest = "arcade.errors.best"
    static let relaxedReading = "reading.relaxed"
}

// MARK: - Arcade section (Practice)

struct ArcadeSection: View {
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var projects = MiniProjectStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Arcade").font(.title3.bold())
            row("Predict the output", "Read code and say what it prints", "eye.fill") { PredictOutputView() }
            row("Error decoder", "Match error messages to what went wrong", "exclamationmark.bubble.fill") { ErrorDecoderView() }
            row("Match pairs", "Pair terms you've learned with their meanings", "square.grid.2x2.fill") { MatchGameView() }
            row("Speed round", "60 seconds of true or false", "bolt.circle.fill") { SpeedRoundView() }
            row("Mini projects", "\(projects.completedCount) of \(MiniProjects.all.count) built: use several lessons together",
                "hammer.fill") { MiniProjectsView() }
        }
    }

    private func row<D: View>(_ title: String, _ subtitle: String, _ icon: String,
                              @ViewBuilder destination: @escaping () -> D) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title3).foregroundStyle(.orange).frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(14)
            .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared multiple-choice drill

/// Steps through items with options, an answer and an explanation.
private struct ChoiceDrill: View {
    struct Item { let id: String; let header: String; let body: String; let mono: Bool; let options: [String]; let answer: Int; let why: String }
    let title: String
    let items: [Item]
    let bestKey: String
    let finale: String
    @EnvironmentObject var store: LearningStore
    @State private var index = 0
    @State private var picked: Int?
    @State private var score = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if items.indices.contains(index) {
                    let item = items[index]
                    HStack {
                        Text("\(index + 1) of \(items.count)").font(.caption.bold().monospacedDigit()).foregroundStyle(.secondary)
                        Spacer()
                        Text(item.header).font(.caption.bold()).foregroundStyle(.orange)
                    }
                    Text(item.body)
                        .font(item.mono ? .system(.callout, design: .monospaced) : .headline)
                        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    ForEach(item.options.indices, id: \.self) { i in
                        Button { pick(i, item) } label: {
                            HStack {
                                Text(item.options[i]).multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                if picked != nil && i == item.answer { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                                else if picked == i { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                            }
                            .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                            .background(fill(i, item), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(picked != nil)
                        .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                    }
                    if picked != nil {
                        Text(item.why).fixedSize(horizontal: false, vertical: true)
                        Button(index + 1 < items.count ? "Next" : "Finish") { picked = nil; index += 1 }
                            .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    }
                } else {
                    Text("\(score) of \(items.count)").font(.largeTitle.bold())
                    let best = UserDefaults.standard.integer(forKey: bestKey)
                    Text(score >= best ? "Your best so far." : "Your best: \(best) of \(items.count)").foregroundStyle(.secondary)
                    Text(finale).foregroundStyle(.secondary)
                    Button("Play again") { index = 0; score = 0; picked = nil }.buttonStyle(.borderedProminent)
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle(title)
        .modifier(SprintTheme())
    }

    private func pick(_ i: Int, _ item: Item) {
        picked = i
        if i == item.answer { score += 1 }
        HapticManager.shared.notification(i == item.answer ? .success : .warning)
        AccessibilityNotification.Announcement(i == item.answer ? "Correct" : "The answer is \(item.options[item.answer])").post()
        if index + 1 == items.count {
            let final = score
            if final > UserDefaults.standard.integer(forKey: bestKey) { UserDefaults.standard.set(final, forKey: bestKey) }
            store.recordPractice()
        }
    }

    private func fill(_ i: Int, _ item: Item) -> Color {
        guard let picked else { return SprintPalette.card }
        if i == item.answer { return .green.opacity(0.15) }
        if i == picked { return .red.opacity(0.12) }
        return SprintPalette.card
    }
}

struct PredictOutputView: View {
    var body: some View {
        ChoiceDrill(title: "Predict the output",
                    items: PredictOutput.all.map { .init(id: $0.id, header: $0.language, body: $0.code, mono: true,
                                                         options: $0.options, answer: $0.answer, why: $0.why) },
                    bestKey: ArcadeKeys.predictBest,
                    finale: "Predicting before you run code is how programmers build a picture of what code really does.")
    }
}

struct ErrorDecoderView: View {
    var body: some View {
        ChoiceDrill(title: "Error decoder",
                    items: ErrorDecoder.all.map { item -> ChoiceDrill.Item in
                        let mixed = ErrorDecoder.shuffled(item)
                        return .init(id: item.id, header: "What went wrong?", body: item.message, mono: true,
                                     options: mixed.options, answer: mixed.answer, why: "Fix: \(item.fix)")
                    },
                    bestKey: ArcadeKeys.errorsBest,
                    finale: "Error messages look scary but usually say exactly what's wrong. Read the first line slowly.")
    }
}

// MARK: - Match pairs

struct MatchGameView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var round: MatchRound?
    @State private var selectedTerm: String?
    @State private var matched: Set<String> = []
    @State private var wrongClue: String?
    @State private var mistakes = 0
    @State private var seed = 0

    private var pool: [Lesson] {
        let all = (store.curriculum?.lessons ?? []).filter { !premiumStore.isLocked($0.category) }
        let learned = all.filter { store.completed.contains($0.id) }
        return learned.count >= 5 ? learned : all
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let round {
                    Text("Tap a term, then its meaning.").foregroundStyle(.secondary)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 10) {
                            ForEach(round.terms, id: \.self) { term in
                                Button { if !matched.contains(term) { selectedTerm = term } } label: {
                                    tile(term, state: matched.contains(term) ? .done : (selectedTerm == term ? .selected : .idle))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(matched.contains(term) ? "\(term), matched" : term)
                            }
                        }
                        VStack(spacing: 10) {
                            ForEach(round.clues, id: \.self) { clue in
                                let done = round.pairs.contains { matched.contains($0.key) && $0.value == clue }
                                Button { choose(clue, in: round) } label: {
                                    tile(clue, state: done ? .done : (wrongClue == clue ? .wrong : .idle), small: true)
                                }
                                .buttonStyle(.plain)
                                .disabled(done || selectedTerm == nil)
                            }
                        }
                    }
                    if matched.count == round.terms.count {
                        Label(mistakes == 0 ? "Perfect match!" : "All matched with \(mistakes) \(mistakes == 1 ? "slip" : "slips")",
                              systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(.green)
                        Button("New round") { newRound() }.buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView("Not enough lessons yet", systemImage: "square.grid.2x2",
                                           description: Text("Open a few more lessons and come back."))
                }
            }
            .padding(24).frame(maxWidth: 700)
        }
        .navigationTitle("Match pairs")
        .modifier(SprintTheme())
        .onAppear { if round == nil { newRound() } }
    }

    private enum TileState { case idle, selected, done, wrong }

    private func tile(_ text: String, state: TileState, small: Bool = false) -> some View {
        Text(text)
            .font(small ? .caption : .subheadline.bold())
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .padding(10)
            .background(color(state), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(state == .selected ? Color.mint : .clear, lineWidth: 2))
            .opacity(state == .done ? 0.5 : 1)
    }

    private func color(_ state: TileState) -> Color {
        switch state {
        case .idle: return SprintPalette.card
        case .selected: return .mint.opacity(0.15)
        case .done: return .green.opacity(0.15)
        case .wrong: return .red.opacity(0.15)
        }
    }

    private func choose(_ clue: String, in round: MatchRound) {
        guard let term = selectedTerm else { return }
        if round.pairs[term] == clue {
            matched.insert(term)
            selectedTerm = nil
            wrongClue = nil
            HapticManager.shared.selection()
            if matched.count == round.terms.count { store.recordPractice() }
        } else {
            mistakes += 1
            wrongClue = clue
            HapticManager.shared.notification(.warning)
        }
    }

    private func newRound() {
        seed += 1
        round = MatchGame.make(from: pool, seed: "\(LearningStore.dayKey(Date()))|\(seed)")
        matched = []; selectedTerm = nil; wrongClue = nil; mistakes = 0
    }
}

// MARK: - Speed round

struct SpeedRoundView: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @AppStorage(SpeedRound.bestKey) private var best = 0
    @State private var statements: [SpeedStatement] = []
    @State private var index = 0
    @State private var score = 0
    @State private var start: Date?
    @State private var finished = false
    @State private var flash: Bool?

    var body: some View {
        VStack(spacing: 20) {
            if let start, !finished, statements.indices.contains(index) {
                TimelineView(.periodic(from: start, by: 1)) { context in
                    let left = max(0, SpeedRound.seconds - Int(context.date.timeIntervalSince(start)))
                    HStack {
                        Label("\(left)s", systemImage: "timer").font(.headline.monospacedDigit())
                        Spacer()
                        Text("Score \(score)").font(.headline.monospacedDigit())
                    }
                    .onChange(of: left == 0) { _, done in if done { finish() } }
                }
                let s = statements[index]
                VStack(spacing: 10) {
                    Text(s.term).font(.title.bold())
                    Text(s.clue).font(.title3).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
                .padding()
                .background((flash == nil ? SprintPalette.card : (flash! ? Color.green.opacity(0.15) : Color.red.opacity(0.15))),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityElement(children: .combine)
                HStack(spacing: 16) {
                    answerButton(false)
                    answerButton(true)
                }
            } else {
                Image(systemName: "bolt.circle.fill").font(.system(size: 56)).foregroundStyle(.orange)
                if finished {
                    Text("\(score) right").font(.largeTitle.bold())
                    Text(score >= best && score > 0 ? "New best!" : "Best: \(best)").foregroundStyle(.secondary)
                } else {
                    Text("Does the meaning match the term?").font(.title3.bold())
                    Text("Answer as many as you can in 60 seconds. Wrong answers don't cost points.").foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Button(finished ? "Play again" : "Start") { begin() }
                    .buttonStyle(.borderedProminent).tint(.orange)
                    .disabled(statements.isEmpty && pool.count < 4)
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: 600)
        .navigationTitle("Speed round")
        .modifier(SprintTheme())
    }

    private var pool: [Lesson] {
        let all = (store.curriculum?.lessons ?? []).filter { !premiumStore.isLocked($0.category) }
        let learned = all.filter { store.completed.contains($0.id) }
        return learned.count >= 6 ? learned : all
    }

    private func answerButton(_ value: Bool) -> some View {
        Button { answer(value) } label: {
            Label(value ? "Match" : "No match", systemImage: value ? "checkmark" : "xmark")
                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent).tint(value ? .green : .red)
        .keyboardShortcut(value ? .rightArrow : .leftArrow, modifiers: [])
    }

    private func begin() {
        statements = SpeedRound.make(from: pool, count: 80, seed: "\(Date().timeIntervalSince1970)")
        index = 0; score = 0; finished = false; flash = nil
        start = Date()
    }

    private func answer(_ value: Bool) {
        guard statements.indices.contains(index), !finished else { return }
        let right = statements[index].isTrue == value
        if right { score += 1 }
        flash = right
        HapticManager.shared.selection()
        index += 1
        if index >= statements.count { finish() }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        if score > best { best = score }
        if score > 0 { store.recordPractice() }
    }
}

// MARK: - Mini projects

struct MiniProjectsView: View {
    @ObservedObject private var projects = MiniProjectStore.shared

    var body: some View {
        List {
            Section {
                Text("Projects pull several lessons together. Building something real is where it all clicks. Tick each step as you finish it, in your own editor or the hands-on studio.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(MiniProjects.all) { project in
                NavigationLink { MiniProjectDetail(project: project) } label: {
                    HStack {
                        Image(systemName: projects.isComplete(project) ? "checkmark.seal.fill" : "hammer")
                            .foregroundStyle(projects.isComplete(project) ? Color.green : Color.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.title).font(.headline)
                            Text("\(project.track) · \(projects.progress(project)) of \(project.steps.count) steps")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Mini projects")
        .modifier(SprintTheme())
    }
}

struct MiniProjectDetail: View {
    let project: MiniProject
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var projects = MiniProjectStore.shared

    var body: some View {
        List {
            Section { Text(project.summary) }
            Section("Steps") {
                ForEach(project.steps.indices, id: \.self) { i in
                    Button {
                        let wasComplete = projects.isComplete(project)
                        projects.toggle(project, step: i)
                        HapticManager.shared.selection()
                        if !wasComplete && projects.isComplete(project) {
                            HapticManager.shared.notification(.success)
                            store.recordPractice()
                        }
                    } label: {
                        Label(project.steps[i], systemImage: projects.isDone(project, step: i) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(projects.isDone(project, step: i) ? Color.green : Color.primary)
                    }
                    .accessibilityValue(projects.isDone(project, step: i) ? "Done" : "Not done")
                }
            }
            if projects.isComplete(project) {
                Section { Label("Built! Show someone what you made.", systemImage: "party.popper.fill").foregroundStyle(.green) }
            }
            Section { NavigationLink("Open the hands-on studio") { StudioView() } }
        }
        .navigationTitle(project.title)
        .modifier(SprintTheme())
    }
}

// MARK: - Your why (study plan)

struct WhyPickerSection: View {
    @AppStorage(LearningWhy.key) private var why = ""

    var body: some View {
        Section {
            Picker("Why are you learning?", selection: $why) {
                Text("Not set").tag("")
                ForEach(LearningWhy.allCases) { Label($0.label, systemImage: $0.icon).tag($0.rawValue) }
            }
            if let reason = LearningWhy(rawValue: why) {
                LabeledContent("A good place to start", value: reason.suggestedTrack)
            }
        } footer: {
            Text("Your reason shows up in reminders. People stick with goals that mean something to them.")
        }
    }
}

// MARK: - Accountability buddy (stats)

struct BuddyShareButton: View {
    @EnvironmentObject var store: LearningStore
    @AppStorage(LearningWhy.key) private var why = ""

    var body: some View {
        ShareLink(item: BuddyMessage.text(streak: store.currentStreak,
                                          comparison: WeekComparison.make(activity: store.lessonActivity),
                                          why: LearningWhy(rawValue: why))) {
            Label("Share my week with a study buddy", systemImage: "person.2.fill")
                .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
        }
        .buttonStyle(.bordered).tint(.mint)
        .accessibilityHint("Sends a short message about your progress and asks a friend to check in")
    }
}

// MARK: - Quiz history export (memory)

struct QuizHistoryExportButton: View {
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var mastery = MasteryStore.shared

    var body: some View {
        if !mastery.records.isEmpty {
            let terms = Dictionary((store.curriculum?.lessons ?? []).map { ($0.id, $0.term) }, uniquingKeysWith: { a, _ in a })
            ShareLink(item: QuizHistoryCSV.make(records: mastery.records, terms: terms),
                      preview: SharePreview("StackSprint quiz history (CSV)")) {
                Label("Export quiz history (CSV)", systemImage: "tablecells")
            }
        }
    }
}

// MARK: - What's in a paid offer (paywall)

struct OfferOutline: View {
    let offer: PaywallOffer
    @EnvironmentObject var store: LearningStore

    var body: some View {
        let lessons: [Lesson] = switch offer {
        case .aiSkills: PaidContent.ai
        case .professional: PaidContent.professional
        case .pro: ["Go", "Rust", "Interview Prep"].flatMap { store.lessonsByTrack[$0] ?? [] }
        }
        if !lessons.isEmpty {
            DisclosureGroup("See all \(lessons.count) lessons") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(lessons) { lesson in
                        Text("\u{2022} \(lesson.term)").font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
            }
            .tint(.mint)
        }
    }
}

// MARK: - Subscription status (account)

struct SubscriptionStatusRows: View {
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var lines: [SubscriptionLine] = []

    var body: some View {
        ForEach(lines) { line in
            LabeledContent(line.title, value: line.text)
        }
        .task(id: premiumStore.isPro || premiumStore.hasAISkills) { await load() }
    }

    private func load() async {
        var found: [SubscriptionLine] = []
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result, transaction.productType == .autoRenewable,
                  transaction.revocationDate == nil, let expires = transaction.expirationDate,
                  let id = StoreProductID(rawValue: transaction.productID) else { continue }
            var renews = true
            if let group = transaction.subscriptionGroupID,
               let statuses = try? await Product.SubscriptionInfo.status(for: group) {
                for status in statuses {
                    if case .verified(let info) = status.renewalInfo, info.currentProductID == transaction.productID {
                        renews = info.willAutoRenew
                    }
                }
            }
            found.append(SubscriptionLine(title: id.offer.title, date: expires, renews: renews))
        }
        lines = found
    }
}
