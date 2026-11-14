# StackSprint — App Review notes

Paste the **Review notes** section into App Store Connect → TestFlight → Test Information → *Review notes* (for Beta App Review) and into the app version's *App Review Information → Notes* (for App Store review). Edit the bracketed parts first.

## Review notes (paste-ready)

> StackSprint teaches coding in short lessons, quizzes and a hands-on Studio where learners write CSS, JavaScript and HTML and see it run.
>
> **No sign-in is required.** Every feature can be reviewed as a guest. Sign in with Apple is optional and only labels progress on the device. Cloud accounts are not enabled in this build, so no demo account is needed.
>
> **Where to look:**
> - Learn tab → any lesson card → reveal, then type the example.
> - Studio tab → CSS → "Palette Pop" → tap Run checks (all three steps fail), add `.arena { background-color: #172554; }` and run again (step 1 passes). Turn the device sideways for the side-by-side editor and live preview.
> - Studio tab → Free build → choose a template → edit the files → Export .html.
> - Practice tab → Review: lessons due for spaced review and a quiz for every track (works offline, no AI needed). "Chat with Bit" is the optional on-device AI tutor.
> - Stats tab → streaks, practice heatmap, and computer "pacers" (labelled on screen as computer-set marks, not real players).
> - Account → Backup: saves progress to a JSON file the learner chooses where to keep; restoring merges it. Nothing is uploaded.
> - Learn → tap the locked Go, Rust or Interview Prep chip → StackSprint Pro subscription (sandbox).
>
> **Subscriptions:** StackSprint Pro (monthly and yearly, auto-renewing) unlocks the Go, Rust and Interview Prep tracks and Pro season collectibles. Everything else is free. Restore Purchases, Terms of Use and the Privacy Policy are on the paywall.
>
> **Running code (guideline 2.5.2):** this is an educational app. Learner-written JavaScript and CSS run in sandboxed, network-blocked web views. The first time a learner runs Python, the app downloads the open-source Pyodide interpreter from jsDelivr. It is used only to run the learner's own Python and doesn't change the app's features.
>
> **On-device AI:** Bit the tutor uses Apple Intelligence (Foundation Models) on device. On devices without Apple Intelligence, the app explains that the tutor isn't available.
>
> **Game Center:** Account → Together → Study Room starts a real-time quiz race through Game Center. It needs two devices signed in to Game Center; only names (from Game Center) and scores are exchanged. There is no chat.
>
> **Privacy:** no tracking, no ads, no analytics SDKs. Policy: Account → Privacy Policy, and [hosted privacy policy URL].
>
> Contact: [support email]

## Reviewer navigation

| Screen | How to reach it | What to verify |
|---|---|---|
| Learn | First tab | Lessons, reveal/type checkpoints, quizzes |
| Studio missions | Studio tab → CSS or JavaScript | Run checks reports ✓/✗ per step; Next mission unlocks after passing |
| Free build | Studio tab → Free build | Templates, HTML/CSS/JS tabs, live preview, Export .html |
| Landscape editor | Studio tab, rotate the device | Code left, preview right; other tabs stay portrait |
| Full Studio (60 projects) | Studio → "Explore the full 60-project Studio" | Web workspace |
| Practice | Tab 3 | Review (due lessons, quick round, quiz by track) works offline; Chat with Bit needs Apple Intelligence |
| Stats | Tab 4 | Streaks, heatmap, pacers, weekly XP |
| Account | Last tab | Sign in with Apple, Pro status, Together (challenges, Study Room), Privacy Policy, Terms, support |
| Paywall | Learn → locked Go/Rust/Interview Prep chip, or Account → View Pro plans | Price and period from the App Store, renewal terms, Restore, Terms, Privacy |

## Demo account

Not required: there is no sign-in wall and cloud accounts are off. If cloud accounts are enabled in a later build, create a reviewer account with seeded progress and add it under *Sign-In Information*.

## Things a reviewer might question

| Topic | Answer |
|---|---|
| "Pacers" on the leaderboard | Computer-generated XP marks around the learner's level, labelled on screen as not real players. No online leaderboard exists. |
| Season pass rewards | Collectible badges for the learner's season shelf; no rewards are described as changing app functionality. |
| Python download | Section 2.5.2 education exception; interpreter only runs the learner's own code. |
| iPad / visionOS | [Confirm both were tested, or remove them from the build's supported devices before submitting.] |
