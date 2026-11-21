import Combine
import Foundation

// MARK: - Phases 146–170: practice arcade, projects and motivation
//
// • Predict the output: reading code and predicting what it does before running it
//   is how programmers build a mental model of code ("tracing").
// • Error decoder: matching error messages to their causes, a skill beginners lack most.
// • Match and speed rounds: quick, game-like retrieval of terms you've learned.
// • Mini projects: apply several lessons together (project-based learning).
// • Your "why": a personal reason, shown back at you in reminders.
// • Accountability buddy: share your week with someone who'll check in.

// MARK: - Predict the output

struct PredictItem: Identifiable {
    let id: String
    let language: String
    let code: String
    let options: [String]
    let answer: Int
    let why: String
}

enum PredictOutput {
    static let all: [PredictItem] = [
        PredictItem(id: "po-1", language: "Python", code: "x = 3\nx = x * 2 + 1\nprint(x)",
                    options: ["7", "9", "6", "x"], answer: 0, why: "Multiplication happens before addition: 3 × 2 = 6, then 6 + 1 = 7."),
        PredictItem(id: "po-2", language: "JavaScript", code: "const items = [\"a\", \"b\", \"c\"];\nconsole.log(items.length);",
                    options: ["2", "3", "4", "undefined"], answer: 1, why: "length counts the items: there are three."),
        PredictItem(id: "po-3", language: "Swift", code: "var total = 0\nfor n in 1...3 {\n    total += n\n}\nprint(total)",
                    options: ["3", "5", "6", "0"], answer: 2, why: "1...3 includes 3, so the loop adds 1 + 2 + 3 = 6."),
        PredictItem(id: "po-4", language: "Python", code: "name = \"Ada\"\nprint(name[0])",
                    options: ["A", "Ada", "d", "Error"], answer: 0, why: "Indexes start at 0, so name[0] is the first character."),
        PredictItem(id: "po-5", language: "JavaScript", code: "console.log(\"5\" + 1);",
                    options: ["6", "51", "Error", "NaN"], answer: 1, why: "With a string on one side, + joins text: \"5\" + 1 becomes \"51\"."),
        PredictItem(id: "po-6", language: "Python", code: "nums = [4, 1, 3]\nnums.sort()\nprint(nums[-1])",
                    options: ["1", "3", "4", "Error"], answer: 2, why: "After sorting the list is [1, 3, 4], and -1 means the last item."),
        PredictItem(id: "po-7", language: "Swift", code: "let age = 17\nprint(age >= 18 ? \"adult\" : \"minor\")",
                    options: ["adult", "minor", "true", "17"], answer: 1, why: "17 isn't 18 or more, so the ternary picks the second value."),
        PredictItem(id: "po-8", language: "JavaScript", code: "let count = 0;\nfunction add() { count++; }\nadd(); add();\nconsole.log(count);",
                    options: ["0", "1", "2", "undefined"], answer: 2, why: "Each call adds one to the same variable: called twice, so 2."),
        PredictItem(id: "po-9", language: "Python", code: "def greet(name=\"friend\"):\n    return \"Hi \" + name\nprint(greet())",
                    options: ["Hi ", "Hi friend", "Error", "Hi name"], answer: 1, why: "No argument was passed, so the default value \"friend\" is used."),
        PredictItem(id: "po-10", language: "TypeScript", code: "const scores = [2, 8, 5];\nconsole.log(scores.filter(s => s > 4).length);",
                    options: ["1", "2", "3", "0"], answer: 1, why: "filter keeps 8 and 5, so the length is 2."),
        PredictItem(id: "po-11", language: "Python", code: "word = \"code\"\nprint(word.upper())",
                    options: ["code", "CODE", "Code", "Error"], answer: 1, why: "upper() returns a copy in capital letters."),
        PredictItem(id: "po-12", language: "JavaScript", code: "const x = [1, 2, 3].map(n => n * 2);\nconsole.log(x[1]);",
                    options: ["2", "4", "6", "1"], answer: 1, why: "map doubles every item: [2, 4, 6]. Index 1 is the second item, 4."),
        PredictItem(id: "po-13", language: "Swift", code: "let names = [\"Bo\", \"Ana\"]\nprint(names.sorted().first!)",
                    options: ["Bo", "Ana", "nil", "[\"Ana\"]"], answer: 1, why: "sorted() puts \"Ana\" before \"Bo\" alphabetically."),
        PredictItem(id: "po-14", language: "Python", code: "for i in range(3):\n    pass\nprint(i)",
                    options: ["3", "2", "0", "Error"], answer: 1, why: "range(3) is 0, 1, 2. After the loop, i keeps its last value, 2."),
        PredictItem(id: "po-15", language: "JavaScript", code: "console.log(0.1 + 0.2 === 0.3);",
                    options: ["true", "false", "0.3", "Error"], answer: 1, why: "Floating-point maths gives 0.30000000000000004, so the strict comparison is false."),
        PredictItem(id: "po-16", language: "Python", code: "d = {\"a\": 1}\nprint(d.get(\"b\", 0))",
                    options: ["None", "0", "Error", "1"], answer: 1, why: "get returns the default (0) when the key is missing, instead of raising an error."),
        PredictItem(id: "po-17", language: "TypeScript", code: "let total: number = 10;\ntotal += 5;\nconsole.log(`Total: ${total}`);",
                    options: ["Total: 105", "Total: 15", "Total: ${total}", "Error"], answer: 1, why: "+= adds to the number, and the template literal puts 15 into the text."),
        PredictItem(id: "po-18", language: "Swift", code: "var a = [1, 2]\nvar b = a\nb.append(3)\nprint(a.count)",
                    options: ["2", "3", "1", "Error"], answer: 0, why: "Swift arrays are values: b is a copy, so changing b doesn't change a."),
        PredictItem(id: "po-19", language: "JavaScript", code: "const user = { name: \"Sam\" };\nconsole.log(user.age ?? \"unknown\");",
                    options: ["undefined", "unknown", "null", "Error"], answer: 1, why: "?? uses the right side when the left is null or undefined."),
        PredictItem(id: "po-20", language: "Python", code: "nums = [1, 2, 3, 4]\nprint(nums[1:3])",
                    options: ["[1, 2, 3]", "[2, 3]", "[2, 3, 4]", "[1, 2]"], answer: 1, why: "A slice includes the start index and stops before the end: items 1 and 2."),
    ]
}

// MARK: - Error decoder

struct ErrorItem: Identifiable {
    let id: String
    let message: String
    let options: [String]
    let answer: Int
    let fix: String
}

enum ErrorDecoder {
    static let all: [ErrorItem] = [
        ErrorItem(id: "ed-1", message: "TypeError: Cannot read properties of undefined (reading 'name')",
                  options: ["A variable is undefined, so it has no .name", "The name is misspelled in CSS", "The internet is down"],
                  answer: 0, fix: "Check the value exists before using it, e.g. user?.name, and find why it's missing."),
        ErrorItem(id: "ed-2", message: "IndentationError: expected an indented block",
                  options: ["A Python block (after a colon) has no indented line", "A file is missing", "A number is too big"],
                  answer: 0, fix: "Indent the lines that belong to the if, for or def, usually by 4 spaces."),
        ErrorItem(id: "ed-3", message: "Fatal error: Index out of range",
                  options: ["Asked for an array position that doesn't exist", "The phone ran out of memory", "A string is empty"],
                  answer: 0, fix: "Check the index is below count, or use .first / .last which return nil safely."),
        ErrorItem(id: "ed-4", message: "ReferenceError: total is not defined",
                  options: ["total is used before it was declared, or is out of scope", "total is a number", "The browser is outdated"],
                  answer: 0, fix: "Declare it with let or const first, in a scope where the code can see it."),
        ErrorItem(id: "ed-5", message: "404 Not Found",
                  options: ["The address points to something that doesn't exist on the server", "Your password is wrong", "The server crashed"],
                  answer: 0, fix: "Check the URL or route path. A 5xx code would mean the server failed; 401/403 means not allowed."),
        ErrorItem(id: "ed-6", message: "ModuleNotFoundError: No module named 'requests'",
                  options: ["The package isn't installed in this environment", "The file has a typo on line 1", "Python is too new"],
                  answer: 0, fix: "Install it (pip install requests) in the same environment you run the code from."),
        ErrorItem(id: "ed-7", message: "Unexpectedly found nil while unwrapping an Optional value",
                  options: ["A force-unwrap (!) hit a missing value", "A loop ran forever", "The app has no internet"],
                  answer: 0, fix: "Use if let or guard let instead of !, and handle the missing case."),
        ErrorItem(id: "ed-8", message: "Access to fetch has been blocked by CORS policy",
                  options: ["The server doesn't allow requests from this website's origin", "The JSON is invalid", "The user is offline"],
                  answer: 0, fix: "The server must send the right Access-Control-Allow-Origin header; it can't be fixed from the browser alone."),
        ErrorItem(id: "ed-9", message: "SyntaxError: Unexpected token '}'",
                  options: ["A bracket or brace is missing or extra nearby", "The variable name is too long", "The server returned an error"],
                  answer: 0, fix: "Check the lines just above for an unclosed ( or { or a missing comma."),
        ErrorItem(id: "ed-10", message: "TypeError: can only concatenate str (not \"int\") to str",
                  options: ["Text and a number were joined with + without converting", "The string is empty", "Python is out of memory"],
                  answer: 0, fix: "Convert first: \"Age: \" + str(age), or use an f-string: f\"Age: {age}\"."),
        ErrorItem(id: "ed-11", message: "401 Unauthorized",
                  options: ["The request has no valid sign-in or API key", "The page doesn't exist", "The server crashed"],
                  answer: 0, fix: "Send valid credentials (a token or key). 403 would mean signed in but not allowed."),
        ErrorItem(id: "ed-12", message: "error: cannot find 'scroe' in scope",
                  options: ["A name is misspelled or declared somewhere this code can't see", "The app needs more memory", "An internet connection is required"],
                  answer: 0, fix: "Fix the spelling (score) or move the declaration where this code can use it."),
        ErrorItem(id: "ed-13", message: "KeyError: 'email'",
                  options: ["The dictionary has no 'email' key", "The email address is invalid", "The file is read-only"],
                  answer: 0, fix: "Check the key exists, or use .get(\"email\") which returns None instead of failing."),
        ErrorItem(id: "ed-14", message: "Maximum call stack size exceeded",
                  options: ["A function keeps calling itself with no way to stop", "The array has too many items", "The browser tab is too small"],
                  answer: 0, fix: "Give the recursion a base case that returns without calling itself again."),
    ]

    /// The options in a stable but mixed order, so the answer isn't always first.
    static func shuffled(_ item: ErrorItem) -> (options: [String], answer: Int) {
        var rng = SeededGenerator(seed: "error|\(item.id)")
        let options = item.options.shuffled(using: &rng)
        return (options, options.firstIndex(of: item.options[item.answer]) ?? 0)
    }
}

// MARK: - Match pairs

struct MatchRound: Equatable {
    let terms: [String]
    /// Clues in a different order from the terms.
    let clues: [String]
    let pairs: [String: String]
}

enum MatchGame {
    static func make(from lessons: [Lesson], size: Int = 5, seed: String) -> MatchRound? {
        var rng = SeededGenerator(seed: "match|\(seed)")
        var seenTerms = Set<String>(), seenClues = Set<String>()
        let unique = lessons.filter { seenTerms.insert($0.term).inserted && seenClues.insert($0.clue).inserted }
        guard unique.count >= size else { return nil }
        let picked = Array(unique.shuffled(using: &rng).prefix(size))
        var clues = picked.map(\.clue).shuffled(using: &rng)
        if clues == picked.map(\.clue) { clues.append(clues.removeFirst()) }
        return MatchRound(terms: picked.map(\.term), clues: clues,
                          pairs: Dictionary(uniqueKeysWithValues: picked.map { ($0.term, $0.clue) }))
    }
}

// MARK: - Speed round

struct SpeedStatement: Equatable {
    let term: String
    let clue: String
    let isTrue: Bool
}

enum SpeedRound {
    static let seconds = 60
    static let bestKey = "speed.best"

    /// True/false statements: about half pair a term with its own clue, the rest with another lesson's.
    static func make(from lessons: [Lesson], count: Int = 40, seed: String) -> [SpeedStatement] {
        guard lessons.count >= 4 else { return [] }
        var rng = SeededGenerator(seed: "speed|\(seed)")
        return (0..<count).map { _ in
            let lesson = lessons.randomElement(using: &rng)!
            if Bool.random(using: &rng) { return SpeedStatement(term: lesson.term, clue: lesson.clue, isTrue: true) }
            let other = lessons.filter { $0.clue != lesson.clue }.randomElement(using: &rng)!
            return SpeedStatement(term: lesson.term, clue: other.clue, isTrue: false)
        }
    }
}

// MARK: - Mini projects

struct MiniProject: Identifiable {
    let id: String
    let track: String
    let title: String
    let summary: String
    let steps: [String]
}

enum MiniProjects {
    static let all: [MiniProject] = [
        MiniProject(id: "mp-web", track: "Web development", title: "A personal profile page",
                    summary: "One HTML page with your name, a short bio and links, styled with CSS.",
                    steps: ["Write the HTML structure: header, main, footer", "Add a heading, a paragraph and a list of links",
                            "Style it with a font, colours and spacing in CSS", "Make it readable on a phone (max-width and padding)",
                            "Check it with a screen reader or the accessibility inspector"]),
        MiniProject(id: "mp-python", track: "Python", title: "A tip calculator",
                    summary: "A script that asks for a bill and a tip percentage, and prints the total.",
                    steps: ["Read the bill and percentage with input()", "Convert the text to numbers with float()",
                            "Calculate the tip and total in a function", "Round to 2 decimal places when printing",
                            "Handle a bad entry (like letters) without crashing"]),
        MiniProject(id: "mp-swift", track: "Swift", title: "A counter app",
                    summary: "A SwiftUI screen with a number and buttons to add, subtract and reset.",
                    steps: ["Store the count with @State", "Show it in a big Text", "Add +, − and Reset buttons",
                            "Stop the count going below zero", "Give each button an accessibility label"]),
        MiniProject(id: "mp-ts", track: "TypeScript", title: "A typed to-do list",
                    summary: "A small list where each to-do has a title and a done flag, with types for both.",
                    steps: ["Define a Todo type with title: string and done: boolean", "Write addTodo and toggleTodo functions",
                            "Filter to show only unfinished items", "Count how many are done", "Let the compiler catch a wrong property name"]),
        MiniProject(id: "mp-security", track: "Cybersecurity", title: "Secure your own accounts",
                    summary: "Apply the lessons to your real life, one account at a time.",
                    steps: ["Turn on two-factor sign-in for your email", "Switch to a password manager for new passwords",
                            "Check your email on a breach-notification site", "Review which apps can see your location",
                            "Update your phone and browser"]),
        MiniProject(id: "mp-react", track: "React", title: "A like button",
                    summary: "A component that counts likes and remembers if you liked it.",
                    steps: ["Make a LikeButton component", "Keep the count in useState", "Toggle liked/unliked on click",
                            "Show a filled heart when liked", "Pass the starting count in as a prop"]),
        MiniProject(id: "mp-go", track: "Go", title: "A word counter",
                    summary: "A command-line program that counts the words in some text.",
                    steps: ["Read text from standard input", "Split it into words with strings.Fields", "Count each word in a map",
                            "Print the five most common words", "Write a test for the counting function"]),
    ]
}

@MainActor final class MiniProjectStore: ObservableObject {
    static let shared = MiniProjectStore()
    static let key = "miniProjects.doneSteps"
    /// "projectID|stepIndex" for every ticked step.
    @Published private(set) var done: Set<String> = []

    init(defaults: UserDefaults = .standard) {
        done = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    func toggle(_ project: MiniProject, step: Int) {
        let key = "\(project.id)|\(step)"
        if done.contains(key) { done.remove(key) } else { done.insert(key) }
        persist()
    }

    func isDone(_ project: MiniProject, step: Int) -> Bool { done.contains("\(project.id)|\(step)") }

    func progress(_ project: MiniProject) -> Int {
        project.steps.indices.filter { isDone(project, step: $0) }.count
    }

    func isComplete(_ project: MiniProject) -> Bool { progress(project) == project.steps.count }
    var completedCount: Int { MiniProjects.all.filter { isComplete($0) }.count }

    func merge(_ incoming: [String]) { done.formUnion(incoming); persist() }
    func eraseAll() { done = []; persist() }
    private func persist() { UserDefaults.standard.set(Array(done).sorted(), forKey: Self.key) }
}

// MARK: - Your "why"

enum LearningWhy: String, CaseIterable, Identifiable {
    case career, school, project, curiosity
    static let key = "goal.why"
    var id: String { rawValue }

    var label: String {
        switch self {
        case .career: return "Change or grow my career"
        case .school: return "Do well in school"
        case .project: return "Build my own app or site"
        case .curiosity: return "I'm curious"
        }
    }

    var icon: String {
        switch self {
        case .career: return "briefcase.fill"
        case .school: return "graduationcap.fill"
        case .project: return "hammer.fill"
        case .curiosity: return "sparkles"
        }
    }

    /// A good first track for this goal.
    var suggestedTrack: String {
        switch self {
        case .career: return "Interview Prep"
        case .school: return "Python"
        case .project: return "Web development"
        case .curiosity: return "Web development"
        }
    }

    /// Reminder wording that brings the learner's own reason back.
    var reminder: String {
        switch self {
        case .career: return "Every lesson is a step toward the job you want. Five minutes today?"
        case .school: return "A quick lesson now makes the next class easier."
        case .project: return "Your app gets closer with every lesson. Ready for the next piece?"
        case .curiosity: return "Something new to learn today. Five minutes?"
        }
    }
}

// MARK: - Accountability buddy

enum BuddyMessage {
    static func text(streak: Int, comparison: WeekComparison, why: LearningWhy?) -> String {
        var lines = ["My StackSprint week: \(comparison.thisWeek) \(comparison.thisWeek == 1 ? "lesson" : "lessons") (last week: \(comparison.lastWeek))."]
        if streak > 0 { lines.append("Current streak: \(streak) \(streak == 1 ? "day" : "days").") }
        if let why { lines.append("Why I'm doing this: \(why.label.lowercased()).") }
        lines.append("Can you check in with me next week to keep me on track?")
        return lines.joined(separator: " ")
    }
}

// MARK: - Quiz history export

enum QuizHistoryCSV {
    /// One row per lesson quiz, oldest first. Quotes fields that contain commas or quotes.
    static func make(records: [String: [LessonQuizRecord]], terms: [String: String]) -> String {
        func field(_ s: String) -> String {
            s.contains(",") || s.contains("\"") ? "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" : s
        }
        let formatter = ISO8601DateFormatter()
        var entries: [(id: String, record: LessonQuizRecord)] = []
        for (id, list) in records {
            for record in list { entries.append((id: id, record: record)) }
        }
        entries.sort { a, b in a.record.date == b.record.date ? a.id < b.id : a.record.date < b.record.date }
        var rows: [String] = []
        for entry in entries {
            let r = entry.record
            let sure = r.sureAnswers.map { String($0) } ?? ""
            let lucky = r.luckyGuesses.map { String($0) } ?? ""
            let confident = r.confidentMisses.map { String($0) } ?? ""
            let cells: [String] = [formatter.string(from: r.date), field(terms[entry.id] ?? entry.id),
                                   String(r.score), String(r.total), sure, lucky, confident]
            rows.append(cells.joined(separator: ","))
        }
        return (["date,lesson,score,total,sure_answers,lucky_guesses,confident_misses"] + rows).joined(separator: "\n") + "\n"
    }
}

// MARK: - Subscription status

struct SubscriptionLine: Identifiable, Equatable {
    let title: String
    let date: Date
    let renews: Bool
    var id: String { title }

    var text: String {
        "\(renews ? "Renews" : "Ends") \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

// MARK: - Due today (Siri)

enum DueToday {
    static func count(dueDates: [Date], now: Date = Date()) -> Int {
        dueDates.filter { $0 <= now }.count
    }

    static func dialog(_ count: Int) -> String {
        switch count {
        case 0: return "Nothing is due today. A new lesson is a good next step."
        case 1: return "1 lesson is due for review today."
        default: return "\(count) lessons are due for review today."
        }
    }
}
