# Review of the six-feature homepage

## Login-first flow and photo hero — 2026-11-01

Signed-out users now land on login/sign-up, and verified accounts without a display name complete their profile before Home. The app uses the actual session name for “Hai, [name]!” and derives initials from its first two words. No student or membership status is inferred from the name or email. Changing identity or logging out resets the Navigator, including a page already open above Home.

Following the supplied reference and the user's rejection of the blue card, the hero now uses the existing PMK photograph without a scrim, colored box, corner clipping or overlay text. The devotional title and link are on white below, followed by an open greeting row and the six shortcuts. Phone and tablet review used a signed-in fake gateway only in tests; no fake production identity was introduced. The two bounded render rounds cover the new home and login surfaces.

## Icon refinement, flat-v2

The user rejected the initial 3D-like icons. Six ImageGen edits now use simplified,
front-facing blue/orange shapes. The meanings remain book/sun, Bible, book/sprout,
heart/hands, conversation, and academic study. All six full-size edits were inspected
before export. Runtime files are versioned under `assets/icons/flat-v2/`; previous
art is preserved and excluded from the runtime asset bundle. Exact prompts, source
files, and edit method are recorded in `.impeccable/assets/flat-v2-generation.json`.

Only asset references and their bundled directory changed. Feature sizes, labels,
layout, focus behavior, pages, and data flows remain as previously reviewed. The
test preloader follows the new asset paths. See `flat-v2-tests.log` in the review
directory for the executed regression and native-render run.

Scoped delivery gate:

- Purpose PASS: simpler illustrations directly address the user's visual critique and retain each feature's meaning.
- Consistency PASS: all six edits use the same prompt constraints and blue/orange palette; no unrelated new symbol system.
- Preservation PASS: existing image sources and the previous runtime set remain available; all three production consumers reference flat-v2.
- Honesty PASS: edits were made with built-in ImageGen, not represented as hand-authored SVGs; output remains transparent PNG.
- Scope PASS: no navigation or service-availability change was introduced.
- Verification PASS: nine Flutter tests, including phone/tablet renders and the six-feature click-through, passed with the flat-v2 asset bundle. The production web build passed.
- Visual PASS: all six edited sources, both device captures and the scrolled phone capture were inspected. The active browser tab was reloaded and the six icons were verified together; final browser capture: `.impeccable/review/flat-v2-browser.png`.

Scope: the revised Home, shared theme, illustrated launchers, support introduction
pages, and local browser preview. This is not a fresh audit of the legacy interview,
visualisation, or full Bible reader implementation.

## Authority and method

- User direction: remove divisions; only Web PMK in quick access; six specified
  features; illustrated icons resembling the supplied screenshot; follow PMK web.
- Impeccable workflow, plus the existing KompasKuliah anti-slop guidelines.
- Anti-slop `during` was explicitly selected in this chat, not saved globally.
- Brand decisions and their purpose are recorded in `DESIGN.md`.
- ImageGen built-in generated six separate transparent icons. Exact prompts,
  outputs and source paths: `assets/icons/generation-manifest.json`.
- Original outputs retained in `.impeccable/assets/originals/`; runtime PNGs resized
  to 256px with alpha. All six source images were visually inspected.
- Plus Jakarta Sans is bundled with its Google Fonts OFL license.

## Executed verification

- Nine Flutter tests passed, including the two opt-in native render tests.
- All six launchers were tapped in the widget workflow and reached their intended
  pages or Bible callback. Existing three-tab navigation and Settings tools passed.
- Tab/Enter activates the Renungan launcher. A visible indigo border marks focus.
- News parsing, error/retry recovery, and local journal persistence passed.
- Narrow 320px layout with 1.5x text passed without a render overflow.
- Native captures inspected at phone 390x844 and tablet 1024x1366, including the
  scrolled news state. They are Flutter renders of the actual hub, not mockups.
- Browser Home at the user's panel size and phone 390px was inspected. Prayer
  navigation was clicked and captured in `prayer-browser.png`. Web PMK opened
  `http://127.0.0.1:8874/home`; the local web server returned HTTP 200.
- Browser navigation later timed out during preview reload. Final layout confirmation
  uses the native Flutter renders and completed production build; no completed final
  browser screenshot or full portal interaction audit is claimed.
- Scoped Dart analysis passed with no issues. Production web build passed.
- No HTML/CSS detector verdict is claimed for the Flutter canvas UI.

## Delivery gate, scoped to this revision

- R-02 PASS: new UI copy has no em dashes.
- R-03 PASS: 320px/1.5x text test and 390px/1024px captures show wrapping without layout exceptions.
- R-17/R-18 PASS: no statistics, reviews, or testimonials were fabricated.
- R-23 PASS: user explicitly requested six generated illustrated icons and the navigation changes.
- R-24 PASS: three existing bottom destinations remain; six new launchers have working page/callback targets.
- R-25 PASS: computed indigo/orange CTA contrast 4.97:1; secondary text on warm surface 5.52:1; white on the worst-case hero scrim 5.01:1.
- R-26 PASS: scoped launchers, route backs, retry, reader and journal controls have tested handlers; upcoming services have no fake forms.
- R-27 PASS: news loading, empty, HTTP failure, retry, and image fallback remain present.
- R-28 PASS: no FAQ was introduced.
- R-32 PASS: keyboard activation tested; native back controls retained; focus border uses the primary brand color.
- R-33 PASS: changes were authored directly with source patches; no external string-rewrite script implemented this revision.
- R-34 PASS: only the existing light theme ships; no nonfunctional theme toggle was added.
- R-35 PASS: build, scoped tests, launcher click-through and native captures completed, with browser limitations distinguished above.
- R-36/R-38 PASS: previews and unopened support services are labeled; no invented providers or service guarantees.
- R-37 PASS: the supplied screenshot and web source define the direction; ENERGY 3, RHYTHM 2, MOTION 1.
- R-39 PASS: native Material controls, names from visible labels, 48px primary buttons, decorative image exclusion, HTML lang=id, no decorative animation loops.
- R-40 PASS: icon/photo layout dimensions are stable; news loading/result states reserve the same feed extent; no unmeasured performance claims.
- Purpose gate PASS: indigo scrim provides contrast, orange identifies the reading action, subject-specific illustration identifies each feature; no decorative grids, glass or glow were added.
- Liveliness PASS: actual PMK photography, the website's font/palette and custom illustrations carry identity without fabricated content.
- Craftsmanship PASS: consistent 10-16px corners and shared theme; content-first order; clear availability and local-link configuration.

## Preview and remaining content work

The app is served at `http://localhost:8873/`. Preview Web PMK points to the
local Next.js site on port 8874 because neither public domain found in the source
resolved during this session. Set `PMK_WEB_URL` to the real published URL for a
deployment; an unset/invalid URL produces a visible notice, not a broken link.

Preview build:

```powershell
flutter build web --no-pub --no-wasm-dry-run --pwa-strategy=none --dart-define=PMK_WEB_URL=http://127.0.0.1:8874
```

The PWA strategy flag is a deprecated, still-supported local-preview option used
to avoid stale application caches. It is not a new production caching design.
Published devotional dates, Kambium content and real prayer/consultation/academic
service providers remain unconnected. APKs and production deployment were not changed.

## Account flow — 2026-11-01

Added email-first login, a real Supabase session boundary, profile name editing and local logout. Entry points are the Home account icon, Friend and Settings. Exact UB domains select registered campus SSO or Google; unavailable providers show their actual status and an explicit email fallback. No campus password form or fabricated signed-in state was added.

Impeccable and anti-slop DURING guidance continue to apply: PMK typography and colors, one primary action per state, a restrained 540px form width, inline email validation, clear provider availability, 48px primary controls and native navigation. Two bounded native render rounds checked 390×844 and 1024×1366. The second round confirmed the shared corner treatment, real back navigation and no debug banner. Captures: `account-phone.png`, `account-tablet.png`, `account-ub-phone.png`, `account-ub-tablet.png` under `.impeccable/review/`.

The full standard suite passed 15 tests (two visual tests skipped by default). The focused account/journal suite plus enabled visual captures passed 10 tests after final UI refinements. New account and journal source analysis is clean; the larger main file retains four pre-existing informational brace lint notices. Android and iOS callback configuration parses as XML; external OAuth, SMTP delivery and native device callbacks have not been exercised. Setup details and deployment limitations are in `ACCOUNT-SETUP.md`.

The final web build succeeded and the running localhost preview was refreshed. Browser click-through confirmed Home → account, exact UB email recognition and the unavailable-provider fallback without sending an email. Captures `account-browser.png` and `account-ub-browser.png` show the actual running build.

### Three explicit login choices

The subsequent revision separates Email, Google and Universitas Brawijaya. Email remains passwordless for every address, including UB. The campus button uses Google OAuth with a UB domain hint; entering the campus email first is optional and supplies a login hint. It does not use the optional direct-SAML gateway. Session reuse or university federation can skip or change the provider screens, so no forced UB password prompt is promised. Google remains disabled until provider activation; the campus button explains the same configuration limitation and provides recovery. Phone and tablet captures confirm all three choices, shared control treatment and readable availability copy. Coverage includes independent email/campus routing and exact Google request parameters. The web build and scoped analysis succeeded. Native Flutter renders verified the revision; refreshing the in-app browser was blocked by unavailable browser control in this turn.

Final account and journal tests passed 10/10. The two native phone/tablet visual tests also passed separately; the widget journey test was repaired to scroll the parent list before selecting a lazily built control in its 800×600 test viewport.
