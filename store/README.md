# Play Store assets: DailyMantra 2.0.0

Upload in **Play Console → Grow → Store presence → Main store listing** (English) and add a **Nepali (ne-NP)** translation for the second set.

| Play Console field | File | Spec |
|---|---|---|
| App icon | `icon/app_icon_512.png` | 512×512 PNG ✔ |
| Feature graphic | `feature_graphic_1024x500.png` | 1024×500 PNG ✔ |
| Phone screenshots (English) | `screenshots/en-US/01…08.png` | 8 × 1080×1920 (9:16) ✔ |
| Phone screenshots (Nepali) | `screenshots/ne-NP/01…08.png` | 8 × 1080×1920 ✔ |
| App name, short and full description | `listing/en-US.md`, `listing/ne-NP.md` | 30 / 80 / 4000 chars ✔ |
| Release notes ("What's new") | `release_notes.txt` | paste as-is: Play reads the language tags ✔ |

Screenshot order (the first 3 matter most): Today → Medicine reminders → Home workouts → Workout → Books & audiobooks → Progress → Nepali/English → Dark mode.

## Regenerating
- **Screenshots** are rendered from the real app with demo data:
  `SHOTS=1 flutter test --update-goldens test/design/screenshots_test.dart --plain-name store`,
  then copy `test/design/screenshots/store/{en,ne}` here. Change captions in `test/design/screenshots_test.dart`.
- **Icon:** `icon/mark_white_2048.png` is the white lotus mark at high resolution. The same icon is used for the Android launcher (including the adaptive and themed icon) and iOS.

## Notes
- Video cards show brand placeholders instead of YouTube thumbnails: other creators' thumbnails and faces shouldn't appear in our store graphics.
- The listing doesn't name third-party brands (YouTube channels) to stay within Play's metadata policy. The app credits them in the UI.
- Have a native speaker review `listing/ne-NP.md` before publishing.
