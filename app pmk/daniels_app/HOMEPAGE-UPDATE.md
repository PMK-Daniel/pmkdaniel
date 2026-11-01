# Homepage Daniel Apps

Current revision: see `DESIGN.md` and `UI-REVIEW.md`. Home now has six illustrated
features: Renungan, Alkitab, Pembekalan, Dukungan doa, Konsultasi Rohani and
Dukungan akademik. Divisions and administrative shortcuts have been removed from
Home; Web PMK is the only quick-access entry. The history below describes the
initial implementation and is superseded where it differs.

Implemented on 1 November 2026 in this Flutter source tree.

## Layout

1. Daniel header and devotional hero using the existing PMK community photograph.
2. Greeting and shortcuts: Renungan, Alkitab, Pembekalan, Jurnal.
3. Horizontal Berita & kabar PMK section with a separate article list and reader.
4. Pembekalan entry, followed by existing interview, visualisation, division and portal tools.
5. Bottom navigation: Home, Friend, Settings. Android back returns internal hub pages to Home.

## Content and availability

- News reads the existing public PMK `/api/pengumuman?limit=50` feed. It does not write to the backend. Loading, empty, retry, and image-failure states are implemented. The list displays up to the latest 50 items.
- The three devotional readings are explicitly marked editorial previews, not published PMK devotionals. No dated daily publishing service or date archive backend is connected yet.
- Alkitab uses the existing offline Bible feature.
- Pembekalan has an honest empty state and a sample reflection; KambiumGo content/services have not been connected or copied.
- Journal notes persist per reading in local SharedPreferences. They are device-local, are not encrypted, and are not synced to an account. The UI explains local storage and asks before discarding unsaved changes.
- Friend is an initial empty state with a link to the PMK portal. Social accounts, friend requests and messaging are not implemented.
- Settings exposes the existing cloud/interview configuration and tools. Interview initialisation is deferred until an interview or visualisation tool is opened; state is retained afterward.

## Files

- `lib/features/home/growth_home.dart`: new home sections.
- `lib/features/home/growth_content.dart`: preview readings, journal, news client and readers.
- `lib/features/home/hub_pages.dart`: Friend and Settings surfaces.
- `lib/features/home/home_screen.dart`: integration with the existing home.
- `lib/main.dart`: three destinations and retained legacy tool screens.
- `lib/features/bible/bible_screen.dart`: Material ancestor for existing tappable book rows, required by the installed Flutter version.

## Verification

```powershell
flutter test --no-pub test/growth_content_test.dart test/widget_test.dart
dart analyze lib/features/home test/growth_content_test.dart test/visual_review_test.dart test/widget_test.dart
flutter build web --no-pub --no-wasm-dry-run
```

Optional native Flutter render captures (phone and tablet):

```powershell
flutter test --no-pub --dart-define=VISUAL_REVIEW=true test/visual_review_test.dart
```

Captures are written to `.impeccable/review/`. Widget tests block network requests, so the render captures exercise the news error/retry state. Functional news parsing is tested with a deterministic HTTP response. The public news endpoint was separately checked read-only and returned published PMK articles. No deployment or APK replacement was performed.
