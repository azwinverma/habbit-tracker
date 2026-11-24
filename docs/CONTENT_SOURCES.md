# Content Sources & Licensing

DailyMantra has no licensed content of its own. It uses only content that is **free to reuse, including commercially** (the app shows ads): public domain, CC0, CC BY and CC BY-SA. NonCommercial (NC) and NoDerivatives (ND) licences are rejected by code (`LicensePolicy` in `lib/features/content/domain/content_item.dart`, unit-tested).

## Active providers

| Provider | Kind | What we use | Licence | Refresh | Attribution shown |
|---|---|---|---|---|---|
| **Project Gutenberg** via [Gutendex](https://gutendex.com) | Books (EPUB) | English titles with `copyright: false` and an EPUB file | Public domain **in the US** | every 6 h (pages 1–2 + one rotating page/day) | Author, "Project Gutenberg", licence |
| **[Wikimedia Commons](https://commons.wikimedia.org)** | Ambient / nature / mindfulness sounds | Audio 30 s – 3 h, MP3 transcode, 10 collections (rain, ocean, forest, water, wind, thunder, singing bowl, bells, night, fire) | PD / CC0 / CC BY / CC BY-SA only | every 24 h | Author (from file page), licence, collection |
| **[wger](https://wger.de)** | Exercise library | English exercises (name, instructions, muscles, equipment, image) | Text CC BY-SA 3/4; images per-author | every 7 days (~10 requests, full catalogue) | Text author, image author, licence |

Live check (2026-11-24, `LIVE=1 flutter test test/content/live_providers_test.dart`): Gutendex 60 books per refresh, Commons 97 sounds, wger 200 exercises from 2 pages (~1,000 total). Every item passed the licence filter.

## How "new content when the user opens the app" works
1. On app start (after the splash screen) and whenever the app returns to the foreground, `ContentSyncService.syncIfStale()` runs in the background.
2. Each provider is fetched only if its refresh interval has passed. After a failure it backs off for 15 minutes. Pull-to-refresh in Discover and "Check for new content now" under You force a refresh.
3. Items are upserted into the local SQLite cache (`content_items`). Items that weren't in the cache before are flagged **New**: they get a badge on Today's Discover icon and on the Discover tabs, and are listed first until viewed. The first-ever sync of a provider doesn't flag everything as new.
4. Offline: the cached catalogue keeps working. A failed or empty response never wipes the cache. Items a provider hasn't returned for 90 days are pruned.
5. Media files (EPUB, MP3) are fetched only when the user opens or plays an item, directly from the provider's servers. Thumbnails are cached by `cached_network_image`.

## Obligations & caveats (read before publishing)
- **Gutenberg "public domain" means US public domain.** Some works may still be under copyright in other countries (Nepal: author's life + 50 years). The You screen says so. The "Project Gutenberg" name is a trademark: we credit it as the source but do not repackage or re-host the books.
- **Gutenberg robot policy:** gutenberg.org asks automated tools not to crawl the site. The app downloads a single EPUB only when a person taps a book, and metadata comes from Gutendex, not gutenberg.org. Do not add background bulk downloading from gutenberg.org. Use a mirror if offline packs are added (Phase 6).
- **CC BY / BY-SA require attribution:** the author and licence are shown in Discover (Credits & licence), in the meditation and reading pickers, and in You → Sources & licences. Keep these visible in any redesign.
- **Wikimedia API etiquette:** requests send a generic User-Agent (`DailyMantra/2.0 …`). Wikimedia recommends adding a contact URL or email. Add one in `contentUserAgent` (`lib/features/content/data/providers/content_provider.dart`) if you want, but it will be sent from every user's device.
- **wger:** texts are CC BY-SA. If you modify a description and redistribute it, the change must be shared under the same licence.
- **Not medical content:** none of these sources are used for health advice.

## Retired source
- **PythonAnywhere API** (`aswiniverma.pythonanywhere.com/api/list/audio|ebooks`): on 2026-11-24 it returned a "Coming Soon: PythonAnywhere" placeholder page instead of JSON, so meditation and reading content was already broken in v1.0.0. The owner confirmed there is no licence for its content. It has been removed from the app.

## Candidate sources (not yet integrated)
| Source | Use | Note |
|---|---|---|
| LibriVox (via Internet Archive) | Public-domain audiobooks | PD recordings; good fit for "listen while walking" |
| Standard Ebooks | Polished PD EPUBs | CC0 for their production work |
| MedlinePlus Connect | Health education | Check API terms, needs attribution, no advice |
| Original DailyMantra content | Breathing guides, quotes, routines | Fully owned, Nepali/English |
| Internet Archive audio | More ambient tracks | Licences vary a lot: filter strictly, avoid NC |
