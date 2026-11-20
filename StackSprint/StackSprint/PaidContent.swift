import Foundation

// MARK: - Paid lesson tracks
//
// Two tracks that ship in the app but open only after purchase:
// • Professional Practice — a one-time purchase: how working developers use Git,
//   tests, reviews, debugging and deployment.
// • AI Skills — a subscription: how to prompt AI clearly, check what it says, and
//   use it safely and fairly. Written for beginners; original content.
//
// Lessons use the same shape as the free curriculum, so search, flash cards,
// quizzes, spaced review and the end-of-lesson quiz all work on them.

enum PaidContent {
    static let professionalTrack = "Professional Practice"
    static let aiTrack = "AI Skills"

    static let lessons: [Lesson] = professional + ai

    // MARK: Professional Practice

    static let professional: [Lesson] = [
        Lesson(id: "pro-git-commit", term: "Commit", category: professionalTrack,
               clue: "A saved snapshot of your project with a message explaining the change.",
               definition: "A commit records a set of changes in Git with a short message saying why. Small, focused commits make history easy to read and easy to undo.",
               code: "git add login.swift\ngit commit -m \"Fix crash when password is empty\"", difficulty: "beginner"),
        Lesson(id: "pro-git-branch", term: "Branch", category: professionalTrack,
               clue: "A separate line of work so your change doesn't disturb the main code.",
               definition: "A branch lets you build a feature or fix in isolation. When it's ready and reviewed, it's merged back into the main branch.",
               code: "git switch -c fix-empty-password\n# edit, commit, then open a pull request", difficulty: "beginner"),
        Lesson(id: "pro-pull-request", term: "Pull request", category: professionalTrack,
               clue: "A request for teammates to review your branch before it's merged.",
               definition: "A pull request shows your changes, explains what and why, and collects review comments. Keep them small so reviewers can understand them in one sitting.",
               code: "Title: Fix crash when password is empty\nWhy: users saw a crash on the login screen\nHow to test: leave the password blank and tap Sign in", difficulty: "beginner"),
        Lesson(id: "pro-code-review", term: "Code review", category: professionalTrack,
               clue: "Another developer reads your change to catch problems early.",
               definition: "In a code review, teammates check correctness, readability and risk. Good reviews are specific and kind, and they ask questions instead of only giving orders.",
               code: "// Review comment\n// What happens here if the list is empty?\n// Could we add a test for that case?", difficulty: "intermediate"),
        Lesson(id: "pro-unit-test", term: "Unit test", category: professionalTrack,
               clue: "A small automatic check that one function gives the right answer.",
               definition: "A unit test runs one piece of code with known input and checks the output. Tests catch mistakes the moment they happen, long before users do.",
               code: "func testTotalAddsTax() {\n    XCTAssertEqual(total(price: 100, taxRate: 0.1), 110)\n}", difficulty: "intermediate"),
        Lesson(id: "pro-ci", term: "Continuous integration", category: professionalTrack,
               clue: "Every change is built and tested automatically on a server.",
               definition: "Continuous integration (CI) builds the project and runs the tests for every push, so a broken change is spotted within minutes instead of on release day.",
               code: "on: push\njobs:\n  test:\n    steps:\n      - run: swift test", difficulty: "intermediate"),
        Lesson(id: "pro-debugging", term: "Debugging", category: professionalTrack,
               clue: "Finding why code misbehaves by forming a guess and testing it.",
               definition: "Good debugging is a loop: reproduce the bug, form one guess about the cause, test that guess with a breakpoint or a log, and change one thing at a time.",
               code: "print(\"cart count:\", cart.count)  // check your guess\n// breakpoint here, then inspect cart", difficulty: "beginner"),
        Lesson(id: "pro-readable-code", term: "Readable code", category: professionalTrack,
               clue: "Code that the next person (or you, later) can understand quickly.",
               definition: "Readable code uses clear names, short functions that do one thing, and comments that explain why rather than what. Code is read far more often than it's written.",
               code: "// Hard to read\nlet d = t * 86400\n// Clear\nlet secondsInDays = days * secondsPerDay", difficulty: "beginner"),
        Lesson(id: "pro-env-secrets", term: "Secrets", category: professionalTrack,
               clue: "Passwords and API keys that must never be committed to code.",
               definition: "Secrets such as API keys belong in environment variables or a secrets manager, never in the repository. Once a secret is pushed, assume it's leaked and replace it.",
               code: "let key = ProcessInfo.processInfo.environment[\"API_KEY\"]\n// never: let key = \"sk_live_123...\"", difficulty: "intermediate"),
        Lesson(id: "pro-semver", term: "Semantic versioning", category: professionalTrack,
               clue: "Version numbers like 2.4.1 that say what kind of change a release is.",
               definition: "Semantic versioning uses MAJOR.MINOR.PATCH: a major change can break things, a minor one adds features, and a patch fixes bugs without changing behaviour.",
               code: "1.4.2  ->  1.4.3   bug fix\n1.4.3  ->  1.5.0   new feature\n1.5.0  ->  2.0.0   breaking change", difficulty: "beginner"),
        Lesson(id: "pro-accessibility", term: "Accessibility", category: professionalTrack,
               clue: "Making software usable by people with different abilities.",
               definition: "Accessible apps work with screen readers, larger text and other settings. Label buttons, don't rely on colour alone, and test with VoiceOver turned on.",
               code: "Button(action: share) { Image(systemName: \"square.and.arrow.up\") }\n    .accessibilityLabel(\"Share\")", difficulty: "intermediate"),
        Lesson(id: "pro-logging", term: "Logging", category: professionalTrack,
               clue: "Recording what your app did so problems can be traced later.",
               definition: "Logs record important events with enough context to understand failures. Log what happened and why it matters, and never log passwords or personal data.",
               code: "logger.error(\"Payment failed: \\(error.localizedDescription)\")\n// not: logger.info(\"card \\(cardNumber)\")", difficulty: "intermediate"),
    ]

    // MARK: AI Skills

    static let ai: [Lesson] = [
        Lesson(id: "ai-what-is-llm", term: "Language model", category: aiTrack,
               clue: "The kind of AI that writes text by predicting what comes next.",
               definition: "A large language model learned patterns from huge amounts of text and writes by predicting likely next words. It can be very helpful, but it can also sound confident while being wrong.",
               code: "", difficulty: "beginner"),
        Lesson(id: "ai-right-job", term: "Choosing the job", category: aiTrack,
               clue: "Deciding which parts of a task AI should help with and which you should do.",
               definition: "AI is great for drafts, ideas, summaries and explanations. Keep the decisions, facts that matter and personal judgment for yourself, and always stay responsible for the result.",
               code: "Good fit: \"Give me 5 title ideas for my essay.\"\nKeep for yourself: deciding which facts are true", difficulty: "beginner"),
        Lesson(id: "ai-clear-ask", term: "Clear instructions", category: aiTrack,
               clue: "Saying exactly what you want, as you would to a new teammate.",
               definition: "The clearer the request, the better the answer. Say the task, who it's for, how long it should be and what a good result looks like.",
               code: "Weak: \"Write about dogs.\"\nClear: \"Write a 100-word intro about adopting rescue dogs for first-time owners. Friendly tone.\"", difficulty: "beginner"),
        Lesson(id: "ai-context", term: "Context", category: aiTrack,
               clue: "Background information that helps the AI give a useful answer.",
               definition: "AI only knows what you tell it about your situation. Share the goal, the audience and why you need it, so the answer fits your real need.",
               code: "\"I'm a nurse writing a note for patients' families. Explain what a CT scan is in plain words, under 80 words.\"", difficulty: "beginner"),
        Lesson(id: "ai-examples", term: "Examples", category: aiTrack,
               clue: "Showing a sample of the answer you want.",
               definition: "Giving one to three examples of the style or format you want is one of the most reliable ways to get it. Use varied examples so the AI copies the pattern, not one detail.",
               code: "\"Turn these into short headlines.\nExample: 'Team wins final game' -> 'Champions!'\nNow: 'City opens new library'\"", difficulty: "beginner"),
        Lesson(id: "ai-structure", term: "Structured prompt", category: aiTrack,
               clue: "Separating instructions, material and questions so nothing gets mixed up.",
               definition: "Put long material in clearly marked sections, for example with labels or tags, and put your question after it. Structure helps the AI tell your instructions apart from your content.",
               code: "<article>\n...paste the article...\n</article>\nSummarize the article above in 3 bullet points.", difficulty: "intermediate"),
        Lesson(id: "ai-role", term: "Giving a role", category: aiTrack,
               clue: "Telling the AI what kind of expert or helper to act as.",
               definition: "A role such as \"patient math tutor\" or \"careful editor\" sets the tone and focus. It works best when combined with a clear task and audience.",
               code: "\"You are a patient math tutor for a 12-year-old. Explain fractions with a pizza example.\"", difficulty: "beginner"),
        Lesson(id: "ai-step-by-step", term: "Step-by-step thinking", category: aiTrack,
               clue: "Asking the AI to work through a problem before answering.",
               definition: "For problems with several steps, ask the AI to think it through first and then give the answer. It makes mistakes easier to spot and often improves the result.",
               code: "\"Work through this step by step, then give the final answer on its own line: ...\"", difficulty: "intermediate"),
        Lesson(id: "ai-iterate", term: "Iterating", category: aiTrack,
               clue: "Improving the answer by giving feedback and asking again.",
               definition: "The first answer is a draft. Say what to keep, what to change and why, and ask for a new version. Small, specific feedback works better than starting over.",
               code: "\"Good start. Keep the first paragraph, make the rest half as long, and add one real-world example.\"", difficulty: "beginner"),
        Lesson(id: "ai-hallucination", term: "Hallucination", category: aiTrack,
               clue: "When AI states something false as if it were true.",
               definition: "AI can invent facts, quotes, numbers and sources that look real. Check anything important against a trusted source, and ask the AI to say when it isn't sure.",
               code: "\"If you're not sure about a fact, say so instead of guessing. List the claims I should double-check.\"", difficulty: "beginner"),
        Lesson(id: "ai-checking", term: "Checking answers", category: aiTrack,
               clue: "Reviewing what the AI produced before you use it.",
               definition: "Before using an answer, check that it's accurate, complete and fits your goal. Test code, verify facts and reread anything you'll share with others.",
               code: "Checklist: Is it true? Is anything missing? Does it fit my audience? Would I sign my name to it?", difficulty: "beginner"),
        Lesson(id: "ai-privacy", term: "Protecting private data", category: aiTrack,
               clue: "Keeping passwords, personal details and confidential work out of prompts.",
               definition: "Don't paste passwords, ID numbers, health or financial details, or confidential work into AI tools unless you know how that data is handled. Remove names and details when you can.",
               code: "Instead of: \"Here's my client John Smith's contract...\"\nTry: \"Here's a contract with names removed...\"", difficulty: "beginner"),
        Lesson(id: "ai-bias", term: "Bias", category: aiTrack,
               clue: "When answers unfairly favour or stereotype some groups of people.",
               definition: "AI learns from human writing, so it can repeat unfair stereotypes. Watch for one-sided answers, ask for other perspectives, and don't use AI alone for decisions about people.",
               code: "\"Review this job ad for wording that might discourage some applicants, and suggest neutral alternatives.\"", difficulty: "intermediate"),
        Lesson(id: "ai-honesty", term: "Being open about AI use", category: aiTrack,
               clue: "Telling people when AI helped make something.",
               definition: "Follow the rules of your school, job or platform about AI use, and be open when AI helped. Present AI-assisted work honestly, and don't pass off AI writing as someone else's words.",
               code: "\"Drafted with help from an AI assistant and edited by me.\"", difficulty: "beginner"),
        Lesson(id: "ai-safe-use", term: "Using AI safely", category: aiTrack,
               clue: "Not using AI to hurt, trick or harass people.",
               definition: "Don't use AI to deceive people, impersonate someone, harass others or make harmful content. Be extra careful with medical, legal and money advice, and ask a qualified person when it matters.",
               code: "OK: \"Help me understand my lease in plain words.\"\nThen: confirm anything important with the landlord or a lawyer.", difficulty: "beginner"),
        Lesson(id: "ai-copyright", term: "Respecting creators", category: aiTrack,
               clue: "Not using AI to copy other people's books, songs or art.",
               definition: "Ask AI to help you create something original, summarise, or explain, not to reproduce someone else's protected work. Credit sources and the people whose ideas you build on.",
               code: "Instead of: \"Write out the lyrics to that song.\"\nTry: \"Explain what makes that song's chorus catchy.\"", difficulty: "beginner"),
    ]
}

// MARK: - Prompt makeovers (AI Skills practice)

struct PromptMakeover: Identifiable {
    let id: String
    let goal: String
    let weak: String
    let options: [String]
    let best: Int
    let why: String
}

enum PromptMakeovers {
    static let all: [PromptMakeover] = [
        PromptMakeover(id: "pm-1", goal: "A birthday message for a coworker",
                       weak: "write a birthday message",
                       options: ["write a really good birthday message",
                                 "Write a warm, 2-sentence birthday message for my coworker Sam, who loves hiking. Friendly but professional.",
                                 "birthday message coworker hiking"],
                       best: 1, why: "It says who it's for, the length, a personal detail and the tone."),
        PromptMakeover(id: "pm-2", goal: "Understand a confusing bill",
                       weak: "explain this",
                       options: ["Explain the charges on this phone bill in plain words and point out anything unusual. [bill text with account number removed]",
                                 "explain this bill and also my account number is 4421...",
                                 "is my bill wrong"],
                       best: 0, why: "It gives the task and the material, asks for plain words, and leaves private numbers out."),
        PromptMakeover(id: "pm-3", goal: "Study for a biology test",
                       weak: "teach me biology",
                       options: ["teach me all of biology fast",
                                 "Quiz me with 5 questions on photosynthesis, one at a time. After each answer, tell me if I'm right and why.",
                                 "photosynthesis"],
                       best: 1, why: "It's specific, active (a quiz), and asks for feedback on each answer — the best way to remember."),
        PromptMakeover(id: "pm-4", goal: "Fix a bug in your code",
                       weak: "my code doesn't work",
                       options: ["Here's my Swift function and the error 'Index out of range' on line 4. Explain the cause and suggest a fix. [code]",
                                 "fix it",
                                 "why is coding so hard"],
                       best: 0, why: "It includes the code, the exact error and where it happens."),
        PromptMakeover(id: "pm-5", goal: "A summary you'll share at work",
                       weak: "summarize this report",
                       options: ["summarize",
                                 "Summarize this report in 3 bullet points for my manager, then list any numbers I should double-check against the original. [report]",
                                 "make the report shorter please thanks"],
                       best: 1, why: "It sets the format and audience, and builds in checking before you share it."),
        PromptMakeover(id: "pm-6", goal: "Ideas for a school project",
                       weak: "give me an idea",
                       options: ["Give me 5 project ideas about recycling for a 7th-grade science fair, each doable in two weeks with household materials.",
                                 "idea",
                                 "Write my whole science project for me so I can hand it in."],
                       best: 0, why: "It asks for ideas you'll build yourself, with clear limits — and doesn't hand off your own work."),
        PromptMakeover(id: "pm-7", goal: "Get facts you can trust",
                       weak: "tell me facts about vitamin D",
                       options: ["give me lots of facts",
                                 "List 3 well-established facts about vitamin D, say how confident you are in each, and tell me which ones I should confirm with a doctor or trusted health site.",
                                 "vitamin D cures everything right?"],
                       best: 1, why: "It asks the AI to show its confidence and points you to check health facts with a reliable source."),
        PromptMakeover(id: "pm-8", goal: "Match a writing style",
                       weak: "write product descriptions",
                       options: ["Write a product description for my candle like these two examples: [example 1] [example 2]. Same length and tone.",
                                 "write product descriptions that are good",
                                 "Copy the description from a famous brand's website."],
                       best: 0, why: "Examples show the style you want, and it stays original instead of copying another brand."),
    ]
}
