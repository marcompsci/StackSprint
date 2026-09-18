# StackSprint

A browser learning app with web vocabulary, hands-on code and AI prompting exercises, a cybersecurity course, and a game studio.

Built for new coders and developers who want a quick refresher: learn a concept, practice it, check your work, then play what you built.

## Courses and checkpoints

- **Web Development 101:** 12 vocabulary flashcards covering front-end, back-end, and full-stack concepts, code-reading and typing practice, and three AI-prompting checkpoints per card.
- **Web quiz:** 25 questions with feedback, plus a layer challenge and quick glossary.
- **Cybersecurity essentials:** 12 vocabulary cards and a 25-question end-of-course quiz.
- **Design Games:** 30 guided CSS projects with browser-rendered checks.
- **Building Games:** 30 guided JavaScript projects with executable checks and unlockable play.

## Run locally

No package installation, API keys, or build step required. The app uses HTML, CSS, and vanilla JavaScript.

Open `index.html` in a modern browser, or serve this folder locally:

```sh
python3 -m http.server 4176 --bind 127.0.0.1
```

Then visit `http://127.0.0.1:4176/`.

## Build, design, play

- **Building games:** 30 small playable prototypes. Write `createState()`, `update(state, action)`, and `isComplete(state)` in JavaScript. The display and input controls are supplied; the learner's actual functions control the game state and win condition.
- **Design games:** 30 CSS exercises applied to playable prototypes. Checks inspect computed browser styles, rather than searching for exact source text. Completed designs are applied to their corresponding builds, and completed builds can power the design previews.
- **Editor:** drafts save on the current browser and device. Ctrl/Command + Enter runs checks. Tab indents; Escape followed by Tab exits the editor.
- **Workspace terminal:** `help`, `test` / `build`, `play`, `preview`, `hint`, `clear`, and `export`. This is a browser coding workspace, not an operating-system shell.
- **Progress:** all three checks must pass before a mission unlocks play and its next project. Editing a passing draft requires checking the new version before playing or exporting it. Completed projects can be revisited and practiced from memory; the last passing source can be restored.
- **Export:** download JavaScript/CSS source or a standalone HTML game. The export includes the renderer and submitted code and requires no account or service.

Some arcade lessons deliberately use discrete steps so beginners can observe state transitions. These are small guided prototypes, not full game-engine projects. Design examples teach interface styling; the app supplies their initial game logic until the corresponding build has been completed.

## A daily habit

Three daily recall questions rotate through coding, design, web, and security concepts. Actual learning activity determines the streak. Rebuild reminders use increasing practice intervals, and repeat checks on the same day do not inflate that interval. XP comes from completed projects and daily recall answers.

The graduation message appears after all 60 code/design missions, all web flashcard code and AI checkpoints, all cybersecurity vocabulary reveals, and at least 20/25 on each course quiz. Quiz best scores and completion state are stored locally. There is no account sync or public deployment.

## Execution and verification

Learner JavaScript executes in disposable web workers within sandboxed, opaque-origin iframes. Runtime requests time out; the preview has no parent-page access or network access. CSS is confined to the game frame. The UI supports keyboard input, mobile layouts, reduced motion, and dark mode.

Open `http://127.0.0.1:4176/tests/studio-runtime.html` to validate all 60 reference solutions, starter locks, 30 game renderer startups, syntax reporting, and endless-loop termination. Tests use their own temporary game frames.

Progress is a learning aid stored on the learner's device, not a tamper-proof credential. Download source files regularly if you want independent copies of your work.

## Project structure

```text
index.html                 App layout and navigation
styles.css                 Main app styles
app.js                     Courses, flashcards, quizzes, and project catalog
lab-curriculum.js          Coding/design missions and reference checks
lab-runtime.js             Sandboxed code execution and game renderers
lab-studio.js              Editor, terminal, progress, exports, daily practice
lab-studio.css             Studio and daily-practice styles
tests/studio-runtime.html  Browser integration checks
```

## Current scope

This is a local-first learning prototype. Progress stays in browser storage and can be lost when site data is cleared; there is no cloud backup, authentication, or cross-device sync. AI-prompting exercises are guided checkpoints, not a connected AI agent. Google Fonts requires a network connection; system font fallbacks are provided. Course completion celebrates practice, not a professional certification.

After completing all course requirements and game missions, learners see: **“You’re ready to get started shipping your own products and designs.”**
