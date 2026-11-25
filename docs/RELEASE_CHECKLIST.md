# Release checklist — DailyMantra 2.0

Status as of 2026-11-25. ✅ verified · ⬜ owner action · ⚠️ known limitation

## Build & quality
- ✅ `flutter analyze` 0 issues · ✅ 194 automated tests (+ live API tests with `LIVE=1`) · ✅ CI: analyze/test, Android debug build, iOS no-codesign build
- ✅ Signed release **AAB** builds (`flutter build appbundle --release`, R8 on, 40 MB bundle). Keystore + `key.properties` are local only (not in git).
- ✅ Release APK smoke-tested on a Pixel 9 Pro emulator (Android 16): onboarding → Today → content sync (~1,500 items on first open) → Discover → video playback (with rendition fallback) → audiobook streaming.
- ✅ Version `2.0.0+20`. ⬜ **Confirm versionCode 20 is higher than the one currently on Play** (Play Console → App bundle explorer). Raise it if not.

## Store requirements (owner)
- ⬜ Host `docs/PRIVACY_POLICY.md` (add a contact email) and paste the URL into Play Console / App Store Connect.
- ⬜ Play **Data safety** form: no data collected by the developer; AdMob collects device and advertising identifiers (ads); data is not shared by the developer; no account.
- ⬜ Play **exact alarm** declaration: the app uses `SCHEDULE_EXACT_ALARM` for user-set medicine/habit reminders and falls back to inexact alarms if it's denied.
- ⬜ Content rating questionnaire; ⬜ new screenshots (the redesign), feature graphic, short and long descriptions in English and Nepali.
- ⬜ iOS: signing team, App Store Connect record, `GoogleService-Info.plist` is present, AdMob iOS unit IDs (currently reuse Android IDs, see `ad_service.dart`).
- ⚠️ **Ad consent (UMP)** for EEA/UK users is not implemented. Needed before distributing in those regions (Nepal-first release is unaffected).

## Device checks still to do on real phones
- ⬜ Reminder checklist M1–M18 (`NOTIFICATION_ARCHITECTURE.md`), iOS I1–I5.
- ⬜ Background content job: leave the phone idle on Wi-Fi overnight, then check You → Free content "updated … ago".
- ⬜ TalkBack / VoiceOver pass and 200 % font size.
- ⬜ A low-end Android phone: wger HEVC videos need hardware HEVC decode (most phones from 2016 on). Older devices show the friendly "can't be played" message.

## Known limitations (documented, not blockers)
- Gutenberg covers sometimes fail to load when gutenberg.org is busy (HTTP 503). A book icon is shown instead.
- The free video library is small (~110). Some Commons videos are in other languages or are amateur recordings.
- iOS: no background refresh (refreshes on open); medicine Taken/Snooze notification buttons are Android-only.
- Remaining English-only screens: water, meditation, reading and parts of exercise.

## Ads (AdMob)
- ⬜ Create **iOS** banner + interstitial ad units in AdMob and put them in `AdService` (iOS currently uses the Android unit IDs, so iOS ads won't fill).
- ⬜ Publish `app-ads.txt` on the developer website: `google.com, pub-2249746804787716, DIRECT, f08c47fec0942fa0`.
- ⬜ AdMob → Privacy & messaging: create the **GDPR consent message** (the app shows it via Google UMP; without a published message nothing is shown in the EEA/UK).
- ⬜ Never click your own ads on a real device; add your phone as a test device in AdMob.

## Store listing / ASO
- ⬜ Follow `docs/ASO.md` section 9.

## Build 2.0.0 (21): Play Console fixes
- **Target API 36** (Play requirement): `compileSdk`/`targetSdk` = 36. Tested on Android 16: predictive back pops pages instead of closing the app.
- **Minimum Android 5.0 (API 21) again**, as in 1.0.0 (1). Phase 1 had raised it to API 24 for `firebase_core`, which was only initialised and never used, so Play reported "1,866 devices no longer supported". Firebase was removed. If Firebase is added in Phase 4, it needs API 24 (or an older firebase_core).
- **versionCode 21:** code 20 was already uploaded to Play and can't be reused. Use 22, 23 … for every new upload.
