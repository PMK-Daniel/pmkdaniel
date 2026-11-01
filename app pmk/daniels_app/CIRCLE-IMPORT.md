# Daniel Circle in Pembekalan

Source supplied by the user:
[Panduan Circle PMK Daniel FILKOM UB](https://daniel-circle.notion.site/23e37fc5cfa88080bfc0e0999c4a7b73?v=23e37fc5cfa881c99721000c96888c93).
Imported 1 November 2026. This is a bundled snapshot, not live Notion synchronization.

## Coverage

- 58 consecutive meetings, numbered 1–58, plus the implementation guide.
- 175 original PDFs: 58 meeting modules, 58 discussion documents, 58 facilitator
  guides, and one implementation guide. Total: 613 original PDF pages.
- Every meeting retains the observed title, phase, curriculum, semester tags,
  introduction and source page. `assets/circle/catalog.json` includes document
  SHA-256 hashes and full extracted text, organized by original PDF page.
- All original PDFs are bundled under `assets/circle/files/`. The 20-page main
  guide is image-only; its original pages are rendered locally under
  `assets/circle/pages/`. No OCR text is invented.

| Original Circle phase | Meetings |
| --- | --- |
| Newcomer (Pioneer) | 1–10 |
| Trainee (Growing Leader) | 11–24 |
| Builder (Emerging Professional) | 25–34 |
| Expert (Profesional Leader) | 35–39 |
| Ambassador (Global Influencer) | 40–58 |

Spelling and grouping follow Notion. The 58-item count was verified after
scrolling beyond Notion's initial 50-row page (the guide plus meetings 1–49).
Each meeting's three document roles were checked; five initially missed links
were revisited before the final import.

## Adaptation of the recovered KambiumGo learning system

The app follows phase → curriculum → ordered meeting → reading/discussion →
personal reflection → completion → next meeting. It offers phase filtering,
search, a resume action, separate document selectors, page navigation and the
original PDF/source link. Curriculum and phase labels come from Daniel Circle;
they are not relabeled Berakar/Bertumbuh/Berbuah.

The recovered KambiumGo models/services informed the hierarchy and the
reflection/completion pattern. Its decompiled C# is not included in this app.
No KambiumGo account, API token or protected server material was imported.
KambiumGo group chat, schedules, permissions, reminders and sync queue have
not been reproduced or implied by this change.

## Reading and progress

The readable edition preserves words and page order while joining PDF hard
wraps using line geometry. Decorative Emoji-font glyphs with broken character
mapping are omitted from extracted text; original PDFs retain their appearance.
The readable edition does not claim to reproduce original font emphasis or layout.

PDFs are local static assets and open in the browser's PDF viewer on web. On
other platforms, the in-app text/image reader and original Notion source remain
available. The document currently selected is not persisted across app restarts.

Reflections, completion and the last opened meeting are saved in device-local
SharedPreferences, partitioned by Daniel account ID. They are not cloud synced,
shared with facilitators or written back to KambiumGo/Notion. Guests can read in
isolated widget tests but cannot save; production retains the existing login gate.
Opening a meeting does not mark it completed. Completion is an explicit,
reversible learner action; saving feedback reflects actual storage success.

## Provenance and checks

The source was read through its public browser UI. PDF URLs came from the file
tabs opened by those visible attachment controls. Downloads used those exact
URLs, with no inferred endpoints, hidden page state or authentication bypass.
Short-lived signed file URLs remain in the local import audit and are excluded
from the app and Git. The app uses stable Notion page links plus bundled files.

Behavioral coverage checks all 58 IDs, all 175 document roles and readable
pages, PDF headers, guide-image existence, per-account persistence and resume,
the real reader/discussion/pagination/save journey, search and load retry.
Phone/tablet native render evidence is under `.impeccable/review/circle-*.png`.
These captures use test accounts only, not a fabricated production login.
