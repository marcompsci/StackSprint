#!/usr/bin/env bash
# StackSprint Apple compliance gate.
#
#   scripts/compliance-check.sh            # every push: fails on code/config problems
#   scripts/compliance-check.sh --release  # before TestFlight/App Store: also fails on
#                                          # missing submission details (support, privacy URL)
#
# Every check prints PASS, WARN or FAIL. A FAIL makes the script exit 1. Nothing is
# skipped silently: checks that need macOS/Xcode or App Store Connect are printed
# as MANUAL so they can't be mistaken for passes.
set -uo pipefail

MODE="${1:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/StackSprint/StackSprint"
PROJ="$ROOT/StackSprint/StackSprint.xcodeproj/project.pbxproj"
FAILS=0; WARNS=0

pass()   { printf '  PASS    %s\n' "$1"; }
warn()   { printf '  WARN    %s\n' "$1"; WARNS=$((WARNS+1)); }
fail()   { printf '  FAIL    %s\n' "$1"; FAILS=$((FAILS+1)); }
manual() { printf '  MANUAL  %s\n' "$1"; }
release_gate() { if [ "$MODE" = "--release" ]; then fail "$1"; else warn "$1 (blocks --release)"; fi; }
uses() { grep -rqE "$1" "$APP" --include='*.swift'; }

plist_get() { python3 - "$1" "$2" <<'PY'
import plistlib, sys
d = plistlib.load(open(sys.argv[1], 'rb'))
v = d
for k in sys.argv[2].split('.'):
    if isinstance(v, dict) and k in v: v = v[k]
    else: print('__MISSING__'); sys.exit()
print(v if not isinstance(v, (list, dict)) else repr(v))
PY
}

echo "== Configuration files"
for f in "$APP/Info.plist" "$APP/StackSprint.entitlements" "$APP/PrivacyInfo.xcprivacy"; do
  if python3 -c "import plistlib,sys; plistlib.load(open(sys.argv[1],'rb'))" "$f" 2>/dev/null; then
    pass "$(basename "$f") is a valid property list"
  else
    fail "$(basename "$f") is missing or not a valid property list"
  fi
done

echo "== Info.plist (guideline 5.1.1: purpose strings must be accurate)"
check_purpose() { # key, regex of code that needs it
  local val; val="$(plist_get "$APP/Info.plist" "$1")"
  if uses "$2"; then
    [ "$val" != "__MISSING__" ] && pass "$1 present for code that needs it" || fail "$1 missing but code uses it"
  else
    [ "$val" = "__MISSING__" ] && pass "$1 absent (app doesn't use it)" || fail "$1 declared but the app never uses it"
  fi
}
check_purpose NSCameraUsageDescription 'AVCaptureDevice|UIImagePickerController|DataScannerViewController'
check_purpose NSMicrophoneUsageDescription 'AVAudioRecorder|SFSpeechRecognizer|requestRecordPermission|AVAudioApplication.requestRecordPermission'
check_purpose NSUserTrackingUsageDescription 'ATTrackingManager'
check_purpose NSPhotoLibraryUsageDescription 'PHPhotoLibrary'
check_purpose NSContactsUsageDescription 'CNContactStore'
check_purpose NSLocationWhenInUseUsageDescription 'CLLocationManager'
bg="$(plist_get "$APP/Info.plist" UIBackgroundModes)"
if [[ "$bg" == *remote-notification* ]] && ! uses 'registerForRemoteNotifications'; then
  fail "UIBackgroundModes has remote-notification but the app never registers for push"
else
  pass "Background modes match the code"
fi
enc="$(plist_get "$APP/Info.plist" ITSAppUsesNonExemptEncryption)"
[ "$enc" != "__MISSING__" ] && pass "ITSAppUsesNonExemptEncryption declared ($enc)" || warn "ITSAppUsesNonExemptEncryption not declared (App Store Connect will ask on every upload)"
grep -q 'com\.example' "$APP/Info.plist" && fail "Info.plist still contains a com.example placeholder" || pass "No com.example placeholders in Info.plist"

echo "== Entitlements and capabilities"
grep -q 'CODE_SIGN_ENTITLEMENTS = StackSprint/StackSprint.entitlements' "$PROJ" \
  && pass "Entitlements file is attached to the app target" \
  || fail "Entitlements file is not attached (CODE_SIGN_ENTITLEMENTS missing)"
ent="$APP/StackSprint.entitlements"
if uses 'import GameKit'; then
  grep -q 'com.apple.developer.game-center' "$ent" && pass "Game Center entitlement present (GameKit is used)" || fail "GameKit used without the Game Center entitlement"
fi
if uses 'ASAuthorizationAppleIDProvider'; then
  grep -q 'com.apple.developer.applesignin' "$ent" && pass "Sign in with Apple entitlement present" || fail "Sign in with Apple used without its entitlement"
fi
if grep -q 'icloud-services' "$ent" && ! grep -q 'SSCloudKitEnabled' "$APP/Info.plist"; then
  warn "CloudKit entitlement present but sync is switched off in Info.plist"
fi
grep -q 'aps-environment' "$ent" && ! uses 'registerForRemoteNotifications' \
  && fail "Push entitlement present but the app never registers for push" || pass "No unused push entitlement"

echo "== Privacy manifest (required-reason APIs)"
pm="$APP/PrivacyInfo.xcprivacy"
grep -A1 'NSPrivacyTracking<' "$pm" | grep -q '<false/>' && pass "NSPrivacyTracking is false" || fail "NSPrivacyTracking must be false (the app does not track)"
need_reason() { # api category, code regex
  if uses "$2"; then
    grep -q "$1" "$pm" && pass "$1 declared (code uses it)" || fail "$1 used in code but not declared in PrivacyInfo.xcprivacy"
  fi
}
need_reason NSPrivacyAccessedAPICategoryUserDefaults 'UserDefaults|@AppStorage'
need_reason NSPrivacyAccessedAPICategoryFileTimestamp 'creationDate|modificationDate|contentModificationDate|attributesOfItem'
need_reason NSPrivacyAccessedAPICategorySystemBootTime 'systemUptime|mach_absolute_time'
need_reason NSPrivacyAccessedAPICategoryDiskSpace 'volumeAvailableCapacity|systemFreeSize|NSFileSystemFreeSize'
need_reason NSPrivacyAccessedAPICategoryActiveKeyboards 'activeInputModes'

echo "== Secrets (no credentials in the bundle or repo)"
secret_hits="$(grep -rInE \
  'sk-ant-[A-Za-z0-9_-]{20,}|sk_live_[A-Za-z0-9]{10,}|ghp_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC )?PRIVATE KEY-----|sb_secret_[A-Za-z0-9_-]{10,}|"service_role"|client_secret *[:=] *"[^"]+' \
  "$ROOT" --exclude-dir=.git --exclude-dir=node_modules --exclude=compliance-check.sh 2>/dev/null || true)"
[ -z "$secret_hits" ] && pass "No API keys, tokens or private keys found" || { fail "Possible secrets:"; echo "$secret_hits" | head -10; }
python3 - "$APP/BackendConfig.json" <<'PY' && pass "BackendConfig.json holds only a URL and a publishable key" || fail "BackendConfig.json contains something other than url/publishableKey/curriculumURL"
import json, sys
d = json.load(open(sys.argv[1]))
allowed = {"url", "publishableKey", "curriculumURL"}
assert set(d) <= allowed
assert "secret" not in json.dumps(d).lower() and "service_role" not in json.dumps(d)
PY

echo "== App completeness (2.1, 2.3: nothing simulated, nothing 'coming soon')"
uses 'Demo: simulate|demoRepos|simulate OAuth' && fail "Simulated sign-in code is back" || pass "No simulated sign-in"
grep -q 'hasTokenExchangeBackend = false' "$APP/SocialAuth.swift" && pass "GitHub/Google sign-in hidden until a token exchange exists" || warn "GitHub/Google sign-in enabled: confirm the server-side token exchange works"
uses '"Alex C\.|"Jordan L\.|xX_dev_Xx' && fail "Fake named players are back in the leaderboard" || pass "Leaderboard shows labelled pacers, not invented people"
grep -q 'LeaderboardStore.disclosure' "$APP/Leaderboard.swift" && pass "Pacer disclosure shown" || fail "Pacer disclosure missing"

echo "== Payments (3.1.1, 3.1.2)"
if uses 'product.purchase\(|Product.products'; then
  grep -q 'LegalLinks.termsOfUse' "$APP/PremiumStore.swift" && pass "Paywall links Terms of Use" || fail "Paywall has no Terms of Use link"
  grep -q 'PrivacyPolicyView' "$APP/PremiumStore.swift" && pass "Paywall links the Privacy Policy" || fail "Paywall has no Privacy Policy link"
  grep -q 'restorePurchases' "$APP/PremiumStore.swift" && pass "Restore Purchases available" || fail "No Restore Purchases"
  grep -q 'productsLoaded' "$APP/PremiumStore.swift" && pass "Paywall handles products that fail to load" || fail "Paywall can spin forever when products don't load"
  grep -qiE 'unlimited (ai|chats)|Pro crown' "$APP/PremiumStore.swift" && fail "Paywall advertises perks that don't exist" || pass "Paywall lists only what Pro unlocks"
  manual "Create com.stacksprint.pro.monthly and .yearly in App Store Connect and attach them to the version"
fi

echo "== Privacy policy and support (5.1.1, 1.5)"
[ -f "$APP/LegalViews.swift" ] && grep -q 'PrivacyPolicyView' "$APP/LegalViews.swift" && pass "In-app privacy policy present" || fail "No in-app privacy policy"
grep -q 'LegalLinksSection()' "$APP/StackSprintApp.swift" && pass "Account links privacy policy, terms and support" || fail "Account screen has no legal links"
grep -qE 'supportEmail = "[^"]+@' "$APP/LegalViews.swift" && pass "Support contact set" || release_gate "Support contact (LegalLinks.supportEmail) is empty"
grep -qE 'privacyURL = "https://' "$APP/AppStoreScreenshots.swift" && pass "Hosted privacy policy URL set" || release_gate "Hosted privacy policy URL (AppStoreCopy.privacyURL) is empty"
grep -qE 'supportURL = "https://' "$APP/AppStoreScreenshots.swift" && pass "Support URL set" || release_gate "Support URL (AppStoreCopy.supportURL) is empty"

echo "== Web content"
ext="$(grep -hoE '(src|href)="https?://[^"]+' "$APP/Web/index.html" || true)"
[ -z "$ext" ] && pass "index.html loads nothing from third-party servers" || fail "index.html loads remote resources: $ext"
remote_js="$(grep -hoE "https://[A-Za-z0-9.-]+" "$APP"/Web/*.js | sort -u | grep -vE 'cdn\.jsdelivr\.net|github\.com|docs\.python\.org' || true)"
[ -z "$remote_js" ] && pass "Web scripts only reach the documented hosts (jsDelivr for Python)" || warn "Undocumented hosts in web scripts: $remote_js"
for f in "$APP"/Web/*.js "$APP"/Web/*.css "$APP"/Web/index.html; do
  base="$(basename "$f")"
  if [ -f "$ROOT/$base" ] && ! cmp -s "$f" "$ROOT/$base"; then warn "$base differs between the app bundle and the repo root copy"; fi
done

echo "== Version and build"
mv="$(grep -m1 -oE 'MARKETING_VERSION = [^;]+' "$PROJ" | cut -d' ' -f3)"
bn="$(grep -m1 -oE 'CURRENT_PROJECT_VERSION = [^;]+' "$PROJ" | cut -d' ' -f3)"
[[ "$mv" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] && pass "Marketing version $mv" || fail "Marketing version '$mv' is not x.y or x.y.z"
[[ "$bn" =~ ^[0-9]+(\.[0-9]+)*$ ]] && pass "Build number $bn" || fail "Build number '$bn' is not numeric"
manual "Raise CURRENT_PROJECT_VERSION above the last build uploaded to App Store Connect (currently $bn)"
dt="$(grep -m1 -oE 'IPHONEOS_DEPLOYMENT_TARGET = [^;]+' "$PROJ" | cut -d' ' -f3)"
pass "Deployment target iOS $dt (testers need iOS $dt or later)"
fam="$(grep -m1 -oE 'TARGETED_DEVICE_FAMILY = "[^"]+"' "$PROJ" | cut -d'"' -f2)"
[[ "$fam" == *2* ]] && warn "iPad is a supported device: App Review tests on iPad, so test it there too"
[[ "$fam" == *7* ]] && warn "visionOS is a supported platform: test on Apple Vision Pro or the visionOS simulator, or remove it"

echo "== Needs macOS, Xcode or App Store Connect"
manual "Release archive: Product → Archive in Xcode, then Validate App in the Organizer"
manual "Answer the age rating questions (AI chatbot: Bite tutor; Game Center races) in App Store Connect"
manual "App Privacy answers in App Store Connect must match docs/privacy-security-audit.md"
manual "Game Center enabled for the app in App Store Connect"

echo
echo "Result: $FAILS failed, $WARNS warnings"
[ "$FAILS" -eq 0 ]
