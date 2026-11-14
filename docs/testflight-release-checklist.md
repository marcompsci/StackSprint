# StackSprint — TestFlight release checklist

Run this before **every** TestFlight upload. Don't tick an item you didn't check; a skipped item is a failed item.

## 1. Automated gate

- [ ] `scripts/compliance-check.sh --release` exits 0 (0 FAIL lines). Read every WARN and MANUAL line.
- [ ] GitHub Actions "Apple compliance gate" is green on the commit you're shipping: policy checks, every-commit secret scan, web tests, Release build, static analysis, unit tests.
- [ ] To run the release gate in CI: Actions → Apple compliance gate → Run workflow → tick "release".

## 2. Submission details

- [ ] `LegalLinks.supportEmail` set (in-app support row appears).
- [ ] Privacy policy hosted at a public HTTPS URL, identical to the in-app policy (`docs/privacy-policy.md`); URL in `AppStoreCopy.privacyURL` and in App Store Connect.
- [ ] Support URL set in `AppStoreCopy.supportURL` and App Store Connect.
- [ ] App Privacy answers in App Store Connect match `docs/privacy-security-audit.md` (Data Not Collected while cloud accounts are off).
- [ ] Age-rating questionnaire answered (AI assistant: yes, Bite tutor; Game Center: yes).
- [ ] Subscriptions `com.stacksprint.pro.monthly` and `com.stacksprint.pro.yearly` exist in one subscription group, with display names, descriptions, prices and a review screenshot, and are "Ready to Submit".
- [ ] Game Center enabled for the app version in App Store Connect.

## 3. Build

- [ ] `CURRENT_PROJECT_VERSION` is higher than the last uploaded build (`MARKETING_VERSION` changes only for a new release).
- [ ] Supported devices decided: iPhone only, iPhone + iPad, and/or visionOS — and every supported device class was actually tested.
- [ ] Xcode 26 or later (Apple's upload minimum since April 28, 2026).
- [ ] Product → Archive with the **StackSprint** scheme (Release).
- [ ] Organizer → Validate App passes (signing, entitlements: Sign in with Apple + Game Center).
- [ ] Distribute → App Store Connect → Upload (only with the owner's explicit go-ahead).

## 4. Manual smoke test on a real device (Release build or the TestFlight build)

- [ ] Cold launch and relaunch; splash skips on tap.
- [ ] Learn: open a lesson, reveal, type the example.
- [ ] Studio: CSS mission Run checks (fails, then passes after a fix); JavaScript mission; Next mission unlocks.
- [ ] Studio landscape split; other tabs stay portrait; Bite hidden in landscape.
- [ ] Free build: template → edit → Export .html opens in Safari.
- [ ] Account: Sign in with Apple, then Disconnect; Privacy Policy, Terms of Use and Contact support open.
- [ ] Paywall: prices load (sandbox), Restore Purchases, Terms, Privacy; "Try again" shows with no network.
- [ ] Airplane mode: app opens, lessons and Studio work, Python explains it needs internet.
- [ ] Background → foreground during a Studio check and during a quiz.
- [ ] iPad (if supported): every tab, both orientations.

## 5. TestFlight

- [ ] Export compliance answered (exempt).
- [ ] Test Information complete (description, feedback email, privacy URL, review notes from `docs/app-review-notes.md`).
- [ ] Build added to the external group → Submit for Beta App Review.
- [ ] After "Ready to Test": public link enabled and verified from a separate Apple Account.

## 6. After release

- [ ] Note the build number and commit hash in the release log.
- [ ] Any new compliance risk found → add a check to `scripts/compliance-check.sh` so it can't come back.
