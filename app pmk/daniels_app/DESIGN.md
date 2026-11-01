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
- Login is an Operate surface: a centered 440px form, one PMK wordmark row,
  a compact functional heading, Google and UB grouped above a separator, and
  a labeled email field with a precise send-link action below. Provider login
  never requires completing the email form. White fields and neutral outlines
  keep indigo reserved for the email submission and visible focus. Explanations
  appear progressively for sent email, missing providers, redirect and errors.
- A single thin separator introduces the news feed. Only Web PMK appears in
  quick access. Divisions and administrative tools do not appear on Home;
  existing interview/visualisation tools remain available from Settings.
- Home, Friend, Settings remain the three bottom destinations.
- New service pages state availability honestly. Prayer, spiritual consultation,
  and academic support have no invented providers or submission endpoints.
- Energy 3: custom colorful illustration and brand color. Rhythm 2: photograph,
  open icon navigation, editorial feed, then one quiet website row. Motion 1:
  native focus/press feedback and route transitions, no decorative loops.

The operating mode is Operate on Home and utility pages; reading pages use Read.
Impeccable leads the workflow. The existing local KompasKuliah anti-slop guidance
is applied during implementation, as explicitly selected by the user in this chat.
No skill installer or persistent agent-configuration change is part of this work.
