# StackSprint — external TestFlight guide

## Beta App Description (paste into App Store Connect → TestFlight → Test Information)

> StackSprint teaches coding in small daily steps. Learn web, Python, Swift, TypeScript, React and cybersecurity concepts with flash cards and quizzes, then open the Studio to write real CSS, JavaScript and HTML and watch it run. Work through guided missions that check what your code actually does, or start a free build from a template and export it as a web page.

## What to Test (paste into the build's "What to Test")

> Thanks for testing StackSprint!
> 1. Studio → CSS → Palette Pop: tap Run checks before and after editing. Do the ✓ and ✗ marks match what you see in the preview?
> 2. Turn your phone sideways in Studio. Is the side-by-side editor comfortable? Do the other tabs stay upright?
> 3. Try the key bar above the keyboard ({ } ( ) ;) and see whether brackets and quotes close themselves the way you expect.
> 4. Free build: pick a template, change it, and export the .html. Does the file open in Safari?
> 5. Learn and Practice: do lessons, quizzes and streaks save correctly after you close and reopen the app?
> Tell us about anything confusing, broken, or slow. Screenshots help: take one and TestFlight will offer to send it.

## Tester requirements

- iPhone or iPad running **iOS / iPadOS 26.5 or later** (the build's deployment target).
- The TestFlight app from the App Store, signed in with the tester's Apple Account.
- Bit the AI tutor needs a device with Apple Intelligence turned on; everything else works without it.
- Python lessons need an internet connection the first time.
- Study Room races need Game Center and a second tester.
- Subscriptions in TestFlight use the sandbox: testers are not charged, and sandbox subscriptions renew on an accelerated schedule.

## Sending feedback

- In TestFlight: open StackSprint → Send Beta Feedback, or take a screenshot in the app and tap Share Beta Feedback.
- Crashes are reported automatically if the tester allows it.
- Support contact: [support email — required before external testing]

## Setting up external testing (developer steps)

1. **Upload a build:** bump `CURRENT_PROJECT_VERSION`, Product → Archive (Release), Organizer → Validate App → Distribute → App Store Connect → Upload. Uploading needs your explicit go-ahead; it is never automated.
2. **Export compliance:** answer "uses only exempt encryption" (already set by `ITSAppUsesNonExemptEncryption = NO`).
3. **Test Information:** enter the Beta App Description, Feedback Email, Privacy Policy URL, Marketing URL (optional), and the review notes from `docs/app-review-notes.md`. Sign-in information: "No sign-in required".
4. **Internal group:** TestFlight → Internal Testing → + → add team members (up to 100 App Store Connect users). Internal builds don't need Beta App Review.
5. **External group:** TestFlight → External Testing → + → name it (e.g. "Public beta") → add the build. Adding the first build of a version to an external group submits it for **Beta App Review**.
6. **Wait for approval:** status changes from "Waiting for Review" to "Ready to Test" (typically within a day or two; not guaranteed). Rejections arrive in App Store Connect with the guideline cited.
7. **Public link:** External group → Public Link → Enable, and set a tester limit (up to 10,000). Optionally add criteria such as minimum OS 26.5 and device families.
8. **Verify:** open the public link on a device signed in to a different Apple Account (not your developer account), accept the invitation in TestFlight, install, and launch.
9. **Later builds of the same version** usually go to external testers without full re-review; a new version number triggers Beta App Review again.

## TestFlight approval vs App Store approval

Beta App Review approves a build for **external testing only**. It is shorter and doesn't replace App Store review. The App Store submission is reviewed again against the full guidelines, including metadata, screenshots, in-app purchase configuration and the privacy answers. A build that passed TestFlight can still be rejected for the App Store.
