# Daniel Apps accounts

Repository snapshot: configure the new project with build defines `SUPABASE_URL` and `SUPABASE_PUBLIC_KEY`. No default backend credentials are bundled in this snapshot. The legacy settings recorded below describe the locally inspected earlier project, not an already configured new project. Private member/interview seed data is excluded.

The new project is `wprgdiimcovlehocbdlc`, at `https://wprgdiimcovlehocbdlc.supabase.co`. Its supplied publishable key was accepted by the public Auth settings endpoint on 2026-11-01: email enabled, Google disabled, signups enabled, email confirmation required. No signup emails were sent for this check. Local build configuration lives in ignored `.local/supabase.json`; `config/supabase.example.json` is the template without a key.

```sh
flutter build web --no-wasm-dry-run --dart-define-from-file=.local/supabase.json
```

The Google OAuth client's authorized redirect must now be `https://wprgdiimcovlehocbdlc.supabase.co/auth/v1/callback`; the earlier `xnbia...` callback is for a different project and must not be used for this setup. Dashboard access is still needed to configure Google and allowed app redirects. Existing users and interview records from the earlier project have not been migrated.

## Activated Google provider — 2026-11-01

Google Cloud project `daniel-apps-513409` now has the `Daniel Apps Web` OAuth web client. Its authorized origins are `http://localhost:8873` and `http://127.0.0.1:8873`; the authorized redirect is the new project's Supabase callback above. The client secret was transferred directly into Supabase Google provider settings and is not stored in source or local build configuration. Nonce checks remain enabled, and users without an email are not accepted.

Supabase Site URL is `http://localhost:8873/`; allowed redirects are exactly `http://localhost:8873/` and `http://127.0.0.1:8873/`. Public Auth settings confirm email and Google enabled. Browser testing reached Google's account chooser with the correct client ID and callback. The Universitas Brawijaya shortcut, with no email entered, then reached `https://iam.ub.ac.id/auth/realms/ub/protocol/saml` and displayed the university's username/password form. The user's completed campus/member sign-in and return session have not been verified; the browser was left at the campus form for the user. SMTP delivery and native callbacks remain untested; add the native callback and real production URLs before deploying those targets.

The Google app remains in Testing status. Requests use only the basic identity scopes `openid email profile`; Google's documented exception permits these without the ordinary test-user allowlist restriction. Campus Workspace policy may still restrict third-party apps. See [Google app state documentation](https://developers.google.com/identity/protocols/oauth2/production-readiness/overview).

Email-first authentication uses the existing Supabase project, separate from the PMK admin login. Ordinary email addresses receive a passwordless login link. The same flow creates a new account or signs into an existing one. A session is shown only after verification succeeds. Names are display metadata and grant no permissions.

The login screen offers three explicit options: email, Google, and Universitas Brawijaya. Email always requests a passwordless link, including for UB mailboxes. Google opens normal account selection. Universitas Brawijaya uses the same Google OAuth provider with `hd=student.ub.ac.id` when the field is blank. Optionally entering an exact `student.ub.ac.id` or `ub.ac.id` address adds `login_hint` and uses the corresponding `hd` domain. Other suffixes in the field are rejected for this shortcut. When Google is not configured, the campus screen explains the limitation and offers an email link if a valid email was entered, or a return to email entry otherwise. A verified UB mailbox is not proof of current student status. The campus shortcut is not a separate official UB SSO integration.

## Current configuration and remaining setup

Public Auth settings checked on 2026-11-01 reported email enabled, Google disabled, signups enabled, and email confirmation required. This does not prove that email delivery or callback allowlists are ready. No real registration emails or external login attempts were sent during automated verification.

1. In Supabase Auth URL Configuration, allow the exact deployment origins and callbacks. Local preview uses `http://localhost:8873/` or `http://127.0.0.1:8873/`; native callback is `danielsapp://auth-callback`. Set the production Site URL. Optional build define `ACCOUNT_REDIRECT_URL` overrides the callback.
2. Configure a production SMTP sender and verify delivery with a controlled test mailbox. The default email template can use the magic link. To support entering the numeric code shown in the app, include `{{ .Token }}` in the template. PKCE email links should open in the browser/device that requested them; numeric codes provide a same-device alternative.
3. For Google login, register a Google Cloud OAuth web client, configure the Supabase callback shown in its dashboard (`https://<project>/auth/v1/callback`), and enable the Google provider in Supabase. Keep the client secret in the provider configuration, never in Flutter or a public repository. The app reads provider availability at runtime.
4. Google `login_hint` and `hd` only guide account selection; Google/UB federation and existing sessions decide whether a UB login page appears. A fresh university password prompt cannot be guaranteed. Both visible Google and UB options use Google OAuth, so this flow does not require registering Daniel Apps directly with UB's SAML provider. The app never asks for BAIS passwords. The older optional direct-SAML gateway remains unused by the visible login options; `UB_SSO_ENABLED` is not needed for these options.

Android and iOS callback declarations are included. Their end-to-end OAuth behavior still needs a device test after provider configuration. Windows protocol registration is not implemented. Web callback parsing and persisted session refresh use the Supabase Flutter SDK with PKCE. Logout ends the local session. Private reflection notes remain local and are separated by authenticated user ID; existing guest notes stay with the guest and are not assigned to the first signed-in account. This separation is not encryption or cloud backup.

## Verification

Fake-gateway tests cover domain routing, unavailable providers, verification, resend cooldown, duplicate requests, errors, profile changes, session events, logout, and local journal isolation. They do not prove SMTP delivery, external OAuth configuration, campus federation, or production redirect settings.

References: [Supabase Google setup](https://supabase.com/docs/guides/auth/social-sign-in/auth-google), [domain SSO](https://supabase.com/docs/reference/dart/auth-signinwithsso), [Google OIDC hints](https://developers.google.com/identity/openid-connect/openid-connect), [native callbacks](https://supabase.com/docs/guides/auth/native-mobile-deep-linking).
