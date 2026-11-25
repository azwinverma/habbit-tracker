# App Store Optimization (ASO) plan: DailyMantra

Goal: rank for the searches people in Nepal (and South Asia) actually type, turn more store visits into installs, and keep users long enough that ratings and retention push the ranking up.

Google Play ranks apps mainly on: **text relevance** (title, short and full description), **install conversion rate** (icon, screenshots, rating), **ratings and reviews** (stars, volume and recency), **quality** (crash and ANR rates in Android vitals) and **engagement** (uninstalls, retention). ASO works on all five, not just keywords.

---

## 1. What's already in the app (done in code)

| Lever | Status |
|---|---|
| In-app rating prompt (Google Play / App Store native sheet) | ✅ `lib/services/review_prompt.dart`: asks only after ≥ 6 completed habits on ≥ 3 days, app used ≥ 4 days, max once per 120 days, 3 times ever, right after a habit is ticked (happy moment) |
| Nepali localisation | ✅ App UI in English and Nepali (most screens). Mirror this in the store listing (section 3) |
| Low crash / ANR risk | ✅ Non-blocking start (ads, consent, content refresh never block launch), tests in CI |
| Fresh content (engagement) | ✅ Books, audiobooks, sounds, exercises and videos refresh on every open; Bodybuilding.com uploads arrive automatically |
| Ad consent (EEA/UK) | ✅ Google UMP consent form + "Ad privacy choices" in You |

---

## 2. Keywords

**Primary (put in title / short description):** habit tracker, water reminder, medicine reminder (pill reminder), home workout.

**Secondary (full description, 2–4 times each, naturally):** daily routine, habit planner, streak, drink water, pill tracker, medication reminder, workout at home, no equipment, exercise videos, yoga, meditation, sleep sounds, free books, audiobooks, Nepali, reminders, self-care, wellness, health.

**Nepali (Nepali listing):** बानी, बानी ट्र्याकर, पानी पिउने रिमाइन्डर, औषधि रिमाइन्डर, घरमै व्यायाम, योग, ध्यान, किताब.

How to refine (do this monthly):
1. **Play Console → Grow → Store presence → Store listing → "Search terms"** (Acquisition reports → *Store analysis*) shows which searches bring visitors and installs. Add what converts and drop what doesn't.
2. Type each keyword into the Play Store search bar on a phone set to Nepal and note the autocomplete suggestions. These are real popular searches.
3. Look at the top 5 apps for each keyword (title, short description, screenshots). Don't copy their names: using another app's name (for example "Fit Flow") in the listing breaks Play policy.

---

## 3. Store listing copy (ready to paste)

> Final files: `store/listing/en-US.md`, `store/listing/ne-NP.md`, `store/release_notes.txt`; graphics in `store/` (see `store/README.md`). Don't name third-party brands (YouTube channels) in the listing.

### English (default, en-US)

**App name (≤ 30):** `DailyMantra: Habit Tracker` (26)
Alternative to A/B test: `DailyMantra: Habits & Workout` (29)

**Short description (≤ 80):**
`Habit tracker with water & medicine reminders, home workouts, meditation, books` (79)

**Full description (≤ 4000)**, keywords in bold for you, not for the listing:

```
DailyMantra is a simple, friendly habit tracker that helps you build a healthier daily routine: drink enough water, take your medicine on time, move every day, meditate and read.

TRACK YOUR HABITS
• One tap to tick off a habit and keep your streak going
• Today screen shows what's next and how far you've come
• Weekly plan and progress insights

REMINDERS THAT ARRIVE ON TIME
• Water reminder: set your daily glasses and get gentle nudges
• Medicine reminder / pill reminder with dose times, start and end dates
• Mark doses Taken or Skip straight from the notification
• Office move breaks: walk and stretch reminders during work hours

HOME WORKOUTS, NO GYM NEEDED
• Follow-along home workout videos from popular trainers
• Short coach videos showing how to do each exercise
• 1,000 exercises with steps, muscles and demo videos
• Workout timer, steps and your own weekly workout plan

MEDITATE, RELAX AND READ
• Free nature and meditation sounds
• Free public-domain books and audiobooks, saved for offline reading
• Continue reading or listening where you left off

MADE FOR NEPAL
• English and Nepali (नेपाली)
• Works offline: your habits stay on your phone
• New free content added automatically

Your data stays on your device. DailyMantra is free with ads.

DailyMantra is a reminder and wellness aid, not medical advice. Always follow your doctor's instructions.
```

### Nepali (ne-NP): add as a translation in Play Console

**App name:** `DailyMantra: बानी ट्र्याकर` (26)
**Short description:** `पानी, औषधि रिमाइन्डर, घरमै व्यायाम, ध्यान र किताब सहितको बानी ट्र्याकर` (70)
**Full description:** translate the English text above, keeping the section headings. Ask a native speaker to review: machine translation reads badly and hurts conversion.

> Tip: Play shows the listing in the phone's language. Most Nepali phones are set to English, so the English listing matters most, but the Nepali one wins searches typed in Devanagari.

---

## 4. Graphics: the biggest conversion lever

- **Icon:** simple and readable at 48 px; brand Deep Teal background, white lotus mark (current). Don't put words in the icon.
- **Screenshots (8, phone):** the first 3 decide most installs. Use real app screens with a short caption above each, large text, brand colours:
  1. "Build better habits, one tap a day" (Today screen)
  2. "Water & medicine reminders that arrive on time" (Medicine screen with Taken/Skip notification)
  3. "Home workouts with video, no gym needed" (Home workouts hub)
  4. "Your workout, your way" (Exercise screen: timer, steps, plan)
  5. "Meditate with calming sounds" (meditation)
  6. "Free books & audiobooks, offline" (Discover)
  7. "See your progress" (Insights)
  8. "English & नेपाली" (Today in Nepali)
  Make a second set with Nepali captions for the ne-NP listing.
- **Feature graphic (1024×500):** brand backdrop, lotus mark and "Habits · Water · Medicine · Workouts". Required for featuring.
- **Promo video (optional):** a 30-second YouTube video of the main flows; it autoplays on the listing.
- Run **Store listing experiments** (Play Console → Grow → Store listing experiments): test icon, first screenshot and short description one at a time, 50/50, for at least 7 days.

---

## 5. Ratings and reviews

- The in-app prompt is built (section 1). Google limits how often the sheet appears, so it can't be spammed.
- **Reply to every review** in Play Console within 48 h, especially 1–3★. Replies are public, and users often update their rating after a fix.
- Read the 1–2★ reviews weekly: reminders not arriving, battery and ads are the usual complaints. Fix them and say so in "What's new".
- Never offer rewards for ratings or ask only happy users through a separate gate. Both break Play policy.

---

## 6. Quality signals (Android vitals)

Google demotes apps above these "bad behaviour" thresholds: **user-perceived crash rate > 1.09%**, **ANR rate > 0.47%** (overall, and also per device model).
- Watch Play Console → Quality → Android vitals after each release; use staged rollout (10% → 50% → 100%).
- Add Firebase Crashlytics (Phase 4) to see crash stacks.
- **App size:** the AAB is ~40 MB (Play delivers ~25–30 MB per device). Smaller apps convert better on slow networks in Nepal. Options: remove unused fonts and weights, `--split-debug-info`, `--obfuscate`.

---

## 7. Ads, policy and trust (these affect listing and ranking)

- **app-ads.txt:** AdMob needs `app-ads.txt` on the website set as "Developer website" in Play Console: `google.com, pub-2249746804787716, DIRECT, f08c47fec0942fa0`. Without it, AdMob earnings drop sharply.
- **Privacy policy URL** (host `docs/PRIVACY_POLICY.md`, add a contact email) and an accurate **Data safety** form (device IDs for ads, IP address to content providers, no account). It now also lists YouTube playback.
- **Ads declaration:** "Contains ads" = Yes. Keep ads away from buttons (accidental clicks get AdMob accounts limited); the app already places banners at the end of content.
- **Health apps declaration:** answer the Health apps questions in App content (reminders, not a medical device).

---

## 8. Ongoing growth

- **Release regularly** (every 2–4 weeks) with a clear "What's new". Fresh apps rank better.
- **Promotional content / LiveOps** (Play Console): seasonal events such as a "New Year 30-day habit challenge", Dashain or Tihar wellness challenges, or World Water Day.
- **Custom store listing for Nepal** (Play Console → Custom store listings, country = Nepal) with Nepal-specific screenshots and wording.
- **Deep links** (`dailymantra.app/workouts/...`) so links shared on Facebook, Viber or TikTok open the app or the store.
- **Off-store traffic:** short Facebook and TikTok videos of home workouts in Nepali, linking to the store. Installs from outside the store also lift ranking.
- **iOS App Store:** name (30), subtitle (30) `Water, pill & workout reminder`, keyword field (100, comma-separated, no spaces, don't repeat words already in the name):
  `habit,tracker,routine,water,reminder,medicine,pill,workout,home,yoga,meditation,nepali,streak` (trim to 100).

---

## 9. Checklist for the next release

- [ ] Paste the English listing (section 3); add the ne-NP translation
- [ ] 8 new screenshots (EN) and 8 (NE), plus feature graphic
- [ ] app-ads.txt live on the developer website
- [ ] Privacy policy URL with contact email; Data safety updated (ads, YouTube)
- [ ] Health apps declaration and Ads declaration
- [ ] Staged rollout; watch Android vitals for 48 h
- [ ] Start one store listing experiment (first screenshot)
- [ ] Reply to all reviews weekly
