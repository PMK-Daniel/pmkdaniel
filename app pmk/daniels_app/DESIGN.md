# Daniel Apps visual system

The user supplied the PMK website as the visual authority and a youth church app
screenshot as the icon-style reference. This is a refinement of the existing
Flutter app, not a new brand.

- Primary: `#3E4095`, secondary: `#F58732`, matching `pmkdaniel/src/app/globals.css`.
- Typeface: Plus Jakarta Sans, matching the website's `src/app/layout.tsx`.
  Bundled locally under its OFL license so the app does not depend on a font CDN.
- White canvas `#FDFDFD`; periwinkle supports reading and navigation; warm cream
  identifies support/availability messages. Dark indigo is used for legible text.
- Six illustrated shortcuts have transparent backgrounds and use a consistent
  blue/orange palette with simple front-facing shapes and minimal details.
  The user rejected the initial dimensional rendering. The current flat-v2 set
  removes extrusion, glossy highlights, dramatic shadows and realistic hand detail.
  The images are generated because the user explicitly requested illustrated icons.
  Runtime assets: `assets/icons/flat-v2/`. Edit prompts and provenance:
  `.impeccable/assets/flat-v2-generation.json`. Previous versions remain preserved.
- Three columns on phones and medium widths, six on wide canvases, two on narrow
  screens with enlarged text. Labels can wrap; no fixed-height text areas.
- The hero shows the real PMK community photograph without tint, overlay text,
  rounded card framing or shadow. It reaches the phone's edges and is centered
  within an 880px reading width on larger screens. The devotional title and
  reading link sit on the white page below. An orange initials avatar and
  “Hai, [profile name]!” greeting precede the feature shortcuts, following the
  supplied reference's order without inventing membership status.
- Signed-out visitors first see login/sign-up. A verified session opens Home;
  accounts without a display name first choose how they want to be addressed.
  Logout and identity changes reset navigation so protected pages do not remain
  visible behind an old route. Existing sessions can return directly to Home.
- Login is an Operate surface with a bounded form on solid indigo. The centered
  app name sits above a 108px PMK logo. Email and its precise send-link action
  appear first, followed by Google/student and the separate registration link.
  Provider login never requires completing the email form. White fields and
  neutral outlines sit on a solid warm panel. The orange student-login control
  echoes the PMK website; Google retains its official multicolor mark.
  Explanations appear progressively for sent email, unavailable providers,
  redirect and errors. The form scrolls when the keyboard reduces available space.
- A single thin separator introduces the news feed. Only Web PMK appears in
  quick access. Divisions and administrative tools do not appear on Home;
  interview/visualisation and cloud configuration are not mounted or routed from
  the member app shell. This is not a claim of server-side admin authorization.
- Home, Friend, Settings remain the three bottom destinations.
- Circle uses the real Daniel Circle sequence from Notion: phase,
  curriculum, numbered meeting, then material/discussion/facilitator documents.
  It is an Operate catalog and a Read detail surface. A compact phase selector
  and search lead to open numbered rows; no repeated promotional cards.
  Readable text uses a bounded width and 17px type with original PDFs available.
  Reflections and completion are explicit local actions with per-account storage.
- New service pages state availability honestly. Prayer, spiritual consultation,
  and academic support have no invented providers or submission endpoints.
- Energy 3: custom colorful illustration and brand color. Rhythm 2: photograph,
  open icon navigation, editorial feed, then one quiet website row. Motion 1:
  native focus/press feedback and route transitions, no decorative loops.

## Member experience revision, 1 November 2026

- Settings uses familiar grouped rows: preferences; account and privacy; help
  and information. Profile identity is the only prominent panel, because it
  establishes which account is being configured. Rows have dividers, not shadows.
- The warm white canvas supports long reading and the PMK orange accents; a
  full indigo surface identifies entry to the account. This release has a fixed
  light reading theme, not an unfinished or simulated dark-mode toggle.
- Sign-in and account creation are distinct intents. Email continues to use the
  deployed passwordless flow; only registration may create a new email account.
  Google/student OAuth still uses its provider's own authentication. The earlier
  password-based mockup is not presented as implemented.
- The account entry now uses a personal initial and a clear edit affordance.
  Profile changes have discard protection and saving feedback. Logout requires
  confirmation and resets the protected app navigation.
- Device-wide text sizes and reduced route motion are persistent, real controls.
  Text scaling adds to system text size rather than overriding it. There are no
  fake notification or privacy switches. Unavailable notification delivery is
  explicitly disclosed before entering the row.
- Home includes a resumable Circle row that reads the current account's local
  position. Circle protects unsaved reflections and persists the next lesson
  position before leaving. Failed storage keeps the current work visible.
- Alkitab uses the shared size control, bounded reading width, selectable verses,
  wrapping chapter buttons, a responsive chapter picker, and stale-load protection.
  News errors and empty states use their natural height rather than reserving a
  large blank carousel. Renungan archives use a bounded reading width.
- Friend and support remain explicit availability states with a real Web PMK
  destination. They do not collect requests without a recipient/backend.
- Energy 2 / Rhythm 2 / Motion 1 for member utility screens. Home and account
  retain the requested stronger identity; typography, control shapes, spacing,
  and indigo/orange tokens remain shared. Icons describe actions or content;
  they are not repeated decoration around every paragraph.

The operating mode is Operate on Home and utility pages; reading pages use Read.
Impeccable leads the workflow. The existing local KompasKuliah anti-slop guidance
is applied during implementation, as explicitly selected by the user in this chat.
No skill installer or persistent agent-configuration change is part of this work.
