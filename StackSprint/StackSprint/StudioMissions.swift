import SwiftUI
import UIKit
import WebKit

// MARK: - Missions
//
// Each mission is a short guided project with three steps. Every step's check
// runs inside the real page (the same one the preview shows) and looks at what
// the code actually does: computed colours and sizes for CSS, and what really
// happens when the target is tapped for JavaScript.

struct StudioMission: Identifiable, Equatable {
    struct Step: Equatable {
        let title: String
        let instruction: String
        let example: String
        /// JavaScript function body evaluated in the page; returns true when the step is done.
        let check: String
    }

    let id: String
    let track: ProjectTrack
    let number: Int
    let title: String
    let pageTitle: String
    let brief: String
    let starter: String
    let steps: [Step]

    static func == (lhs: StudioMission, rhs: StudioMission) -> Bool { lhs.id == rhs.id }

    static func missions(for track: ProjectTrack) -> [StudioMission] {
        track == .design ? cssMissions : jsMissions
    }

    // Helpers available to every check (prepended to each check body).
    static let checkHelpers = """
    const $ = (s) => document.querySelector(s);
    const css = (s, p) => getComputedStyle($(s)).getPropertyValue(p).trim();
    const rgb = (c) => (c.match(/[\\d.]+/g) || []).slice(0, 3).map(Number);
    const lum = (c) => { const [r, g, b] = rgb(c).map(v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }); return 0.2126 * r + 0.7152 * g + 0.0722 * b; };
    const contrast = (a, b) => { const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05); };
    const px = (v) => parseFloat(v) || 0;
    const tap = (n = 1) => { for (let i = 0; i < n; i++) $('.target').dispatchEvent(new MouseEvent('click', { bubbles: true })); };
    const val = (name) => { try { return eval(name); } catch (e) { return undefined; } };
    const wait = (ms) => new Promise(r => setTimeout(r, ms));
    """

    // MARK: CSS

    static let cssMissions: [StudioMission] = [
        StudioMission(
            id: "css-1", track: .design, number: 1, title: "Palette Pop", pageTitle: "Arcade Café",
            brief: "A small arcade café needs a three-colour look. Make one bright choice without losing readability.",
            starter: "/* Palette Pop */\n\n.arena {\n  /* background-color */\n}\n\n.target {\n  /* background-color */\n}\n\n.arena {\n  /* color */\n}\n",
            steps: [
                Step(title: "Set the background",
                     instruction: "Give .arena the background-color #172554.",
                     example: ".arena { background-color: #172554; }",
                     check: "return css('.arena', 'background-color') === 'rgb(23, 37, 84)';"),
                Step(title: "Make the target bright",
                     instruction: "Give .target a bright background-color so players know where to tap.",
                     example: ".target { background-color: #5eead4; }",
                     check: "const c = css('.target', 'background-color'); return c !== 'rgb(71, 85, 105)' && lum(c) > 0.3;"),
                Step(title: "Keep the text readable",
                     instruction: "Set a color on .arena that's easy to read on the dark background.",
                     example: ".arena { color: white; }",
                     check: "const c = css('.arena', 'color'); return c !== 'rgb(148, 163, 184)' && contrast(c, css('.arena', 'background-color')) >= 4.5;"),
            ]),
        StudioMission(
            id: "css-2", track: .design, number: 2, title: "Round and Raised", pageTitle: "Arcade Café",
            brief: "Turn the square target into a round button that sits up off the page.",
            starter: "/* Round and Raised */\n\n.target {\n  /* border-radius */\n  /* box-shadow */\n}\n\n.arena h1 {\n  /* font-size */\n}\n",
            steps: [
                Step(title: "Make it a circle",
                     instruction: "Set border-radius on .target to 50% so it becomes a circle.",
                     example: ".target { border-radius: 50%; }",
                     check: "const r = css('.target', 'border-top-left-radius'); return r.endsWith('%') ? px(r) >= 50 : px(r) >= $('.target').offsetWidth / 2;"),
                Step(title: "Lift it up",
                     instruction: "Give .target a box-shadow that's different from the default one.",
                     example: ".target { box-shadow: 0 12px 24px rgba(0, 0, 0, 0.4); }",
                     check: "const s = css('.target', 'box-shadow'); return s !== 'none' && !/0px 8px 0px 0px/.test(s);"),
                Step(title: "Bigger heading",
                     instruction: "Make the heading (.arena h1) at least 28px.",
                     example: ".arena h1 { font-size: 32px; }",
                     check: "return px(css('.arena h1', 'font-size')) >= 28;"),
            ]),
        StudioMission(
            id: "css-3", track: .design, number: 3, title: "Breathing Room", pageTitle: "Arcade Café",
            brief: "Give everything space, then make the target big enough to hit with a thumb.",
            starter: "/* Breathing Room */\n\n.arena {\n  /* padding */\n  /* gap */\n}\n\n.target {\n  /* width and height */\n}\n",
            steps: [
                Step(title: "Pad the arena",
                     instruction: "Give .arena at least 40px of padding.",
                     example: ".arena { padding: 48px; }",
                     check: "return px(css('.arena', 'padding-top')) >= 40 && px(css('.arena', 'padding-left')) >= 40;"),
                Step(title: "Space the items",
                     instruction: "Set gap on .arena to at least 28px.",
                     example: ".arena { gap: 32px; }",
                     check: "return px(css('.arena', 'row-gap')) >= 28;"),
                Step(title: "Thumb-sized target",
                     instruction: "Make .target at least 160px wide and 160px tall.",
                     example: ".target { width: 160px; height: 160px; }",
                     check: "const t = $('.target'); return t.offsetWidth >= 160 && t.offsetHeight >= 160;"),
            ]),
        StudioMission(
            id: "css-4", track: .design, number: 4, title: "Press Feel", pageTitle: "Arcade Café",
            brief: "The page adds the class is-hit while the target is pressed. Style that moment so a tap feels physical.",
            starter: "/* Press Feel */\n\n.target {\n  /* transition */\n}\n\n.target.is-hit {\n  /* background-color */\n  /* transform */\n}\n",
            steps: [
                Step(title: "Quick transition",
                     instruction: "Give .target a transition between 0.05s and 0.4s long.",
                     example: ".target { transition: transform 0.1s, background-color 0.1s; }",
                     check: "const d = css('.target', 'transition-duration').split(',').map(v => parseFloat(v) * (v.includes('ms') ? 0.001 : 1)); return d.some(v => v >= 0.05 && v <= 0.4) && css('.target', 'transition-duration') !== '0.08s, 0.08s, 0.25s';"),
                Step(title: "Change colour when pressed",
                     instruction: "Give .target.is-hit a different background-color.",
                     example: ".target.is-hit { background-color: #2dd4bf; }",
                     check: "const t = $('.target'); t.style.transition = 'none'; const a = css('.target', 'background-color'); t.classList.add('is-hit'); const b = css('.target', 'background-color'); t.classList.remove('is-hit'); t.style.transition = ''; return a !== b;"),
                Step(title: "Push it down",
                     instruction: "Give .target.is-hit a transform, like a slight scale down.",
                     example: ".target.is-hit { transform: scale(0.94); }",
                     check: "const t = $('.target'); t.style.transition = 'none'; t.classList.add('is-hit'); const v = css('.target', 'transform'); t.classList.remove('is-hit'); t.style.transition = ''; return v !== 'none' && v !== 'matrix(0.97, 0, 0, 0.97, 0, 6)';"),
            ]),
        StudioMission(
            id: "css-5", track: .design, number: 5, title: "One Accent", pageTitle: "Arcade Café",
            brief: "Pick one accent colour, store it in a CSS variable, and use it in two places.",
            starter: "/* One Accent */\n\n:root {\n  /* --accent */\n}\n\n.target {\n  /* use the accent */\n}\n\n.score {\n  /* use the accent */\n}\n",
            steps: [
                Step(title: "Define the accent",
                     instruction: "Add a --accent variable to :root with a colour value.",
                     example: ":root { --accent: #f472b6; }",
                     check: "const v = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim(); if (!v) return false; const p = document.createElement('i'); p.style.color = v; return p.style.color !== '';"),
                Step(title: "Use it on the target",
                     instruction: "Set .target's background-color to var(--accent).",
                     example: ".target { background-color: var(--accent); }",
                     check: "const p = document.createElement('i'); p.style.color = 'var(--accent)'; document.body.append(p); const accent = getComputedStyle(p).color; p.remove(); return css('.target', 'background-color') === accent;"),
                Step(title: "Use it again",
                     instruction: "Set .score's color to var(--accent) too.",
                     example: ".score { color: var(--accent); }",
                     check: "const p = document.createElement('i'); p.style.color = 'var(--accent)'; document.body.append(p); const accent = getComputedStyle(p).color; p.remove(); return css('.score', 'color') === accent;"),
            ]),
    ]

    // MARK: JavaScript

    static let jsMissions: [StudioMission] = [
        StudioMission(
            id: "js-1", track: .build, number: 1, title: "Tap Dash", pageTitle: "Tap Dash",
            brief: "Build a one-button reflex game: tap the target, count the score, keep a game loop running.",
            starter: "// Tap Dash\n\nlet score = 0;\n\nconst target = document.querySelector('.target');\n\n// 1. Respond to a tap\n// 2. Add one to the score\n// 3. Start a game loop\n",
            steps: [
                Step(title: "Respond to a tap",
                     instruction: "Add a click listener to target.",
                     example: "target.addEventListener('click', hit);",
                     check: "return window.__ss.listeners > 0 || typeof $('.target').onclick === 'function';"),
                Step(title: "Count the score",
                     instruction: "Inside your listener, add one to score.",
                     example: "function hit() {\n  score += 1;\n}",
                     check: "if (typeof val('score') !== 'number') return false; const before = val('score'); tap(); return val('score') > before;"),
                Step(title: "Start a game loop",
                     instruction: "Call requestAnimationFrame with a function that calls it again.",
                     example: "function loop() {\n  requestAnimationFrame(loop);\n}\nrequestAnimationFrame(loop);",
                     check: "await wait(120); return window.__ss.raf > 0;"),
            ]),
        StudioMission(
            id: "js-2", track: .build, number: 2, title: "Level Up", pageTitle: "Level 1",
            brief: "Reward players: change the heading when they reach five taps, and move the target after every hit.",
            starter: "// Level Up\n\nlet score = 0;\nconst target = document.querySelector('.target');\nconst heading = document.querySelector('h1');\n\ntarget.addEventListener('click', () => {\n  score += 1;\n  // 2. At 5, change the heading\n  // 3. Nudge the target\n});\n",
            steps: [
                Step(title: "Count taps",
                     instruction: "Keep a score that goes up by one on every tap.",
                     example: "score += 1;",
                     check: "if (typeof val('score') !== 'number') return false; const before = val('score'); tap(); return val('score') === before + 1;"),
                Step(title: "Reach level 2",
                     instruction: "When score reaches 5, set the heading's text to \"Level 2\".",
                     example: "if (score === 5) {\n  heading.textContent = 'Level 2';\n}",
                     check: "tap(6); return /level 2/i.test($('h1').textContent);"),
                Step(title: "Nudge the target",
                     instruction: "After each tap, change the target's position, for example with style.transform.",
                     example: "target.style.transform = `translateX(${score % 2 ? 40 : -40}px)`;",
                     check: "const t = $('.target'); const a = t.getAttribute('style') || ''; tap(); const b = t.getAttribute('style') || ''; tap(); const c = t.getAttribute('style') || ''; return a !== b || b !== c;"),
            ]),
        StudioMission(
            id: "js-3", track: .build, number: 3, title: "Countdown", pageTitle: "Countdown",
            brief: "Give the round a clock: count down every second and stop at zero.",
            starter: "// Countdown\n\nlet score = 0;\nlet timeLeft = 10;\nconst heading = document.querySelector('h1');\n\n// 1. Show the time in the heading\n// 2. Count down once a second\n// 3. Stop at zero\n",
            steps: [
                Step(title: "Show the time",
                     instruction: "Put timeLeft in the heading's text.",
                     example: "heading.textContent = timeLeft + 's';",
                     check: "return typeof val('timeLeft') === 'number' && $('h1').textContent.includes(String(val('timeLeft')));"),
                Step(title: "Tick every second",
                     instruction: "Use setInterval to subtract one from timeLeft every 1000 ms, and update the heading.",
                     example: "setInterval(() => {\n  timeLeft -= 1;\n  heading.textContent = timeLeft + 's';\n}, 1000);",
                     check: "const a = val('timeLeft'); await wait(1150); const b = val('timeLeft'); return typeof b === 'number' && b < a && $('h1').textContent.includes(String(b));"),
                Step(title: "Stop at zero",
                     instruction: "Never let timeLeft go below 0. Stop the timer with clearInterval, or check before subtracting.",
                     example: "if (timeLeft > 0) timeLeft -= 1;",
                     check: "try { eval('timeLeft = 1'); } catch (e) { return false; } await wait(2300); return val('timeLeft') === 0;"),
            ]),
        StudioMission(
            id: "js-4", track: .build, number: 4, title: "Catch Me", pageTitle: "Catch Me",
            brief: "Make the target jump to a random spot after every tap, without ever leaving the arena.",
            starter: "// Catch Me\n\nlet score = 0;\nconst target = document.querySelector('.target');\nconst arena = document.querySelector('.arena');\n\n// 1. Position the target yourself\n// 2. Jump somewhere new on each tap\n// 3. Stay inside the arena\n",
            steps: [
                Step(title: "Take control of position",
                     instruction: "Set target.style.position to 'absolute' (and arena's to 'relative').",
                     example: "arena.style.position = 'relative';\ntarget.style.position = 'absolute';",
                     check: "return css('.target', 'position') === 'absolute';"),
                Step(title: "Jump on every tap",
                     instruction: "On each tap, set target.style.left and target.style.top to new random values.",
                     example: "target.style.left = Math.random() * 200 + 'px';\ntarget.style.top = Math.random() * 300 + 'px';",
                     check: "const t = $('.target'); tap(); const a = t.style.left + t.style.top; tap(); const b = t.style.left + t.style.top; tap(); const c = t.style.left + t.style.top; return a !== '' && (a !== b || b !== c);"),
                Step(title: "Stay inside",
                     instruction: "Use arena.clientWidth - target.offsetWidth (and the same for height) as the largest value.",
                     example: "const maxX = arena.clientWidth - target.offsetWidth;\ntarget.style.left = Math.random() * maxX + 'px';",
                     check: "const t = $('.target'), a = $('.arena'); if (!t.style.left || !t.style.top) return false; for (let i = 0; i < 12; i++) { tap(); const r = t.getBoundingClientRect(), b = a.getBoundingClientRect(); if (r.left < b.left - 1 || r.top < b.top - 1 || r.right > b.right + 1 || r.bottom > b.bottom + 1) return false; } return true;"),
            ]),
        StudioMission(
            id: "js-5", track: .build, number: 5, title: "Best Score", pageTitle: "Best Score",
            brief: "Remember the best score of the session, and let a double tap start a new round.",
            starter: "// Best Score\n\nlet score = 0;\nlet best = 0;\nconst target = document.querySelector('.target');\nconst heading = document.querySelector('h1');\n\ntarget.addEventListener('click', () => {\n  score += 1;\n  // 1. Update best\n});\n\n// 2. Double tap resets the score\n",
            steps: [
                Step(title: "Track the best",
                     instruction: "After each tap, if score is higher than best, set best to score.",
                     example: "if (score > best) best = score;",
                     check: "tap(3); return typeof val('best') === 'number' && val('best') >= 3 && val('best') >= val('score');"),
                Step(title: "Double tap to restart",
                     instruction: "Listen for 'dblclick' on the target and set score back to 0.",
                     example: "target.addEventListener('dblclick', () => {\n  score = 0;\n});",
                     check: "tap(2); $('.target').dispatchEvent(new MouseEvent('dblclick', { bubbles: true })); return val('score') === 0;"),
                Step(title: "Show the best",
                     instruction: "Keep best after a restart, and show it in the heading.",
                     example: "heading.textContent = 'Best: ' + best;",
                     check: "return val('best') >= 3 && $('h1').textContent.includes(String(val('best')));"),
            ]),
    ]
}

// MARK: - Mission progress

@MainActor enum MissionProgress {
    private static let completedKey = "studio.missions.completed"

    static func currentIndex(for track: ProjectTrack) -> Int {
        let missions = StudioMission.missions(for: track)
        return min(max(UserDefaults.standard.integer(forKey: "studio.mission.\(trackKey(track))"), 0), missions.count - 1)
    }

    static func setCurrentIndex(_ index: Int, for track: ProjectTrack) {
        UserDefaults.standard.set(index, forKey: "studio.mission.\(trackKey(track))")
    }

    static func isCompleted(_ mission: StudioMission) -> Bool {
        (UserDefaults.standard.stringArray(forKey: completedKey) ?? []).contains(mission.id)
    }

    static func markCompleted(_ mission: StudioMission) {
        var done = Set(UserDefaults.standard.stringArray(forKey: completedKey) ?? [])
        done.insert(mission.id)
        UserDefaults.standard.set(Array(done).sorted(), forKey: completedKey)
    }

    /// Mission 1 keeps the keys earlier versions used, so existing drafts carry over.
    static func draftKey(_ mission: StudioMission) -> String {
        mission.number == 1 ? "project.\(mission.track.rawValue).draft" : "studio.\(mission.id).draft"
    }

    static func passingKey(_ mission: StudioMission) -> String {
        mission.number == 1 ? "project.\(mission.track.rawValue).passing" : "studio.\(mission.id).passing"
    }

    private static func trackKey(_ track: ProjectTrack) -> String { track == .design ? "design" : "build" }
}

// MARK: - Check runner

/// Loads the learner's page in an off-screen web view and runs each step's
/// check against it, in order, on the same page.
@MainActor final class StudioCheckRunner: NSObject, WKNavigationDelegate {
    struct Result {
        let passed: [Bool]
        let error: String?
    }

    private var webView: WKWebView?
    private var loadContinuation: CheckedContinuation<Void, Never>?

    func run(_ mission: StudioMission, code: String) async -> Result {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let web = WKWebView(frame: CGRect(x: -2000, y: 0, width: 390, height: 640), configuration: config)
        web.navigationDelegate = self
        web.isUserInteractionEnabled = false
        web.alpha = 0.01
        web.isAccessibilityElement = false
        // WebKit pauses timers in pages that aren't in a window, so the check page
        // sits in the app's window, off to the side and invisible.
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        window?.addSubview(web)
        webView = web
        defer {
            web.removeFromSuperview()
            webView = nil
        }

        let html = StudioPreviewDocument.html(track: mission.track, code: code,
                                              title: mission.pageTitle, instrumented: true)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            loadContinuation = continuation
            web.loadHTMLString(html, baseURL: nil)
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(4))
                self?.finishLoad()
            }
        }
        try? await Task.sleep(for: .milliseconds(150))

        var results: [Bool] = []
        for step in mission.steps {
            let body = StudioMission.checkHelpers + "\ntry {\n" + step.check + "\n} catch (e) { return false; }"
            let value = try? await web.callAsyncJavaScript(body, arguments: [:], in: nil, contentWorld: .page)
            results.append((value as? Bool) ?? ((value as? NSNumber)?.boolValue ?? false))
        }
        let errors = try? await web.callAsyncJavaScript("return (window.__ss && window.__ss.errors[0]) || ''",
                                                        arguments: [:], in: nil, contentWorld: .page)
        let error = (errors as? String).flatMap { $0.isEmpty ? nil : $0 }
        return Result(passed: results, error: error)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finishLoad() }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { finishLoad() }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { finishLoad() }

    private func finishLoad() {
        loadContinuation?.resume()
        loadContinuation = nil
    }
}
