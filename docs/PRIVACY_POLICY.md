# DailyMantra — Privacy Policy (draft for the owner to review and publish)

_Last updated: 25 November 2026 · Applies to DailyMantra 2.0 for Android and iOS._

> **Owner:** fill in the contact line, review with your own legal adviser, and host this at a public URL (required by Google Play and the App Store for apps that show ads). This draft describes what the code in this repository actually does.

## Summary
- No account is needed. Your habits, medicine schedules, dose log, water/exercise history and settings are stored **only on your phone**.
- We (the developer) do not receive or store your personal data. There is no DailyMantra server.
- The app downloads free books, audiobooks, sounds and videos from public libraries. Those services see your IP address, as any website does.
- The app shows ads from Google AdMob, which processes device data as described below.

## Data stored on your device
| Data | Purpose | Where |
|---|---|---|
| Habits, reminder times, medicine names/doses/notes, taken/skipped log, water/exercise/meditation counts | The app's features | Local SQLite database inside the app |
| Downloaded books, audio and video | Offline use | App-private storage, removable under You → Saved for offline |
| Language, theme, onboarding state | Preferences | Local app settings |

Uninstalling the app deletes all of it. Clearing the app's storage does too.

## Network requests the app makes
| Service | Why | What they receive |
|---|---|---|
| gutendex.com, gutenberg.org | Book catalogue and EPUB downloads | IP address, generic app User-Agent, the book requested |
| archive.org (LibriVox) | Audiobook catalogue and audio | Same |
| commons.wikimedia.org, upload.wikimedia.org | Sounds and videos | Same |
| wger.de | Exercise library and demo videos | Same |
| YouTube (Google), youtube-nocookie.com | Free workout videos, only when you open one (official embedded player) | IP address, device/browser data and viewing activity for that video, per [Google's Privacy Policy](https://policies.google.com/privacy). The privacy-enhanced (no-cookie) player is used; YouTube may show ads |
| Google AdMob (+ Google consent form in the EEA/UK/Switzerland) | Ads (requested as **non-personalised**; where required, Google's consent form is shown first and choices can be changed in You → Ad privacy choices) | Device and advertising identifiers, IP address, app interaction data, per [Google's policy](https://policies.google.com/technologies/partner-sites) |

The app never sends your habits, medicine information or history to any of these services.

## Notifications and permissions
- **Notifications:** to show the reminders you set (asked only after you create your first reminder).
- **Alarms & reminders (Android):** to deliver reminders at the exact minute.
- **Motion / activity (optional):** for step counting.
- **Internet:** to download free content and ads.

## Children
DailyMantra is a general-audience wellness app and is not directed at children under 13.

## Medical disclaimer
DailyMantra is a reminder aid. It does not give medical advice and is not a medical device.

## Changes and contact
We will update this page when the app's data practices change.
Contact: **[owner: add an email address]**
