# Content Sources & Licensing

DailyMantra has no licensed content of its own. It uses only content that is **free to reuse, including commercially** (the app shows ads): public domain, CC0, CC BY and CC BY-SA. NonCommercial (NC) and NoDerivatives (ND) licences are rejected by code (`LicensePolicy` in `lib/features/content/domain/content_item.dart`, unit-tested).

## Active providers

| Provider | Kind | What we use | Licence | Re-download when older than | Attribution shown |
|---|---|---|---|---|---|
| **Project Gutenberg** via [Gutendex](https://gutendex.com) | Books (EPUB) | English titles with `copyright: false` and an EPUB | Public domain **in the US** | 1 h (pages 1–2 + one rotating page/day) | Author, "Project Gutenberg", licence |
| **LibriVox** via [Internet Archive](https://archive.org/details/librivoxaudio) | Audiobooks (MP3 chapters) | Most-downloaded English titles (2 pages + 1 rotating page/day, ~300); chapters fetched when a book is opened | Public domain | 6 h | "Read by LibriVox volunteers", licence |
| **[Wikimedia Commons](https://commons.wikimedia.org)** | Nature / mindfulness sounds | Audio 30 s – 3 h, MP3 transcode, 10 collections | PD / CC0 / CC BY / CC BY-SA | 6 h | Author, licence, collection |
| **Wikimedia Commons (video)** | Exercise, yoga, meditation videos | Categories *Videos of physical exercises*, *Videos of yoga*, *Videos of meditation*; 5 s – 45 min; VP9 WebM (Android) + MPEG-4 (iOS) transcodes; files with personality/trademark restrictions skipped | PD / CC0 / CC BY / CC BY-SA | 12 h | Author, licence |
| **[wger](https://wger.de)** | Exercise library + demo videos | ~980 English exercises (instructions, muscles, equipment, image) and ~45 demo videos (HEVC MOV, 30–60 MB each, streamed on tap) | Texts CC BY-SA 3/4; videos/images per author (NC rejected) | 24 h (~12 requests; API has no "changed since" filter) | Text, image and video authors, licence |
| **YouTube** (curated, not synced) | Follow-along workout videos | 32 hand-picked videos from well-known trainers (FitnessBlender, Yoga With Adriene, Pamela Reif, The Body Coach TV, Calisthenicmovement, …) in 11 groups that match the weekly-plan body parts. List: `lib/features/content/data/youtube_workouts.dart` | YouTube Terms: played only through YouTube's official embedded player (no download/offline, no ad blocking); views and ads stay with the creator | Static list, checked with `LIVE=1` test (oEmbed 200 = exists and embeddable) | Channel name, "Open in YouTube" |

Live check (2026-11-25, `LIVE=1 flutter test test/content/live_providers_test.dart`, and on a Pixel 9 Pro emulator with the release build): Gutendex 60–86 books, LibriVox 287 audiobooks (chapters stream), Commons 97 sounds, Commons 39–65 videos (36/39 with an iOS rendition), wger 979 exercises + 46 videos. About 1,500 items on first open. Every item passed the licence filter.

**What this is not:** there is no free, openly licensed equivalent of a curated, professionally filmed workout programme. The free video library is real but small (~110 videos) and uneven in quality. Commissioned or owned videos (DailyMantra originals) would be the way to grow it.

## How content stays fresh
1. **Every app open and every return to the foreground** runs `ContentSyncService.syncIfStale()` in the background. All providers are checked **in parallel**, and each re-downloads when its last refresh is older than the interval above. A failure backs off for 15 min. HTTP 429/5xx and timeouts are retried with exponential back-off (Retry-After honoured).
2. **Android background job** (WorkManager, `lib/features/content/data/background_sync.dart`): roughly every 12 h, only with a network connection and when the battery isn't low, the same sync runs while the app is closed. The OS may defer it (Doze, battery saver). iOS refreshes on open only.
3. **"Check now"**: pull-to-refresh in Discover, or You → Check for new content now.
4. New items are flagged **New** (badges on Today's Discover icon and Discover tabs, listed first until viewed). A provider's first-ever sync doesn't flag everything.
5. **Offline:** the catalogue is in SQLite (`content_items`). Failed or empty responses never wipe it. Items not returned for 90 days are pruned, **except anything downloaded**.

## Offline media ("saved in the app")
- **Books** are saved automatically the first time they're opened, so they open offline afterwards.
- **Audiobooks** (per chapter or "Download all chapters"), **sounds** and **videos** have *Download for offline*. Downloads stream to a temp file and rename on success (no half files), are recorded in `content_downloads`, play from disk, and are listed under You → Saved for offline (size, remove all).
- Audiobook chapter lists and listening positions are stored locally, so a downloaded book also plays in flight mode.
- Video streaming falls back to the other rendition if the first fails. Verified on the emulator: Wikimedia returned HTTP 429 for the WebM and the MPEG-4 copy played.

## Obligations & caveats (read before publishing)
- **Gutenberg "public domain" means US public domain.** Some works may still be under copyright in other countries (Nepal: author's life + 50 years). The You screen says so. The "Project Gutenberg" name is a trademark: we credit it as the source but do not repackage or re-host the books.
- **Gutenberg robot policy:** gutenberg.org asks automated tools not to crawl the site. The app downloads a single EPUB only when a person taps a book, and metadata comes from Gutendex, not gutenberg.org. Do not add background bulk downloading from gutenberg.org. Use a mirror if offline packs are added (Phase 6).
- **CC BY / BY-SA require attribution:** the author and licence are shown in Discover (Credits & licence), in the meditation and reading pickers, and in You → Sources & licences. Keep these visible in any redesign.
- **Wikimedia API etiquette:** requests send a generic User-Agent (`DailyMantra/2.0 …`). Wikimedia recommends adding a contact URL or email. Add one in `contentUserAgent` (`lib/features/content/data/providers/content_provider.dart`) if you want, but it will be sent from every user's device.
- **wger:** texts are CC BY-SA. If you modify a description and redistribute it, the change must be shared under the same licence.
- **Internet Archive / LibriVox:** recordings are public domain. LibriVox asks that its name isn't used to imply endorsement; we credit "Read by LibriVox volunteers" only.
- **Wikimedia videos** may show identifiable people. Files tagged with personality-rights or trademark restrictions are skipped. Others are used as Commons provides them, with attribution.
- **YouTube videos are not ours and not openly licensed.** They are only embedded with YouTube's official player (allowed by YouTube's Terms of Service), never downloaded, cached or shown without YouTube's controls/branding. They can't be saved for offline. A creator can delete a video or turn off embedding at any time: run the `LIVE=1` test before each release and replace failures. If a video refuses to play, the app offers "Open in YouTube".
- **Not medical content:** none of these sources are used for health advice.

## Retired source
- **PythonAnywhere API** (`aswiniverma.pythonanywhere.com/api/list/audio|ebooks`): on 2026-11-24 it returned a "Coming Soon: PythonAnywhere" placeholder page instead of JSON, so meditation and reading content was already broken in v1.0.0. The owner confirmed there is no licence for its content. It has been removed from the app.

## Candidate sources (not yet integrated)
| Source | Use | Note |
|---|---|---|
| Standard Ebooks | Polished PD EPUBs | CC0 for their production work |
| MedlinePlus Connect | Health education | Check API terms, needs attribution, no advice |
| Original DailyMantra content | Breathing guides, quotes, routines | Fully owned, Nepali/English |
| Internet Archive audio | More ambient tracks | Licences vary a lot: filter strictly, avoid NC |
