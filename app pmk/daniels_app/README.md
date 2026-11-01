# Daniel Apps

Flutter application for PMK Daniel: devotional previews, Bible reading, equipping, community support entry points, PMK news, and member accounts. The Home, Friend, and Settings navigation follows the PMK website's visual system.

## Run locally

Use a Flutter SDK that includes Dart 3.12.2 or later and supports the SDK constraints in `pubspec.yaml`.

```sh
flutter pub get
flutter run -d chrome --web-port=8873 --dart-define=PMK_WEB_URL=https://YOUR_PMK_WEBSITE
```

`PMK_WEB_URL` is the destination for the Web PMK shortcut. An unset URL displays an availability message. The Bible and bundled fonts work without an external asset CDN.

## Accounts

Email login uses Supabase passwordless verification. Google and Universitas Brawijaya are separate visible options using the same Google OAuth provider; the campus option supplies UB account-selection hints. Google controls subsequent federation to the university identity provider.

The first screen for signed-out users is login/sign-up. Verified accounts without a name complete their profile before Home. Home greets users using their saved display name. Logout clears the protected navigation stack. This is a UI session gate; backend permissions must still be enforced through Supabase authorization/RLS.

Google OAuth is enabled on the new Supabase project for local web preview. Supply `--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co` and `--dart-define=SUPABASE_PUBLIC_KEY=YOUR_PUBLISHABLE_KEY` when running or building with accounts enabled, or use the local JSON build configuration described in `ACCOUNT-SETUP.md`. Without these values the public features remain available and the account service reports that it is unconfigured. The old backend and private interview seed are not connected by default. Review `ACCOUNT-SETUP.md` for the verified scope and remaining production/native setup. Never put OAuth client secrets or Supabase service-role keys into the Flutter application.

Private member names, interview answers, exported spreadsheets, and browser authentication screenshots are intentionally absent from this repository snapshot. The legacy interview tools remain available for privately imported records. This source snapshot starts with an empty official roster and interview seed; it does not migrate data from an existing backend.

Some devotional content is illustrative, and the equipping, Friend, prayer, consultation, and academic services are marked as upcoming where not connected. See `HOMEPAGE-UPDATE.md` and `UI-REVIEW.md` for implemented scope and validation limitations.

## Validate and build

```sh
flutter test
flutter analyze lib/features/account lib/features/home/growth_content.dart
flutter build web --no-wasm-dry-run --dart-define=PMK_WEB_URL=https://YOUR_PMK_WEBSITE
```

Optional phone/tablet render review:

```sh
flutter test --dart-define=VISUAL_REVIEW=true test/visual_review_test.dart
```

Generated renders and local build output are ignored. Plus Jakarta Sans is bundled with its OFL license in `assets/fonts/OFL.txt`.
