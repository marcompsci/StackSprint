import Charts
import SwiftUI

// MARK: - Complete the code (in the lesson)

struct CompleteTheCodeCard: View {
    let lesson: Lesson
    @EnvironmentObject var store: LearningStore
    @State private var typed = ""
    @State private var checked: Bool?
    @FocusState private var focused: Bool

    var body: some View {
        if let cloze = CodeClozeBuilder.make(for: lesson) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Complete the code", systemImage: "curlybraces.square.fill").font(.headline)
                Text("Fill in the missing word from the example above, from memory.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(cloze.prompt)
                    .font(.system(.callout, design: .monospaced))
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("Code with a blank: \(cloze.prompt.replacingOccurrences(of: "____", with: "blank"))")
                HStack {
                    TextField("Missing word", text: $typed)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                        .focused($focused)
                        .onSubmit { check(cloze) }
                        .padding(10)
                        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Button("Check") { check(cloze) }
                        .buttonStyle(.borderedProminent)
                        .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let checked {
                    Label(checked ? "Right: \(cloze.answer)" : "It's \(cloze.answer)",
                          systemImage: checked ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(checked ? Color.green : Color.orange)
                        .font(.subheadline.bold())
                }
            }
            .padding(16)
            .background(Color.mint.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .onChange(of: typed) { _, _ in checked = nil }
        }
    }

    private func check(_ cloze: CodeCloze) {
        guard !typed.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        focused = false
        let right = CodeClozeBuilder.isCorrect(typed, cloze)
        checked = right
        HapticManager.shared.notification(right ? .success : .warning)
        AccessibilityNotification.Announcement(right ? "Correct" : "The answer is \(cloze.answer)").post()
        if right { store.recordPractice() }
    }
}

// MARK: - Related lessons and teach a friend (in the lesson)

struct RelatedLessonsSection: View {
    let lesson: Lesson
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore

    var body: some View {
        let open = (store.curriculum?.lessons ?? []).filter { !premiumStore.isLocked($0.category) }
        let related = RelatedLessons.find(for: lesson, in: open)
        if !related.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Connects to", systemImage: "point.3.connected.trianglepath.dotted").font(.headline)
                Text("Linking a new idea to ones you know makes both easier to remember.")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(related) { other in
                    NavigationLink { LessonView(lesson: other) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(other.term).font(.subheadline.bold())
                                Text(other.clue).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer()
                            if store.completed.contains(other.id) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    .accessibilityLabel("Finished")
                            }
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TeachAFriendButton: View {
    let lesson: Lesson
    /// Drawn once per lesson, not on every redraw of the lesson screen.
    @State private var image: Image?

    var body: some View {
        Group {
            if let image {
            ShareLink(item: image, preview: SharePreview("\(lesson.term) in one card", image: image)) {
                Label("Teach a friend", systemImage: "person.2.wave.2.fill")
                    .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.bordered).tint(.indigo)
            .accessibilityHint("Shares a picture card explaining \(lesson.term)")
            }
        }
        .task(id: lesson.id) { image = render() }
    }

    private func render() -> Image? {
        let renderer = ImageRenderer(content: LessonShareCard(lesson: lesson))
        renderer.scale = 2
        return renderer.uiImage.map { Image(uiImage: $0) }
    }
}

/// A picture of one lesson to send to someone. Teaching others helps you remember too.
struct LessonShareCard: View {
    let lesson: Lesson

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(lesson.category.uppercased()).font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
            Text(lesson.term).font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(lesson.definition).font(.body).foregroundStyle(.white.opacity(0.92))
            if !lesson.code.isEmpty {
                Text(lesson.code).font(.system(.footnote, design: .monospaced)).foregroundStyle(.white)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
            }
            Spacer(minLength: 0)
            Text("Learned with StackSprint").font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
        }
        .padding(32)
        .frame(width: 560, height: 560, alignment: .topLeading)
        .background(LinearGradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.22), .indigo],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

// MARK: - Daily reflection

struct ReflectionCard: View {
    @EnvironmentObject var store: LearningStore
    @ObservedObject private var journal = JournalStore.shared
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        if store.practicedToday && journal.entry() == nil {
            VStack(alignment: .leading, spacing: 10) {
                Label("Today's reflection", systemImage: "book.closed.fill").font(.headline)
                Text(JournalPrompt.forDay(Date())).font(.subheadline)
                TextField("One sentence is enough", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .focused($focused)
                    .padding(10)
                    .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button("Save") {
                    journal.save(text)
                    focused = false
                    HapticManager.shared.notification(.success)
                }
                .buttonStyle(.borderedProminent).tint(.indigo)
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                Text("Taking a minute to reflect helps today's learning stick.").font(.caption).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct JournalView: View {
    @ObservedObject private var journal = JournalStore.shared

    var body: some View {
        List {
            if journal.sorted.isEmpty {
                ContentUnavailableView("No reflections yet", systemImage: "book.closed",
                                       description: Text("After you study, Learn asks one quick question about your day."))
            }
            ForEach(journal.sorted, id: \.day) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.display(entry.day)).font(.caption.bold()).foregroundStyle(.secondary)
                    Text(entry.text)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .navigationTitle("Reflections")
        .modifier(SprintTheme())
    }

    static func display(_ dayKey: String) -> String {
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .gregorian)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dayKey) else { return dayKey }
        return date.formatted(date: .complete, time: .omitted)
    }
}

// MARK: - Lesson of the day (Learn)

struct LessonOfTheDayCard: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @State private var revealed = false

    var body: some View {
        let open = (store.curriculum?.lessons ?? []).filter { store.completed.contains($0.id) && !premiumStore.isLocked($0.category) }
        if open.count >= 5, let id = LessonOfTheDay.pick(from: open.map(\.id)), let lesson = open.first(where: { $0.id == id }) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Lesson of the day", systemImage: "sun.max.fill").font(.headline).foregroundStyle(.yellow)
                Text(lesson.clue).font(.subheadline)
                if revealed {
                    Text(lesson.term).font(.title3.bold())
                    Text(LessonQuizBuilder.firstSentence(lesson.definition)).font(.subheadline).foregroundStyle(.secondary)
                } else {
                    Button("Say it in your head, then reveal") {
                        withAnimation(.smooth(duration: 0.2)) { revealed = true }
                        HapticManager.shared.selection()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .contain)
        }
    }
}

// MARK: - Memory: forecast and tough lessons

struct ReviewForecastSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var reviews = SM2Engine.shared

    var body: some View {
        let open = (store.curriculum?.lessons ?? []).filter { !premiumStore.isLocked($0.category) }
        let dates = open.compactMap { reviews.card(for: $0.id)?.dueDate }
        let days = ReviewForecast.days(dueDates: dates)
        if days.contains(where: { $0.count > 0 }) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Coming up").font(.headline)
                Chart(days, id: \.day) { item in
                    BarMark(x: .value("Day", item.day, unit: .day), y: .value("Reviews", item.count))
                        .foregroundStyle(Color.indigo)
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day, count: 3)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated)) } }
                .frame(height: 130)
                .accessibilityLabel("Reviews due over the next 14 days")
                .accessibilityValue(days.prefix(7).map { "\($0.count)" }.joined(separator: ", "))
                Text("Reviews due over the next two weeks. Doing a few each day keeps the pile small.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct ToughLessonsSection: View {
    @EnvironmentObject var store: LearningStore
    @EnvironmentObject var premiumStore: PremiumStore
    @ObservedObject private var mastery = MasteryStore.shared

    var body: some View {
        let lessons = store.curriculum?.lessons ?? []
        let tough = ToughLessons.find(records: mastery.records).compactMap { id in lessons.first { $0.id == id } }
            .filter { !premiumStore.isLocked($0.category) }
        if !tough.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tough lessons").font(.headline)
                Text("These keep slipping. More of the same won't fix it, so try a different angle:")
                    .font(.caption).foregroundStyle(.secondary)
                ForEach(ToughLessons.tips, id: \.self) { tip in
                    Text("\u{2022} \(tip)").font(.caption)
                }
                ForEach(tough.prefix(5)) { lesson in
                    NavigationLink { LessonView(lesson: lesson) } label: {
                        HStack {
                            Image(systemName: "tortoise.fill").foregroundStyle(.orange)
                            Text(lesson.term).font(.subheadline.bold())
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(SprintPalette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
